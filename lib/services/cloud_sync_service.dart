import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'account_service.dart';
import 'firebase_bootstrap.dart';
import 'profile_service.dart';

class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  static const Duration _networkTimeout = Duration(seconds: 15);

  bool get isAvailable =>
      FirebaseBootstrap.isConfigured && FirebaseBootstrap.isInitialized;

  Future<void> uploadAllProfiles() async {
    final user = AccountService.instance.currentUser;
    if (!isAvailable || user == null) {
      throw StateError('Sign in before syncing profiles.');
    }

    final bundle = await ProfileService.instance.exportCloudBundle();
    final profiles = List<dynamic>.from(bundle['profiles'] as List<dynamic>);
    final snapshots = Map<String, dynamic>.from(
      bundle['snapshots'] as Map<String, dynamic>,
    );

    if (profiles.isEmpty) {
      throw StateError('There are no local profiles to back up.');
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final profilesRef = userRef.collection('profiles');
    final localIds = profiles
        .map((item) => Map<String, dynamic>.from(item as Map)['id'].toString())
        .toList(growable: false);

    // Do not read the collection before backing up. On web, a blocked Firestore
    // read can leave the UI waiting even though Firebase Authentication works.
    // The user document stores the exact profile IDs for the latest backup, so
    // stale profile documents can safely be ignored during restore.
    final batch = firestore.batch();

    batch.set(
      userRef,
      {
        'email': user.email,
        'displayName': user.displayName,
        'activeProfileId': bundle['activeProfileId'],
        'profileIds': localIds,
        'profileCount': localIds.length,
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 2,
      },
      SetOptions(merge: true),
    );

    for (final rawProfile in profiles) {
      final profile = Map<String, dynamic>.from(rawProfile as Map);
      final id = profile['id'].toString();
      final rawData = snapshots[id];
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      batch.set(
        profilesRef.doc(id),
        {
          ...profile,
          'trackingData': data,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await _withTimeout(batch.commit(), 'Cloud backup');
  }

  Future<bool> downloadCloudProfiles() async {
    final user = AccountService.instance.currentUser;
    if (!isAvailable || user == null) {
      throw StateError('Sign in before restoring profiles.');
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);

    final userSnapshot = await _withTimeout(
      userRef.get(const GetOptions(source: Source.server)),
      'Cloud restore',
    );

    if (!userSnapshot.exists) return false;

    final userData = userSnapshot.data();
    final rawProfileIds = userData?['profileIds'];
    final profileIds = rawProfileIds is List
        ? rawProfileIds.map((item) => item.toString()).toSet()
        : <String>{};

    final profilesSnapshot = await _withTimeout(
      userRef.collection('profiles').get(const GetOptions(source: Source.server)),
      'Cloud restore',
    );

    final documents = profileIds.isEmpty
        ? profilesSnapshot.docs
        : profilesSnapshot.docs
            .where((doc) => profileIds.contains(doc.id))
            .toList(growable: false);

    if (documents.isEmpty) return false;

    final profiles = <Map<String, dynamic>>[];
    final snapshots = <String, Map<String, dynamic>>{};

    for (final doc in documents) {
      final data = doc.data();
      final trackingData = data['trackingData'];

      profiles.add({
        'id': data['id'] ?? doc.id,
        'name': data['name'] ?? 'Profile',
        // UserProfile uses snake_case JSON keys.
        'avatar_index': data['avatar_index'] ?? data['avatarIndex'] ?? 0,
        'created_at': data['created_at'] ??
            data['createdAt'] ??
            DateTime.now().toIso8601String(),
      });

      snapshots[doc.id] = trackingData is Map
          ? Map<String, dynamic>.from(trackingData)
          : <String, dynamic>{};
    }

    final activeProfileId = userData?['activeProfileId']?.toString();

    await ProfileService.instance.importCloudBundle({
      'version': 2,
      'activeProfileId': activeProfileId,
      'profiles': profiles,
      'snapshots': snapshots,
    });

    return true;
  }

  Future<DateTime?> lastCloudUpdate() async {
    final user = AccountService.instance.currentUser;
    if (!isAvailable || user == null) return null;

    final snapshot = await _withTimeout(
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server)),
      'Cloud status check',
    );

    final value = snapshot.data()?['updatedAt'];
    if (value is Timestamp) return value.toDate();
    return null;
  }

  String friendlyError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Cloud access was denied. Make sure the Firestore rules are published for /users/{uid} and /users/{uid}/profiles.';
        case 'failed-precondition':
          return 'Cloud Firestore is not ready yet. Confirm the Firestore database was created in this Firebase project.';
        case 'unavailable':
          return 'Cloud Firestore is temporarily unavailable. Check your connection and try again.';
        case 'deadline-exceeded':
          return 'Cloud Firestore took too long to respond. Please try again.';
      }

      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) {
        return 'Cloud sync failed: $message';
      }
      return 'Cloud sync failed (${error.code}).';
    }

    if (error is TimeoutException) {
      return 'Cloud Firestore did not respond within 15 seconds. Authentication is working, but the Firestore connection is not completing.';
    }

    if (error is StateError) {
      return error.message.toString();
    }

    return 'Cloud sync failed: $error';
  }

  Future<T> _withTimeout<T>(Future<T> future, String operation) {
    return future.timeout(
      _networkTimeout,
      onTimeout: () {
        throw TimeoutException('$operation timed out.', _networkTimeout);
      },
    );
  }
}

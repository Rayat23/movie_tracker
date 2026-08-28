import 'package:cloud_firestore/cloud_firestore.dart';

import 'account_service.dart';
import 'firebase_bootstrap.dart';
import 'profile_service.dart';

class CloudSyncService {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

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

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final profilesRef = userRef.collection('profiles');

    final existing = await profilesRef.get();
    final localIds = profiles
        .map((item) => Map<String, dynamic>.from(item as Map)['id'].toString())
        .toSet();

    final batch = firestore.batch();

    batch.set(
      userRef,
      {
        'email': user.email,
        'displayName': user.displayName,
        'activeProfileId': bundle['activeProfileId'],
        'updatedAt': FieldValue.serverTimestamp(),
        'schemaVersion': 1,
      },
      SetOptions(merge: true),
    );

    for (final doc in existing.docs) {
      if (!localIds.contains(doc.id)) {
        batch.delete(doc.reference);
      }
    }

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

    await batch.commit();
  }

  Future<bool> downloadCloudProfiles() async {
    final user = AccountService.instance.currentUser;
    if (!isAvailable || user == null) {
      throw StateError('Sign in before restoring profiles.');
    }

    final firestore = FirebaseFirestore.instance;
    final userRef = firestore.collection('users').doc(user.uid);
    final userSnapshot = await userRef.get();
    final profilesSnapshot = await userRef.collection('profiles').get();

    if (profilesSnapshot.docs.isEmpty) return false;

    final profiles = <Map<String, dynamic>>[];
    final snapshots = <String, Map<String, dynamic>>{};

    for (final doc in profilesSnapshot.docs) {
      final data = doc.data();
      final trackingData = data['trackingData'];

      profiles.add({
        'id': data['id'] ?? doc.id,
        'name': data['name'] ?? 'Profile',
        'avatarIndex': data['avatarIndex'] ?? 0,
        'createdAt': data['createdAt'] ?? DateTime.now().toIso8601String(),
      });

      snapshots[doc.id] = trackingData is Map
          ? Map<String, dynamic>.from(trackingData)
          : <String, dynamic>{};
    }

    final userData = userSnapshot.data();
    final activeProfileId = userData?['activeProfileId']?.toString();

    await ProfileService.instance.importCloudBundle({
      'version': 1,
      'activeProfileId': activeProfileId,
      'profiles': profiles,
      'snapshots': snapshots,
    });

    return true;
  }

  Future<DateTime?> lastCloudUpdate() async {
    final user = AccountService.instance.currentUser;
    if (!isAvailable || user == null) return null;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final value = snapshot.data()?['updatedAt'];
    if (value is Timestamp) return value.toDate();
    return null;
  }
}

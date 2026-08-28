import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
    if (kIsWeb) {
      await _uploadAllProfilesRest();
      return;
    }

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
        'schemaVersion': 3,
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
    if (kIsWeb) {
      return _downloadCloudProfilesRest();
    }

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
      'version': 3,
      'activeProfileId': activeProfileId,
      'profiles': profiles,
      'snapshots': snapshots,
    });

    return true;
  }

  Future<DateTime?> lastCloudUpdate() async {
    if (kIsWeb) {
      return _lastCloudUpdateRest();
    }

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
    final iso = snapshot.data()?['updatedAtIso']?.toString();
    return iso == null ? null : DateTime.tryParse(iso);
  }

  // FlutterFire's Firestore WebChannel can be blocked or buffered by some
  // browser/network environments even while Firebase Authentication works.
  // On web we use Firestore's official REST API with the signed-in user's
  // Firebase ID token. Security Rules still apply to these requests.
  Future<void> _uploadAllProfilesRest() async {
    final user = AccountService.instance.currentUser;
    if (!isAvailable || user == null) {
      throw StateError('Sign in before syncing profiles.');
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not get a Firebase sign-in token. Sign in again.');
    }

    final bundle = await ProfileService.instance.exportCloudBundle();
    final profiles = List<dynamic>.from(bundle['profiles'] as List<dynamic>);
    final snapshots = Map<String, dynamic>.from(
      bundle['snapshots'] as Map<String, dynamic>,
    );

    if (profiles.isEmpty) {
      throw StateError('There are no local profiles to back up.');
    }

    final now = DateTime.now().toUtc().toIso8601String();
    final profileIds = profiles
        .map((item) => Map<String, dynamic>.from(item as Map)['id'].toString())
        .toList(growable: false);

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    // Save each profile as its own document. JSON strings keep the REST
    // conversion simple while preserving the existing local data exactly.
    for (final rawProfile in profiles) {
      final profile = Map<String, dynamic>.from(rawProfile as Map);
      final id = profile['id'].toString();
      final rawData = snapshots[id];
      final trackingData = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      final response = await _withTimeout(
        http.patch(
          _restDocumentUri('users/${user.uid}/profiles/$id'),
          headers: headers,
          body: jsonEncode({
            'fields': {
              'profileJson': {'stringValue': jsonEncode(profile)},
              'trackingDataJson': {'stringValue': jsonEncode(trackingData)},
              'updatedAtIso': {'stringValue': now},
              'schemaVersion': {'integerValue': '3'},
            },
          }),
        ),
        'Cloud profile backup',
      );
      _throwForRestError(response, 'Cloud profile backup');
    }

    final userResponse = await _withTimeout(
      http.patch(
        _restDocumentUri('users/${user.uid}'),
        headers: headers,
        body: jsonEncode({
          'fields': {
            'email': {'stringValue': user.email ?? ''},
            'displayName': {'stringValue': user.displayName ?? ''},
            'activeProfileId': {
              'stringValue': bundle['activeProfileId']?.toString() ?? '',
            },
            'profileIds': {
              'arrayValue': {
                'values': profileIds
                    .map((id) => {'stringValue': id})
                    .toList(growable: false),
              },
            },
            'profileCount': {'integerValue': profileIds.length.toString()},
            'updatedAtIso': {'stringValue': now},
            'schemaVersion': {'integerValue': '3'},
          },
        }),
      ),
      'Cloud account backup',
    );
    _throwForRestError(userResponse, 'Cloud account backup');
  }

  Future<bool> _downloadCloudProfilesRest() async {
    final user = AccountService.instance.currentUser;
    if (!isAvailable || user == null) {
      throw StateError('Sign in before restoring profiles.');
    }

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) {
      throw StateError('Could not get a Firebase sign-in token. Sign in again.');
    }

    final headers = <String, String>{
      'Authorization': 'Bearer $token',
    };

    final userResponse = await _withTimeout(
      http.get(_restDocumentUri('users/${user.uid}'), headers: headers),
      'Cloud restore',
    );

    if (userResponse.statusCode == 404) return false;
    _throwForRestError(userResponse, 'Cloud restore');

    final userJson = jsonDecode(userResponse.body) as Map<String, dynamic>;
    final userFields = Map<String, dynamic>.from(
      userJson['fields'] as Map? ?? const <String, dynamic>{},
    );

    final profileIds = _restStringArray(userFields['profileIds']);
    if (profileIds.isEmpty) return false;

    final profiles = <Map<String, dynamic>>[];
    final snapshots = <String, Map<String, dynamic>>{};

    for (final profileId in profileIds) {
      final response = await _withTimeout(
        http.get(
          _restDocumentUri('users/${user.uid}/profiles/$profileId'),
          headers: headers,
        ),
        'Cloud restore',
      );

      if (response.statusCode == 404) continue;
      _throwForRestError(response, 'Cloud restore');

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = Map<String, dynamic>.from(
        json['fields'] as Map? ?? const <String, dynamic>{},
      );

      final profileJson = _restString(fields['profileJson']);
      final trackingJson = _restString(fields['trackingDataJson']);
      if (profileJson == null || profileJson.isEmpty) continue;

      final profile = Map<String, dynamic>.from(
        jsonDecode(profileJson) as Map,
      );
      profiles.add(profile);

      if (trackingJson != null && trackingJson.isNotEmpty) {
        snapshots[profileId] = Map<String, dynamic>.from(
          jsonDecode(trackingJson) as Map,
        );
      } else {
        snapshots[profileId] = <String, dynamic>{};
      }
    }

    if (profiles.isEmpty) return false;

    await ProfileService.instance.importCloudBundle({
      'version': 3,
      'activeProfileId': _restString(userFields['activeProfileId']),
      'profiles': profiles,
      'snapshots': snapshots,
    });

    return true;
  }

  Future<DateTime?> _lastCloudUpdateRest() async {
    final user = AccountService.instance.currentUser;
    if (!isAvailable || user == null) return null;

    final token = await user.getIdToken();
    if (token == null || token.isEmpty) return null;

    final response = await _withTimeout(
      http.get(
        _restDocumentUri('users/${user.uid}'),
        headers: {'Authorization': 'Bearer $token'},
      ),
      'Cloud status check',
    );

    if (response.statusCode == 404) return null;
    _throwForRestError(response, 'Cloud status check');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final fields = Map<String, dynamic>.from(
      json['fields'] as Map? ?? const <String, dynamic>{},
    );
    final iso = _restString(fields['updatedAtIso']);
    return iso == null ? null : DateTime.tryParse(iso);
  }

  Uri _restDocumentUri(String documentPath) {
    return Uri.parse(
      'https://firestore.googleapis.com/v1/projects/'
      '${FirebaseBootstrap.projectId}/databases/(default)/documents/$documentPath',
    );
  }

  String? _restString(dynamic rawValue) {
    if (rawValue is! Map) return null;
    return rawValue['stringValue']?.toString();
  }

  List<String> _restStringArray(dynamic rawValue) {
    if (rawValue is! Map) return const [];
    final arrayValue = rawValue['arrayValue'];
    if (arrayValue is! Map) return const [];
    final values = arrayValue['values'];
    if (values is! List) return const [];
    return values
        .map(_restString)
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  void _throwForRestError(http.Response response, String operation) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        message = error['message']?.toString() ?? message;
      }
    } catch (_) {
      // Keep the raw body if it was not JSON.
    }

    if (response.statusCode == 401) {
      throw StateError('Firebase sign-in expired. Sign out and sign in again.');
    }
    if (response.statusCode == 403) {
      throw StateError(
        'Cloud access was denied by Firestore Security Rules. '
        'Open Firestore → Security and publish the Movie Tracker rules. '
        'Firebase said: $message',
      );
    }
    if (response.statusCode == 404) {
      throw StateError(
        'Cloud Firestore could not find this database or document. '
        'Confirm the (default) Firestore database exists in project '
        '${FirebaseBootstrap.projectId}.',
      );
    }

    throw StateError('$operation failed (${response.statusCode}): $message');
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

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

    final firestore = FirebaseBootstrap.firestore;
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
        'schemaVersion': 4,
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
          'schemaVersion': 4,
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

    final firestore = FirebaseBootstrap.firestore;
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
      'version': 4,
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
      FirebaseBootstrap.firestore
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

  // FlutterFire's WebChannel transport can be blocked or buffered in some
  // browser/network environments even while Firebase Authentication works.
  // Web uses Firestore's REST API with the signed-in Firebase ID token.
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

    final writes = <Map<String, dynamic>>[];

    for (final rawProfile in profiles) {
      final profile = Map<String, dynamic>.from(rawProfile as Map);
      final id = profile['id'].toString();
      final rawData = snapshots[id];
      final trackingData = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      writes.add({
        'update': {
          'name': _restDocumentName('users/${user.uid}/profiles/$id'),
          'fields': _restProfileFields(profile, trackingData, now),
        },
      });
    }

    writes.add({
      'update': {
        'name': _restDocumentName('users/${user.uid}'),
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
          'schemaVersion': {'integerValue': '4'},
        },
      },
    });

    // Commit writes without a currentDocument precondition. Firestore treats
    // these as set/upsert writes: the first backup creates the documents and
    // later backups replace them. PATCH alone can return NOT_FOUND for a
    // document that has never existed.
    final response = await _withTimeout(
      http.post(
        _restCommitUri(),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'writes': writes}),
      ),
      'Cloud backup',
    );

    _throwForRestError(response, 'Cloud backup');
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

      Map<String, dynamic> profile;
      final profileJson = _restString(fields['profileJson']);
      if (profileJson != null && profileJson.isNotEmpty) {
        profile = Map<String, dynamic>.from(jsonDecode(profileJson) as Map);
      } else {
        profile = {
          'id': _restString(fields['id']) ?? profileId,
          'name': _restString(fields['name']) ?? 'Profile',
          'avatar_index': _restInt(fields['avatar_index']) ?? 0,
          'created_at': _restString(fields['created_at']) ??
              DateTime.now().toIso8601String(),
        };
      }
      profiles.add(profile);

      final trackingJson = _restString(fields['trackingDataJson']);
      if (trackingJson != null && trackingJson.isNotEmpty) {
        snapshots[profileId] = Map<String, dynamic>.from(
          jsonDecode(trackingJson) as Map,
        );
      } else {
        snapshots[profileId] = _restStringMap(fields['trackingData']);
      }
    }

    if (profiles.isEmpty) return false;

    await ProfileService.instance.importCloudBundle({
      'version': 4,
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

  Map<String, dynamic> _restProfileFields(
    Map<String, dynamic> profile,
    Map<String, dynamic> trackingData,
    String now,
  ) {
    final avatarIndex = (profile['avatar_index'] as num?)?.toInt() ?? 0;
    final trackingFields = <String, dynamic>{};

    for (final entry in trackingData.entries) {
      trackingFields[entry.key] = {'stringValue': entry.value.toString()};
    }

    return {
      'id': {'stringValue': profile['id']?.toString() ?? ''},
      'name': {'stringValue': profile['name']?.toString() ?? 'Profile'},
      'avatar_index': {'integerValue': avatarIndex.toString()},
      'created_at': {
        'stringValue':
            profile['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      },
      'profileJson': {'stringValue': jsonEncode(profile)},
      'trackingData': {
        'mapValue': {'fields': trackingFields},
      },
      'trackingDataJson': {'stringValue': jsonEncode(trackingData)},
      'updatedAtIso': {'stringValue': now},
      'schemaVersion': {'integerValue': '4'},
    };
  }

  Uri _restDocumentUri(String documentPath) {
    return Uri.parse(
      'https://firestore.googleapis.com/v1/projects/'
      '${FirebaseBootstrap.projectId}/databases/${FirebaseBootstrap.databaseId}/documents/$documentPath',
    );
  }

  Uri _restCommitUri() {
    return Uri.parse(
      'https://firestore.googleapis.com/v1/projects/'
      '${FirebaseBootstrap.projectId}/databases/${FirebaseBootstrap.databaseId}/documents:commit',
    );
  }

  String _restDocumentName(String documentPath) {
    return 'projects/${FirebaseBootstrap.projectId}/databases/${FirebaseBootstrap.databaseId}/documents/'
        '$documentPath';
  }

  String? _restString(dynamic rawValue) {
    if (rawValue is! Map) return null;
    return rawValue['stringValue']?.toString();
  }

  int? _restInt(dynamic rawValue) {
    if (rawValue is! Map) return null;
    return int.tryParse(rawValue['integerValue']?.toString() ?? '');
  }

  Map<String, dynamic> _restStringMap(dynamic rawValue) {
    if (rawValue is! Map) return <String, dynamic>{};
    final mapValue = rawValue['mapValue'];
    if (mapValue is! Map) return <String, dynamic>{};
    final fields = mapValue['fields'];
    if (fields is! Map) return <String, dynamic>{};

    final result = <String, dynamic>{};
    for (final entry in fields.entries) {
      final value = _restString(entry.value);
      if (value != null) result[entry.key.toString()] = value;
    }
    return result;
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
        '$operation returned 404 for Firestore database '
        '${FirebaseBootstrap.databaseId}. Firebase said: $message',
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

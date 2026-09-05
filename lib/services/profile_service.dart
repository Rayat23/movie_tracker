import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'favorites_service.dart';
import 'series_tracking_service.dart';
import 'sync_bootstrap_policy.dart';

class ProfileService {
  ProfileService._privateConstructor();

  static final ProfileService instance = ProfileService._privateConstructor();

  static const String _profilesKey = 'app_profiles_v1';
  static const String _activeProfileKey = 'active_profile_id_v1';

  static const List<String> _profileDataKeys = [
    'favorite_movies',
    'watchlist_movies',
    'watched_movies',
    'movie_ratings',
    'watched_dates',
    'movie_rewatch_dates_v1',
    'watched_tv_episodes_v1',
    'rewatched_tv_episodes_v1',
    'favorite_tv_shows_v1',
    'watchlist_tv_shows_v1',
    'tv_show_ratings_v1',
    'tv_season_ratings_v1',
    'tv_episode_ratings_v1',
    'tv_show_episode_totals_v1',
    'tv_season_episode_totals_v1',
  ];

  final List<UserProfile> _profiles = [];
  String? _activeProfileId;

  List<UserProfile> get profiles => List.unmodifiable(_profiles);

  UserProfile get activeProfile {
    if (_profiles.isEmpty) {
      throw StateError('ProfileService has not been initialized.');
    }

    return _profiles.firstWhere(
      (profile) => profile.id == _activeProfileId,
      orElse: () => _profiles.first,
    );
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final storedProfiles = prefs.getString(_profilesKey);

    _profiles.clear();

    if (storedProfiles != null && storedProfiles.isNotEmpty) {
      final decoded = jsonDecode(storedProfiles) as List<dynamic>;
      _profiles.addAll(
        decoded.map(
          (item) => UserProfile.fromJson(item as Map<String, dynamic>),
        ),
      );
    }

    if (_profiles.isEmpty) {
      final profile = UserProfile(
        id: _newProfileId(),
        name: 'My Profile',
        avatarIndex: 0,
        createdAt: DateTime.now(),
      );

      _profiles.add(profile);
      _activeProfileId = profile.id;

      await _saveProfiles(prefs);
      await prefs.setString(_activeProfileKey, profile.id);

      // Existing pre-profile Movie Tracker data becomes the first profile.
      await _snapshotBaseDataToProfile(prefs, profile.id);
      return;
    }

    final storedActiveId = prefs.getString(_activeProfileKey);
    final activeExists = _profiles.any((p) => p.id == storedActiveId);

    _activeProfileId = activeExists ? storedActiveId : _profiles.first.id;
    await prefs.setString(_activeProfileKey, _activeProfileId!);
  }

  Future<UserProfile> createProfile(
    String name, {
    int avatarIndex = 0,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Profile name cannot be empty.');
    }

    final prefs = await SharedPreferences.getInstance();

    if (_activeProfileId != null) {
      await _snapshotBaseDataToProfile(prefs, _activeProfileId!);
    }

    final profile = UserProfile(
      id: _newProfileId(),
      name: trimmedName,
      avatarIndex: avatarIndex,
      createdAt: DateTime.now(),
    );

    _profiles.add(profile);
    _activeProfileId = profile.id;

    await _saveProfiles(prefs);
    await prefs.setString(_activeProfileKey, profile.id);
    await _clearBaseData(prefs);
    await _reloadTrackingServices();

    return profile;
  }

  Future<void> switchProfile(String profileId) async {
    if (profileId == _activeProfileId) return;
    if (!_profiles.any((profile) => profile.id == profileId)) return;

    final prefs = await SharedPreferences.getInstance();

    if (_activeProfileId != null) {
      await _snapshotBaseDataToProfile(prefs, _activeProfileId!);
    }

    _activeProfileId = profileId;
    await prefs.setString(_activeProfileKey, profileId);
    await _restoreProfileDataToBase(prefs, profileId);
    await _reloadTrackingServices();
  }

  Future<void> renameProfile(String profileId, String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index == -1) return;

    _profiles[index] = _profiles[index].copyWith(name: trimmedName);

    final prefs = await SharedPreferences.getInstance();
    await _saveProfiles(prefs);
  }

  Future<void> setAvatar(String profileId, int avatarIndex) async {
    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index == -1) return;

    _profiles[index] = _profiles[index].copyWith(
      avatarIndex: avatarIndex.clamp(0, 7).toInt(),
    );

    final prefs = await SharedPreferences.getInstance();
    await _saveProfiles(prefs);
  }

  Future<bool> deleteProfile(String profileId) async {
    if (_profiles.length <= 1) return false;

    final index = _profiles.indexWhere((profile) => profile.id == profileId);
    if (index == -1) return false;

    final prefs = await SharedPreferences.getInstance();
    final deletingActive = profileId == _activeProfileId;

    _profiles.removeAt(index);
    await _removeProfileSnapshot(prefs, profileId);

    if (deletingActive) {
      final nextProfile = _profiles.first;
      _activeProfileId = nextProfile.id;
      await prefs.setString(_activeProfileKey, nextProfile.id);
      await _restoreProfileDataToBase(prefs, nextProfile.id);
      await _reloadTrackingServices();
    }

    await _saveProfiles(prefs);
    return true;
  }

  Future<void> persistActiveProfileData() async {
    if (_activeProfileId == null) return;

    final prefs = await SharedPreferences.getInstance();
    await _snapshotBaseDataToProfile(prefs, _activeProfileId!);
  }

  /// Returns false only for the untouched generated local shell: one default
  /// "My Profile", default avatar, and no non-empty movie/TV tracking state.
  ///
  /// This lets automatic cloud bootstrap replace a genuinely clean browser
  /// while treating any customized profile/library as data that must be kept.
  Future<bool> hasMeaningfulLocalState() async {
    if (_profiles.isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    if (_activeProfileId != null) {
      await _snapshotBaseDataToProfile(prefs, _activeProfileId!);
    }

    if (_profiles.length != 1) return true;

    final profile = _profiles.single;
    if (profile.name.trim() != 'My Profile' || profile.avatarIndex != 0) {
      return true;
    }

    for (final key in _profileDataKeys) {
      final scopedValue = prefs.getString(_scopedKey(profile.id, key));
      final baseValue = prefs.getString(key);
      if (SyncBootstrapPolicy.isMeaningfulTrackingValue(scopedValue) ||
          SyncBootstrapPolicy.isMeaningfulTrackingValue(baseValue)) {
        return true;
      }
    }

    return false;
  }

  /// Serializes every local profile and its tracking data for cloud backup.
  Future<Map<String, dynamic>> exportCloudBundle() async {
    final prefs = await SharedPreferences.getInstance();

    if (_activeProfileId != null) {
      await _snapshotBaseDataToProfile(prefs, _activeProfileId!);
    }

    final snapshots = <String, Map<String, String>>{};

    for (final profile in _profiles) {
      final data = <String, String>{};
      for (final key in _profileDataKeys) {
        final value = prefs.getString(_scopedKey(profile.id, key));
        if (value != null) data[key] = value;
      }
      snapshots[profile.id] = data;
    }

    return {
      'version': 1,
      'activeProfileId': _activeProfileId,
      'profiles': _profiles.map((profile) => profile.toJson()).toList(),
      'snapshots': snapshots,
    };
  }

  /// Replaces the local profile set with a previously exported cloud bundle.
  Future<void> importCloudBundle(Map<String, dynamic> bundle) async {
    final rawProfiles = bundle['profiles'];
    if (rawProfiles is! List || rawProfiles.isEmpty) {
      throw StateError('No cloud profiles were found for this account.');
    }

    final importedProfiles = rawProfiles
        .map(
          (item) => UserProfile.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();

    final prefs = await SharedPreferences.getInstance();

    for (final profile in _profiles) {
      await _removeProfileSnapshot(prefs, profile.id);
    }

    _profiles
      ..clear()
      ..addAll(importedProfiles);

    final requestedActiveId = bundle['activeProfileId']?.toString();
    final activeExists =
        _profiles.any((profile) => profile.id == requestedActiveId);
    _activeProfileId = activeExists ? requestedActiveId : _profiles.first.id;

    final rawSnapshots = bundle['snapshots'];
    final snapshots = rawSnapshots is Map
        ? Map<String, dynamic>.from(rawSnapshots)
        : <String, dynamic>{};

    for (final profile in _profiles) {
      final rawData = snapshots[profile.id];
      final data = rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : <String, dynamic>{};

      for (final key in _profileDataKeys) {
        final value = data[key];
        if (value == null) {
          await prefs.remove(_scopedKey(profile.id, key));
        } else {
          await prefs.setString(_scopedKey(profile.id, key), value.toString());
        }
      }
    }

    await _saveProfiles(prefs);
    await prefs.setString(_activeProfileKey, _activeProfileId!);
    await _restoreProfileDataToBase(prefs, _activeProfileId!);
    await _reloadTrackingServices();
  }

  Future<void> _reloadTrackingServices() async {
    await Future.wait([
      FavoritesService.instance.loadAll(),
      SeriesTrackingService.instance.loadAll(),
    ]);
  }

  Future<void> _snapshotBaseDataToProfile(
    SharedPreferences prefs,
    String profileId,
  ) async {
    for (final key in _profileDataKeys) {
      final value = prefs.getString(key);
      final scopedKey = _scopedKey(profileId, key);

      if (value == null) {
        await prefs.remove(scopedKey);
      } else {
        await prefs.setString(scopedKey, value);
      }
    }
  }

  Future<void> _restoreProfileDataToBase(
    SharedPreferences prefs,
    String profileId,
  ) async {
    for (final key in _profileDataKeys) {
      final scopedValue = prefs.getString(_scopedKey(profileId, key));

      if (scopedValue == null) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, scopedValue);
      }
    }
  }

  Future<void> _clearBaseData(SharedPreferences prefs) async {
    for (final key in _profileDataKeys) {
      await prefs.remove(key);
    }
  }

  Future<void> _removeProfileSnapshot(
    SharedPreferences prefs,
    String profileId,
  ) async {
    for (final key in _profileDataKeys) {
      await prefs.remove(_scopedKey(profileId, key));
    }
  }

  Future<void> _saveProfiles(SharedPreferences prefs) async {
    await prefs.setString(
      _profilesKey,
      jsonEncode(_profiles.map((profile) => profile.toJson()).toList()),
    );
  }

  String _scopedKey(String profileId, String key) {
    return 'profile:$profileId:$key';
  }

  String _newProfileId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'sync_bootstrap_policy.dart';

class LocalLibraryStateService {
  LocalLibraryStateService._();

  static final LocalLibraryStateService instance =
      LocalLibraryStateService._();

  static const String _profilesKey = 'app_profiles_v1';

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

  /// Reads local state without mutating profile snapshots.
  ///
  /// The only state considered non-meaningful is the generated untouched
  /// single "My Profile" shell with no non-empty movie/TV tracking data.
  Future<bool> hasMeaningfulState() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfiles = prefs.getString(_profilesKey);

    if (rawProfiles == null || rawProfiles.trim().isEmpty) {
      return _hasMeaningfulTrackingData(prefs);
    }

    try {
      final decoded = jsonDecode(rawProfiles);
      if (decoded is! List || decoded.isEmpty) {
        return _hasMeaningfulTrackingData(prefs);
      }

      if (decoded.length != 1) return true;

      final rawProfile = decoded.first;
      if (rawProfile is! Map) return true;

      final profile = Map<String, dynamic>.from(rawProfile);
      final name = profile['name']?.toString().trim() ?? '';
      final avatarIndex =
          int.tryParse((profile['avatar_index'] ?? profile['avatarIndex'] ?? 0)
                  .toString()) ??
              0;

      if (name != 'My Profile' || avatarIndex != 0) return true;

      return _hasMeaningfulTrackingData(prefs);
    } catch (_) {
      // Malformed/legacy profile metadata is data. Never classify it as a
      // disposable clean shell.
      return true;
    }
  }

  bool _hasMeaningfulTrackingData(SharedPreferences prefs) {
    for (final key in _profileDataKeys) {
      if (SyncBootstrapPolicy.isMeaningfulTrackingValue(
        prefs.getString(key),
      )) {
        return true;
      }
    }

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('profile:')) continue;
      if (SyncBootstrapPolicy.isMeaningfulTrackingValue(
        prefs.getString(key),
      )) {
        return true;
      }
    }

    return false;
  }
}

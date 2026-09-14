import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/tv_watch_entry.dart';
import 'local_change_service.dart';
import 'series_tracking_service.dart';

class TvWatchTimestampService {
  TvWatchTimestampService._();

  static final TvWatchTimestampService instance = TvWatchTimestampService._();

  static const String _watchedStorageKey = 'watched_tv_episodes_v1';
  static const String _rewatchStorageKey = 'rewatched_tv_episodes_v1';

  Future<bool> updateWatchTimestamp(
    TvWatchEntry original,
    DateTime replacement,
  ) async {
    if (replacement.isAfter(DateTime.now())) return false;

    final prefs = await SharedPreferences.getInstance();

    final updatedWatched = await _replaceTimestamp(
      prefs: prefs,
      storageKey: _watchedStorageKey,
      original: original,
      replacement: replacement,
    );

    final updated = updatedWatched ||
        await _replaceTimestamp(
          prefs: prefs,
          storageKey: _rewatchStorageKey,
          original: original,
          replacement: replacement,
        );

    if (!updated) return false;

    await SeriesTrackingService.instance.loadAll();
    await LocalChangeService.instance.markDirty();
    return true;
  }

  Future<bool> _replaceTimestamp({
    required SharedPreferences prefs,
    required String storageKey,
    required TvWatchEntry original,
    required DateTime replacement,
  }) async {
    final stored = prefs.getString(storageKey);
    if (stored == null || stored.isEmpty) return false;

    final decoded = jsonDecode(stored);
    if (decoded is! List) return false;

    for (final item in decoded) {
      if (item is! Map<String, dynamic>) continue;

      final watchedAt = DateTime.tryParse(item['watched_at']?.toString() ?? '');
      if (item['show_id'] == original.showId &&
          item['episode_id'] == original.episodeId &&
          watchedAt != null &&
          watchedAt.isAtSameMomentAs(original.watchedAt)) {
        item['watched_at'] = replacement.toIso8601String();
        await prefs.setString(storageKey, jsonEncode(decoded));
        return true;
      }
    }

    return false;
  }
}

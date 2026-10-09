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

  Future<bool> updateWatchDate({
    required TvWatchEntry entry,
    required DateTime replacement,
    required bool isRewatch,
    int? sourceIndex,
  }) async {
    if (replacement.isAfter(DateTime.now())) return false;

    final prefs = await SharedPreferences.getInstance();
    final storageKey = isRewatch ? _rewatchStorageKey : _watchedStorageKey;
    final stored = prefs.getString(storageKey);
    if (stored == null || stored.isEmpty) return false;

    final decoded = jsonDecode(stored);
    if (decoded is! List) return false;

    bool matches(dynamic item) {
      if (item is! Map) return false;

      final watchedAt = DateTime.tryParse(item['watched_at']?.toString() ?? '');
      return item['show_id'] == entry.showId &&
          item['episode_id'] == entry.episodeId &&
          item['season_number'] == entry.seasonNumber &&
          item['episode_number'] == entry.episodeNumber &&
          watchedAt != null &&
          watchedAt.isAtSameMomentAs(entry.watchedAt);
    }

    // A minute-precision edit can make two rewatches share the same timestamp.
    // When the diary provides the persisted index, verify that exact entry
    // before writing; never silently edit the first matching rewatch instead.
    final index = sourceIndex == null
        ? decoded.indexWhere(matches)
        : (sourceIndex >= 0 &&
                sourceIndex < decoded.length &&
                matches(decoded[sourceIndex])
            ? sourceIndex
            : -1);

    if (index == -1) return false;

    final updated = Map<String, dynamic>.from(
      decoded[index] as Map<dynamic, dynamic>,
    );
    updated['watched_at'] = replacement.toIso8601String();
    decoded[index] = updated;

    await prefs.setString(storageKey, jsonEncode(decoded));
    await LocalChangeService.instance.markDirty();
    await SeriesTrackingService.instance.loadAll();
    return true;
  }
}

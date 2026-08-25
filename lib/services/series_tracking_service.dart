import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/episode.dart';
import '../models/season.dart';
import '../models/tv_show.dart';
import '../models/tv_watch_entry.dart';

class SeriesTrackingService {
  SeriesTrackingService._privateConstructor();

  static final SeriesTrackingService instance =
      SeriesTrackingService._privateConstructor();

  static const String _storageKey = 'watched_tv_episodes_v1';

  final List<TvWatchEntry> _entries = [];

  List<TvWatchEntry> get watchedEpisodes {
    final copy = List<TvWatchEntry>.from(_entries);
    copy.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return List.unmodifiable(copy);
  }

  int get totalWatchedEpisodes => _entries.length;

  int get totalTvMinutes => _entries.fold(
        0,
        (total, entry) => total + entry.runtimeMinutes,
      );

  int get watchedSeriesCount =>
      _entries.map((entry) => entry.showId).toSet().length;

  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);

    _entries.clear();

    if (stored == null || stored.isEmpty) {
      return;
    }

    final decoded = jsonDecode(stored) as List<dynamic>;

    _entries.addAll(
      decoded.map(
        (item) => TvWatchEntry.fromJson(
          item as Map<String, dynamic>,
        ),
      ),
    );
  }

  bool isEpisodeWatched(int showId, int episodeId) {
    return _entries.any(
      (entry) => entry.showId == showId && entry.episodeId == episodeId,
    );
  }

  DateTime? watchedDateForEpisode(int showId, int episodeId) {
    for (final entry in _entries) {
      if (entry.showId == showId && entry.episodeId == episodeId) {
        return entry.watchedAt;
      }
    }

    return null;
  }

  int watchedEpisodeCountForShow(int showId) {
    return _entries.where((entry) => entry.showId == showId).length;
  }

  int watchedEpisodeCountForSeason(int showId, int seasonNumber) {
    return _entries
        .where(
          (entry) =>
              entry.showId == showId &&
              entry.seasonNumber == seasonNumber,
        )
        .length;
  }

  int watchedMinutesForShow(int showId) {
    return _entries
        .where((entry) => entry.showId == showId)
        .fold(0, (total, entry) => total + entry.runtimeMinutes);
  }

  Future<void> toggleEpisodeWatched(
    TvShow show,
    Episode episode,
  ) async {
    if (isEpisodeWatched(show.id, episode.id)) {
      _entries.removeWhere(
        (entry) =>
            entry.showId == show.id && entry.episodeId == episode.id,
      );
    } else {
      _entries.add(
        _entryFromEpisode(
          show,
          episode,
          DateTime.now(),
        ),
      );
    }

    await _save();
  }

  Future<void> setSeasonWatched({
    required TvShow show,
    required Season season,
    required List<Episode> episodes,
    required bool watched,
  }) async {
    if (watched) {
      final now = DateTime.now();

      for (final episode in episodes) {
        if (!isEpisodeWatched(show.id, episode.id)) {
          _entries.add(
            _entryFromEpisode(show, episode, now),
          );
        }
      }
    } else {
      _entries.removeWhere(
        (entry) =>
            entry.showId == show.id &&
            entry.seasonNumber == season.seasonNumber,
      );
    }

    await _save();
  }

  TvWatchEntry _entryFromEpisode(
    TvShow show,
    Episode episode,
    DateTime watchedAt,
  ) {
    return TvWatchEntry(
      showId: show.id,
      showName: show.name,
      showPosterPath: show.posterPath,
      seasonNumber: episode.seasonNumber,
      episodeId: episode.id,
      episodeNumber: episode.episodeNumber,
      episodeName: episode.name,
      episodeStillPath: episode.stillPath,
      runtimeMinutes: episode.runtimeMinutes,
      watchedAt: watchedAt,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _entries.map((entry) => entry.toJson()).toList(),
    );

    await prefs.setString(_storageKey, encoded);
  }
}

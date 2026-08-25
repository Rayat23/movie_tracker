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

  static const String _watchedStorageKey = 'watched_tv_episodes_v1';
  static const String _rewatchStorageKey = 'rewatched_tv_episodes_v1';
  static const String _favoritesStorageKey = 'favorite_tv_shows_v1';
  static const String _watchlistStorageKey = 'watchlist_tv_shows_v1';
  static const String _ratingsStorageKey = 'tv_show_ratings_v1';
  static const String _seasonRatingsStorageKey = 'tv_season_ratings_v1';
  static const String _episodeRatingsStorageKey = 'tv_episode_ratings_v1';
  static const String _showEpisodeTotalsStorageKey =
      'tv_show_episode_totals_v1';
  static const String _seasonEpisodeTotalsStorageKey =
      'tv_season_episode_totals_v1';

  final List<TvWatchEntry> _entries = [];
  final List<TvWatchEntry> _rewatches = [];
  final List<TvShow> _favorites = [];
  final List<TvShow> _watchlist = [];

  final Map<int, double> _ratings = {};
  final Map<String, double> _seasonRatings = {};
  final Map<String, double> _episodeRatings = {};
  final Map<int, int> _showEpisodeTotals = {};
  final Map<String, int> _seasonEpisodeTotals = {};

  List<TvWatchEntry> get watchedEpisodes {
    final copy = List<TvWatchEntry>.from(_entries);
    copy.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return List.unmodifiable(copy);
  }

  List<TvWatchEntry> get rewatchEpisodes {
    final copy = List<TvWatchEntry>.from(_rewatches);
    copy.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return List.unmodifiable(copy);
  }

  List<TvWatchEntry> get allWatchEvents {
    final copy = <TvWatchEntry>[
      ..._entries,
      ..._rewatches,
    ];
    copy.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));
    return List.unmodifiable(copy);
  }

  List<TvShow> get favorites => List.unmodifiable(_favorites);
  List<TvShow> get watchlist => List.unmodifiable(_watchlist);

  List<TvShow> get startedShows {
    final shows = <int, TvShow>{};

    for (final entry in watchedEpisodes) {
      shows.putIfAbsent(
        entry.showId,
        () => TvShow(
          id: entry.showId,
          name: entry.showName,
          posterPath: entry.showPosterPath,
          backdropPath: '',
          rating: 0,
          firstAirDate: '',
          overview: '',
        ),
      );
    }

    return List.unmodifiable(shows.values.toList());
  }

  int get totalWatchedEpisodes => _entries.length;
  int get totalTvRewatches => _rewatches.length;
  int get totalTvWatchEvents => _entries.length + _rewatches.length;

  int get totalTvMinutes => allWatchEvents.fold(
        0,
        (total, entry) => total + entry.runtimeMinutes,
      );

  int get watchedSeriesCount =>
      _entries.map((entry) => entry.showId).toSet().length;

  int get ratedSeriesCount => _ratings.length;
  int get ratedSeasonsCount => _seasonRatings.length;
  int get ratedEpisodesCount => _episodeRatings.length;

  int get completedSeriesCount {
    int count = 0;

    for (final item in _showEpisodeTotals.entries) {
      if (item.value > 0 &&
          watchedEpisodeCountForShow(item.key) >= item.value) {
        count++;
      }
    }

    return count;
  }

  int get completedSeasonCount {
    int count = 0;

    for (final item in _seasonEpisodeTotals.entries) {
      final parts = item.key.split(':');
      if (parts.length != 2) continue;

      final showId = int.tryParse(parts[0]);
      final seasonNumber = int.tryParse(parts[1]);

      if (showId == null || seasonNumber == null || seasonNumber <= 0) {
        continue;
      }

      if (item.value > 0 &&
          watchedEpisodeCountForSeason(showId, seasonNumber) >= item.value) {
        count++;
      }
    }

    return count;
  }

  double get averageSeriesRating {
    if (_ratings.isEmpty) return 0;

    final total = _ratings.values.fold<double>(
      0,
      (sum, rating) => sum + rating,
    );

    return total / _ratings.length;
  }

  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    _loadWatchedEntries(prefs.getString(_watchedStorageKey), _entries);
    _loadWatchedEntries(prefs.getString(_rewatchStorageKey), _rewatches);
    _loadShowList(
      prefs.getString(_favoritesStorageKey),
      _favorites,
    );
    _loadShowList(
      prefs.getString(_watchlistStorageKey),
      _watchlist,
    );
    _loadRatings(prefs.getString(_ratingsStorageKey));
    _loadStringDoubleMap(
      prefs.getString(_seasonRatingsStorageKey),
      _seasonRatings,
    );
    _loadStringDoubleMap(
      prefs.getString(_episodeRatingsStorageKey),
      _episodeRatings,
    );
    _loadIntIntMap(
      prefs.getString(_showEpisodeTotalsStorageKey),
      _showEpisodeTotals,
    );
    _loadStringIntMap(
      prefs.getString(_seasonEpisodeTotalsStorageKey),
      _seasonEpisodeTotals,
    );
  }

  void _loadWatchedEntries(String? stored, List<TvWatchEntry> target) {
    target.clear();

    if (stored == null || stored.isEmpty) {
      return;
    }

    final decoded = jsonDecode(stored) as List<dynamic>;

    target.addAll(
      decoded.map(
        (item) => TvWatchEntry.fromJson(
          item as Map<String, dynamic>,
        ),
      ),
    );
  }

  void _loadShowList(
    String? stored,
    List<TvShow> target,
  ) {
    target.clear();

    if (stored == null || stored.isEmpty) {
      return;
    }

    final decoded = jsonDecode(stored) as List<dynamic>;

    target.addAll(
      decoded.map(
        (item) => TvShow.fromJson(
          item as Map<String, dynamic>,
        ),
      ),
    );
  }

  void _loadRatings(String? stored) {
    _ratings.clear();

    if (stored == null || stored.isEmpty) {
      return;
    }

    final decoded = jsonDecode(stored) as Map<String, dynamic>;

    decoded.forEach((key, value) {
      final showId = int.tryParse(key);

      if (showId != null && value is num) {
        _ratings[showId] = value.toDouble();
      }
    });
  }

  void _loadStringDoubleMap(
    String? stored,
    Map<String, double> target,
  ) {
    target.clear();

    if (stored == null || stored.isEmpty) return;

    final decoded = jsonDecode(stored) as Map<String, dynamic>;

    decoded.forEach((key, value) {
      if (value is num) {
        target[key] = value.toDouble();
      }
    });
  }

  void _loadIntIntMap(
    String? stored,
    Map<int, int> target,
  ) {
    target.clear();

    if (stored == null || stored.isEmpty) return;

    final decoded = jsonDecode(stored) as Map<String, dynamic>;

    decoded.forEach((key, value) {
      final parsedKey = int.tryParse(key);
      if (parsedKey != null && value is num) {
        target[parsedKey] = value.toInt();
      }
    });
  }

  void _loadStringIntMap(
    String? stored,
    Map<String, int> target,
  ) {
    target.clear();

    if (stored == null || stored.isEmpty) return;

    final decoded = jsonDecode(stored) as Map<String, dynamic>;

    decoded.forEach((key, value) {
      if (value is num) {
        target[key] = value.toInt();
      }
    });
  }

  bool isFavorite(TvShow show) {
    return _favorites.any((item) => item.id == show.id);
  }

  bool isInWatchlist(TvShow show) {
    return _watchlist.any((item) => item.id == show.id);
  }

  double? getUserRating(TvShow show) {
    return _ratings[show.id];
  }

  double? getSeasonRating(int showId, int seasonNumber) {
    return _seasonRatings[_seasonKey(showId, seasonNumber)];
  }

  double? getEpisodeRating(int showId, int episodeId) {
    return _episodeRatings[_episodeKey(showId, episodeId)];
  }

  bool isEpisodeWatched(int showId, int episodeId) {
    return _entries.any(
      (entry) => entry.showId == showId && entry.episodeId == episodeId,
    );
  }

  bool isShowComplete(int showId) {
    final total = _showEpisodeTotals[showId] ?? 0;
    return total > 0 && watchedEpisodeCountForShow(showId) >= total;
  }

  bool isSeasonComplete(int showId, int seasonNumber) {
    final total = _seasonEpisodeTotals[_seasonKey(showId, seasonNumber)] ?? 0;
    return total > 0 &&
        watchedEpisodeCountForSeason(showId, seasonNumber) >= total;
  }

  DateTime? watchedDateForEpisode(int showId, int episodeId) {
    for (final entry in _entries) {
      if (entry.showId == showId && entry.episodeId == episodeId) {
        return entry.watchedAt;
      }
    }

    return null;
  }

  DateTime? latestWatchDateForEpisode(int showId, int episodeId) {
    final dates = allWatchEvents
        .where(
          (entry) => entry.showId == showId && entry.episodeId == episodeId,
        )
        .map((entry) => entry.watchedAt)
        .toList()
      ..sort();

    return dates.isEmpty ? null : dates.last;
  }

  int episodeWatchCount(int showId, int episodeId) {
    return allWatchEvents
        .where(
          (entry) => entry.showId == showId && entry.episodeId == episodeId,
        )
        .length;
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
    return allWatchEvents
        .where((entry) => entry.showId == showId)
        .fold(0, (total, entry) => total + entry.runtimeMinutes);
  }

  Future<void> toggleFavorite(TvShow show) async {
    if (isFavorite(show)) {
      _favorites.removeWhere((item) => item.id == show.id);
    } else {
      _favorites.add(show);
    }

    await _saveShowList(_favoritesStorageKey, _favorites);
  }

  Future<void> toggleWatchlist(TvShow show) async {
    if (isInWatchlist(show)) {
      _watchlist.removeWhere((item) => item.id == show.id);
    } else {
      _watchlist.add(show);
    }

    await _saveShowList(_watchlistStorageKey, _watchlist);
  }

  Future<void> setUserRating(TvShow show, double rating) async {
    _ratings[show.id] = rating.clamp(1, 10).toDouble();
    await _saveRatings();
  }

  Future<void> removeUserRating(TvShow show) async {
    _ratings.remove(show.id);
    await _saveRatings();
  }

  Future<void> setSeasonRating(
    int showId,
    int seasonNumber,
    double rating,
  ) async {
    _seasonRatings[_seasonKey(showId, seasonNumber)] =
        rating.clamp(1, 10).toDouble();
    await _saveStringDoubleMap(
      _seasonRatingsStorageKey,
      _seasonRatings,
    );
  }

  Future<void> removeSeasonRating(int showId, int seasonNumber) async {
    _seasonRatings.remove(_seasonKey(showId, seasonNumber));
    await _saveStringDoubleMap(
      _seasonRatingsStorageKey,
      _seasonRatings,
    );
  }

  Future<void> setEpisodeRating(
    int showId,
    int episodeId,
    double rating,
  ) async {
    _episodeRatings[_episodeKey(showId, episodeId)] =
        rating.clamp(1, 10).toDouble();
    await _saveStringDoubleMap(
      _episodeRatingsStorageKey,
      _episodeRatings,
    );
  }

  Future<void> removeEpisodeRating(int showId, int episodeId) async {
    _episodeRatings.remove(_episodeKey(showId, episodeId));
    await _saveStringDoubleMap(
      _episodeRatingsStorageKey,
      _episodeRatings,
    );
  }

  Future<void> toggleEpisodeWatched(
    TvShow show,
    Episode episode, {
    int? seasonEpisodeCount,
  }) async {
    await _rememberProgressMetadata(
      show: show,
      seasonNumber: episode.seasonNumber,
      seasonEpisodeCount: seasonEpisodeCount,
    );

    if (isEpisodeWatched(show.id, episode.id)) {
      _entries.removeWhere(
        (entry) =>
            entry.showId == show.id && entry.episodeId == episode.id,
      );
      _rewatches.removeWhere(
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

      _rewatches.removeWhere(
        (entry) =>
            entry.showId == show.id && entry.episodeId == episode.id,
      );

      if (isInWatchlist(show)) {
        _watchlist.removeWhere((item) => item.id == show.id);
        await _saveShowList(_watchlistStorageKey, _watchlist);
      }
    }

    await _saveWatchedEntries();
    await _saveRewatchEntries();
  }

  Future<void> logEpisodeRewatch(
    TvShow show,
    Episode episode, {
    int? seasonEpisodeCount,
  }) async {
    if (!isEpisodeWatched(show.id, episode.id)) return;

    await _rememberProgressMetadata(
      show: show,
      seasonNumber: episode.seasonNumber,
      seasonEpisodeCount: seasonEpisodeCount,
    );

    _rewatches.add(
      _entryFromEpisode(
        show,
        episode,
        DateTime.now(),
      ),
    );

    await _saveRewatchEntries();
  }

  Future<void> setSeasonWatched({
    required TvShow show,
    required Season season,
    required List<Episode> episodes,
    required bool watched,
  }) async {
    await _rememberProgressMetadata(
      show: show,
      seasonNumber: season.seasonNumber,
      seasonEpisodeCount: season.episodeCount,
    );

    if (watched) {
      final now = DateTime.now();

      for (final episode in episodes) {
        if (!isEpisodeWatched(show.id, episode.id)) {
          _entries.add(
            _entryFromEpisode(show, episode, now),
          );
        }
      }

      if (isInWatchlist(show)) {
        _watchlist.removeWhere((item) => item.id == show.id);
        await _saveShowList(_watchlistStorageKey, _watchlist);
      }
    } else {
      _entries.removeWhere(
        (entry) =>
            entry.showId == show.id &&
            entry.seasonNumber == season.seasonNumber,
      );
      _rewatches.removeWhere(
        (entry) =>
            entry.showId == show.id &&
            entry.seasonNumber == season.seasonNumber,
      );
    }

    await _saveWatchedEntries();
    await _saveRewatchEntries();
  }

  Future<void> _rememberProgressMetadata({
    required TvShow show,
    required int seasonNumber,
    int? seasonEpisodeCount,
  }) async {
    bool showChanged = false;
    bool seasonChanged = false;

    if (show.numberOfEpisodes > 0 &&
        _showEpisodeTotals[show.id] != show.numberOfEpisodes) {
      _showEpisodeTotals[show.id] = show.numberOfEpisodes;
      showChanged = true;
    }

    if (seasonEpisodeCount != null && seasonEpisodeCount > 0) {
      final key = _seasonKey(show.id, seasonNumber);
      if (_seasonEpisodeTotals[key] != seasonEpisodeCount) {
        _seasonEpisodeTotals[key] = seasonEpisodeCount;
        seasonChanged = true;
      }
    }

    if (showChanged) {
      await _saveIntIntMap(
        _showEpisodeTotalsStorageKey,
        _showEpisodeTotals,
      );
    }

    if (seasonChanged) {
      await _saveStringIntMap(
        _seasonEpisodeTotalsStorageKey,
        _seasonEpisodeTotals,
      );
    }
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

  String _seasonKey(int showId, int seasonNumber) {
    return '$showId:$seasonNumber';
  }

  String _episodeKey(int showId, int episodeId) {
    return '$showId:$episodeId';
  }

  Future<void> _saveWatchedEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _entries.map((entry) => entry.toJson()).toList(),
    );

    await prefs.setString(_watchedStorageKey, encoded);
  }

  Future<void> _saveRewatchEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _rewatches.map((entry) => entry.toJson()).toList(),
    );

    await prefs.setString(_rewatchStorageKey, encoded);
  }

  Future<void> _saveShowList(
    String key,
    List<TvShow> shows,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      shows.map((show) => show.toJson()).toList(),
    );

    await prefs.setString(key, encoded);
  }

  Future<void> _saveRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _ratings.map(
        (showId, rating) => MapEntry(showId.toString(), rating),
      ),
    );

    await prefs.setString(_ratingsStorageKey, encoded);
  }

  Future<void> _saveStringDoubleMap(
    String key,
    Map<String, double> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(values));
  }

  Future<void> _saveIntIntMap(
    String key,
    Map<int, int> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      values.map(
        (itemKey, value) => MapEntry(itemKey.toString(), value),
      ),
    );
    await prefs.setString(key, encoded);
  }

  Future<void> _saveStringIntMap(
    String key,
    Map<String, int> values,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(values));
  }
}

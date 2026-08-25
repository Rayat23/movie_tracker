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
  static const String _favoritesStorageKey = 'favorite_tv_shows_v1';
  static const String _watchlistStorageKey = 'watchlist_tv_shows_v1';
  static const String _ratingsStorageKey = 'tv_show_ratings_v1';

  final List<TvWatchEntry> _entries = [];
  final List<TvShow> _favorites = [];
  final List<TvShow> _watchlist = [];
  final Map<int, double> _ratings = {};

  List<TvWatchEntry> get watchedEpisodes {
    final copy = List<TvWatchEntry>.from(_entries);
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

  int get totalTvMinutes => _entries.fold(
        0,
        (total, entry) => total + entry.runtimeMinutes,
      );

  int get watchedSeriesCount =>
      _entries.map((entry) => entry.showId).toSet().length;

  int get ratedSeriesCount => _ratings.length;

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

    _loadWatchedEntries(prefs.getString(_watchedStorageKey));
    _loadShowList(
      prefs.getString(_favoritesStorageKey),
      _favorites,
    );
    _loadShowList(
      prefs.getString(_watchlistStorageKey),
      _watchlist,
    );
    _loadRatings(prefs.getString(_ratingsStorageKey));
  }

  void _loadWatchedEntries(String? stored) {
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

  bool isFavorite(TvShow show) {
    return _favorites.any((item) => item.id == show.id);
  }

  bool isInWatchlist(TvShow show) {
    return _watchlist.any((item) => item.id == show.id);
  }

  double? getUserRating(TvShow show) {
    return _ratings[show.id];
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

      if (isInWatchlist(show)) {
        _watchlist.removeWhere((item) => item.id == show.id);
        await _saveShowList(_watchlistStorageKey, _watchlist);
      }
    }

    await _saveWatchedEntries();
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
    }

    await _saveWatchedEntries();
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

  Future<void> _saveWatchedEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _entries.map((entry) => entry.toJson()).toList(),
    );

    await prefs.setString(_watchedStorageKey, encoded);
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
}

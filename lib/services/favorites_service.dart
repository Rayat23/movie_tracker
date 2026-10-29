import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';
import 'local_change_service.dart';
import 'profile_service.dart';

class FavoritesService {
  FavoritesService._privateConstructor();

  static final FavoritesService instance =
      FavoritesService._privateConstructor();

  static const String _favoritesKey = 'favorite_movies';
  static const String _watchlistKey = 'watchlist_movies';
  static const String _watchedKey = 'watched_movies';
  static const String _ratingsKey = 'movie_ratings';
  static const String _watchedDatesKey = 'watched_dates';
  static const String _rewatchDatesKey = 'movie_rewatch_dates_v1';

  final List<Movie> _favorites = [];
  final List<Movie> _watchlist = [];
  final List<Movie> _watched = [];

  final Map<int, double> _ratings = {};
  final Map<int, DateTime> _watchedDates = {};
  final Map<int, List<DateTime>> _rewatchDates = {};
  // Index of each valid in-memory rewatch in the original persisted JSON list.
  // Invalid legacy timestamps are skipped for display, not renumbered for edits.
  final Map<int, List<int>> _rewatchSourceIndices = {};

  List<Movie> get favorites => List.unmodifiable(_favorites);
  List<Movie> get watchlist => List.unmodifiable(_watchlist);
  List<Movie> get watched => List.unmodifiable(_watched);

  int get totalMovieWatchEvents {
    int total = 0;
    for (final movie in _watched) {
      total += getMovieWatchCount(movie);
    }
    return total;
  }

  int get totalMovieRewatches => _rewatchDates.values.fold(
        0,
        (total, dates) => total + dates.length,
      );

  int get totalMovieMinutes {
    int total = 0;
    for (final movie in _watched) {
      total += movie.runtimeMinutes * getMovieWatchCount(movie);
    }
    return total;
  }

  bool isFavorite(Movie movie) => _favorites.any((m) => m.id == movie.id);
  bool isInWatchlist(Movie movie) =>
      _watchlist.any((m) => m.id == movie.id);
  bool isWatched(Movie movie) => _watched.any((m) => m.id == movie.id);
  double? getUserRating(Movie movie) => _ratings[movie.id];
  DateTime? getWatchedDate(Movie movie) => _watchedDates[movie.id];

  List<DateTime> getMovieWatchDates(Movie movie) {
    final dates = <DateTime>[];
    final firstWatch = _watchedDates[movie.id];
    if (firstWatch != null) dates.add(firstWatch);
    dates.addAll(_rewatchDates[movie.id] ?? const <DateTime>[]);
    dates.sort();
    return List.unmodifiable(dates);
  }

  DateTime? getLatestMovieWatchDate(Movie movie) {
    final dates = getMovieWatchDates(movie);
    return dates.isEmpty ? null : dates.last;
  }

  int getMovieWatchCount(Movie movie) => getMovieWatchDates(movie).length;

  /// Original watch and rewatches must retain their source identity even when
  /// a rewatch is backdated before the original or dates are duplicated.
  List<DateTime> getMovieRewatchDatesInStorageOrder(Movie movie) =>
      List.unmodifiable(_rewatchDates[movie.id] ?? const <DateTime>[]);

  List<int> getMovieRewatchSourceIndicesInStorageOrder(Movie movie) =>
      List.unmodifiable(_rewatchSourceIndices[movie.id] ?? const <int>[]);

  /// Edits exactly one persisted watch event, without rewriting unrelated keys.
  /// Rejects stale diary pickers and ambiguous/mismatched source indices.
  Future<bool> updateMovieWatchDate(
    Movie movie,
    DateTime original,
    DateTime replacement, {
    required bool isRewatch,
    required int sourceIndex,
    required String expectedProfileId,
  }) async {
    if (replacement.isAfter(DateTime.now())) return false;

    final prefs = await SharedPreferences.getInstance();
    bool profileMatches() =>
        ProfileService.instance.profiles.isNotEmpty &&
        ProfileService.instance.activeProfile.id == expectedProfileId &&
        prefs.getString('active_profile_id_v1') == expectedProfileId;
    if (!profileMatches()) return false;

    final id = movie.id.toString();
    final storageKey = isRewatch ? _rewatchDatesKey : _watchedDatesKey;
    final stored = prefs.getString(storageKey);
    if (stored == null || stored.isEmpty) return false;
    final decoded = jsonDecode(stored);
    if (decoded is! Map) return false;
    final updated = Map<String, dynamic>.from(decoded);
    final current = updated[id];

    if (isRewatch) {
      final inMemory = _rewatchDates[movie.id];
      final indices = _rewatchSourceIndices[movie.id];
      if (current is! List || inMemory == null || indices == null ||
          sourceIndex < 0 || sourceIndex >= current.length) {
        return false;
      }
      final memoryIndex = indices.indexOf(sourceIndex);
      if (memoryIndex < 0 || memoryIndex >= inMemory.length) {
        return false;
      }
      final persistedDate = DateTime.tryParse(current[sourceIndex].toString());
      if (persistedDate == null ||
          !persistedDate.isAtSameMomentAs(original) ||
          !inMemory[memoryIndex].isAtSameMomentAs(original)) {
        return false;
      }
      final revised = List<dynamic>.from(current);
      revised[sourceIndex] = replacement.toIso8601String();
      updated[id] = revised;
    } else {
      if (sourceIndex != 0) return false;
      final persistedDate = DateTime.tryParse(current?.toString() ?? '');
      final inMemory = _watchedDates[movie.id];
      if (persistedDate == null || inMemory == null ||
          !persistedDate.isAtSameMomentAs(original) ||
          !inMemory.isAtSameMomentAs(original)) {
        return false;
      }
      updated[id] = replacement.toIso8601String();
    }

    // Profile selection can change while the date/time picker is open.
    // No await occurs between this final identity check and the write call.
    if (!profileMatches()) return false;
    final saved = await prefs.setString(storageKey, jsonEncode(updated));
    if (!saved) return false;
    await LocalChangeService.instance.markDirty();
    await loadAll();
    return true;
  }

  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    _loadMovieList(prefs.getString(_favoritesKey), _favorites);
    _loadMovieList(prefs.getString(_watchlistKey), _watchlist);
    _loadMovieList(prefs.getString(_watchedKey), _watched);
    _loadRatings(prefs.getString(_ratingsKey));
    _loadWatchedDates(prefs.getString(_watchedDatesKey));
    _loadRewatchDates(prefs.getString(_rewatchDatesKey));
  }

  void _loadMovieList(String? stored, List<Movie> targetList) {
    if (stored == null || stored.isEmpty) {
      targetList.clear();
      return;
    }
    final List<dynamic> decoded = jsonDecode(stored);
    targetList
      ..clear()
      ..addAll(decoded.map((item) => Movie.fromJson(item as Map<String, dynamic>)));
  }

  void _loadRatings(String? stored) {
    if (stored == null || stored.isEmpty) {
      _ratings.clear();
      return;
    }
    final decoded = jsonDecode(stored) as Map<String, dynamic>;
    _ratings.clear();
    decoded.forEach((key, value) {
      final movieId = int.tryParse(key);
      if (movieId != null) _ratings[movieId] = (value as num).toDouble();
    });
  }

  void _loadWatchedDates(String? stored) {
    if (stored == null || stored.isEmpty) {
      _watchedDates.clear();
      return;
    }
    final decoded = jsonDecode(stored) as Map<String, dynamic>;
    _watchedDates.clear();
    decoded.forEach((key, value) {
      final movieId = int.tryParse(key);
      final watchedDate = DateTime.tryParse(value.toString());
      if (movieId != null && watchedDate != null) {
        _watchedDates[movieId] = watchedDate;
      }
    });
  }

  void _loadRewatchDates(String? stored) {
    _rewatchDates.clear();
    _rewatchSourceIndices.clear();
    if (stored == null || stored.isEmpty) return;
    final decoded = jsonDecode(stored) as Map<String, dynamic>;
    decoded.forEach((key, value) {
      final movieId = int.tryParse(key);
      if (movieId == null || value is! List) return;
      final dates = <DateTime>[];
      final sourceIndices = <int>[];
      for (var i = 0; i < value.length; i++) {
        final date = DateTime.tryParse(value[i].toString());
        if (date == null) continue;
        dates.add(date);
        sourceIndices.add(i);
      }
      if (dates.isNotEmpty) {
        _rewatchDates[movieId] = dates;
        _rewatchSourceIndices[movieId] = sourceIndices;
      }
    });
  }

  Future<void> _saveList(String key, List<Movie> movies) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(movies.map((movie) => movie.toJson()).toList()),
    );
    await LocalChangeService.instance.markDirty();
  }

  Future<void> toggle(Movie movie) async {
    if (isFavorite(movie)) {
      _favorites.removeWhere((m) => m.id == movie.id);
    } else {
      _favorites.add(movie);
    }
    await _saveList(_favoritesKey, _favorites);
  }

  Future<void> toggleWatchlist(Movie movie) async {
    if (isInWatchlist(movie)) {
      _watchlist.removeWhere((m) => m.id == movie.id);
    } else {
      _watchlist.add(movie);
      _watched.removeWhere((m) => m.id == movie.id);
      _watchedDates.remove(movie.id);
      _rewatchDates.remove(movie.id);
      await _saveList(_watchedKey, _watched);
      await _saveWatchedDates();
      await _saveRewatchDates();
    }
    await _saveList(_watchlistKey, _watchlist);
  }

  Future<void> toggleWatched(Movie movie) async {
    if (isWatched(movie)) {
      _watched.removeWhere((m) => m.id == movie.id);
      _watchedDates.remove(movie.id);
      _rewatchDates.remove(movie.id);
    } else {
      _watched.removeWhere((m) => m.id == movie.id);
      _watched.add(movie);
      _watchedDates[movie.id] = DateTime.now();
      _rewatchDates.remove(movie.id);
      _watchlist.removeWhere((m) => m.id == movie.id);
      await _saveList(_watchlistKey, _watchlist);
    }
    await _saveList(_watchedKey, _watched);
    await _saveWatchedDates();
    await _saveRewatchDates();
  }

  Future<void> logRewatch(Movie movie) async {
    if (!isWatched(movie)) return;
    final dates = _rewatchDates.putIfAbsent(movie.id, () => <DateTime>[]);
    dates.add(DateTime.now());
    dates.sort();
    await _saveRewatchDates();
  }

  Future<void> syncMovieMetadata(Movie movie) async {
    final favoritesChanged = _replaceMovie(_favorites, movie);
    final watchlistChanged = _replaceMovie(_watchlist, movie);
    final watchedChanged = _replaceMovie(_watched, movie);
    if (favoritesChanged) await _saveList(_favoritesKey, _favorites);
    if (watchlistChanged) await _saveList(_watchlistKey, _watchlist);
    if (watchedChanged) await _saveList(_watchedKey, _watched);
  }

  bool _replaceMovie(List<Movie> movies, Movie updatedMovie) {
    final index = movies.indexWhere((movie) => movie.id == updatedMovie.id);
    if (index == -1) return false;
    final oldMovie = movies[index];
    if (oldMovie.runtimeMinutes == updatedMovie.runtimeMinutes &&
        oldMovie.posterPath == updatedMovie.posterPath &&
        oldMovie.title == updatedMovie.title &&
        oldMovie.overview == updatedMovie.overview) {
      return false;
    }
    movies[index] = updatedMovie;
    return true;
  }

  Future<void> setUserRating(Movie movie, double rating) async {
    _ratings[movie.id] = rating;
    await _saveRatings();
  }

  Future<void> removeUserRating(Movie movie) async {
    _ratings.remove(movie.id);
    await _saveRatings();
  }

  Future<void> _saveRatings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _ratingsKey,
      jsonEncode(_ratings.map((id, rating) => MapEntry(id.toString(), rating))),
    );
    await LocalChangeService.instance.markDirty();
  }

  Future<void> _saveWatchedDates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _watchedDatesKey,
      jsonEncode(_watchedDates.map(
        (id, date) => MapEntry(id.toString(), date.toIso8601String()),
      )),
    );
    await LocalChangeService.instance.markDirty();
  }

  Future<void> _saveRewatchDates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _rewatchDatesKey,
      jsonEncode(_rewatchDates.map(
        (id, dates) => MapEntry(
          id.toString(),
          dates.map((date) => date.toIso8601String()).toList(),
        ),
      )),
    );
    // This save serializes only valid in-memory dates, so indices become dense.
    _rewatchSourceIndices
      ..clear()
      ..addAll(_rewatchDates.map((id, dates) =>
          MapEntry(id, List<int>.generate(dates.length, (i) => i))));
    await LocalChangeService.instance.markDirty();
  }
}

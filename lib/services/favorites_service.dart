import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

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

  int get totalMovieRewatches {
    return _rewatchDates.values.fold(
      0,
      (total, dates) => total + dates.length,
    );
  }

  int get totalMovieMinutes {
    int total = 0;

    for (final movie in _watched) {
      total += movie.runtimeMinutes * getMovieWatchCount(movie);
    }

    return total;
  }

  bool isFavorite(Movie movie) {
    return _favorites.any((m) => m.id == movie.id);
  }

  bool isInWatchlist(Movie movie) {
    return _watchlist.any((m) => m.id == movie.id);
  }

  bool isWatched(Movie movie) {
    return _watched.any((m) => m.id == movie.id);
  }

  double? getUserRating(Movie movie) {
    return _ratings[movie.id];
  }

  DateTime? getWatchedDate(Movie movie) {
    return _watchedDates[movie.id];
  }

  List<DateTime> getMovieWatchDates(Movie movie) {
    final dates = <DateTime>[];
    final firstWatch = _watchedDates[movie.id];

    if (firstWatch != null) {
      dates.add(firstWatch);
    }

    dates.addAll(_rewatchDates[movie.id] ?? const <DateTime>[]);
    dates.sort();

    return List.unmodifiable(dates);
  }

  DateTime? getLatestMovieWatchDate(Movie movie) {
    final dates = getMovieWatchDates(movie);
    return dates.isEmpty ? null : dates.last;
  }

  int getMovieWatchCount(Movie movie) {
    return getMovieWatchDates(movie).length;
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

    targetList.clear();
    targetList.addAll(
      decoded.map((item) => Movie.fromJson(item as Map<String, dynamic>)),
    );
  }

  void _loadRatings(String? stored) {
    if (stored == null || stored.isEmpty) {
      _ratings.clear();
      return;
    }

    final Map<String, dynamic> decoded =
        jsonDecode(stored) as Map<String, dynamic>;

    _ratings.clear();

    decoded.forEach((key, value) {
      final movieId = int.tryParse(key);
      if (movieId != null) {
        _ratings[movieId] = (value as num).toDouble();
      }
    });
  }

  void _loadWatchedDates(String? stored) {
    if (stored == null || stored.isEmpty) {
      _watchedDates.clear();
      return;
    }

    final Map<String, dynamic> decoded =
        jsonDecode(stored) as Map<String, dynamic>;

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

    if (stored == null || stored.isEmpty) {
      return;
    }

    final decoded = jsonDecode(stored) as Map<String, dynamic>;

    decoded.forEach((key, value) {
      final movieId = int.tryParse(key);
      if (movieId == null || value is! List) return;

      final dates = value
          .map((item) => DateTime.tryParse(item.toString()))
          .whereType<DateTime>()
          .toList()
        ..sort();

      if (dates.isNotEmpty) {
        _rewatchDates[movieId] = dates;
      }
    });
  }

  Future<void> _saveList(String key, List<Movie> movies) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      movies.map((movie) => movie.toJson()).toList(),
    );

    await prefs.setString(key, encoded);
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
    bool favoritesChanged = _replaceMovie(_favorites, movie);
    bool watchlistChanged = _replaceMovie(_watchlist, movie);
    bool watchedChanged = _replaceMovie(_watched, movie);

    if (favoritesChanged) {
      await _saveList(_favoritesKey, _favorites);
    }

    if (watchlistChanged) {
      await _saveList(_watchlistKey, _watchlist);
    }

    if (watchedChanged) {
      await _saveList(_watchedKey, _watched);
    }
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

    final Map<String, double> ratingsToSave = _ratings.map(
      (movieId, rating) => MapEntry(movieId.toString(), rating),
    );

    await prefs.setString(_ratingsKey, jsonEncode(ratingsToSave));
  }

  Future<void> _saveWatchedDates() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, String> datesToSave = _watchedDates.map(
      (movieId, date) => MapEntry(movieId.toString(), date.toIso8601String()),
    );

    await prefs.setString(_watchedDatesKey, jsonEncode(datesToSave));
  }

  Future<void> _saveRewatchDates() async {
    final prefs = await SharedPreferences.getInstance();

    final datesToSave = _rewatchDates.map(
      (movieId, dates) => MapEntry(
        movieId.toString(),
        dates.map((date) => date.toIso8601String()).toList(),
      ),
    );

    await prefs.setString(_rewatchDatesKey, jsonEncode(datesToSave));
  }
}

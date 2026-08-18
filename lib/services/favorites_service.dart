import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

class FavoritesService {
  FavoritesService._privateConstructor();

  static final FavoritesService instance =
      FavoritesService._privateConstructor();

  // --------------------------------------------------
  // STORAGE KEYS
  // --------------------------------------------------

  static const String _favoritesKey = 'favorite_movies';
  static const String _watchlistKey = 'watchlist_movies';
  static const String _watchedKey = 'watched_movies';
  static const String _ratingsKey = 'movie_ratings';
  static const String _watchedDatesKey = 'watched_dates';

  // --------------------------------------------------
  // DATA
  // --------------------------------------------------

  final List<Movie> _favorites = [];
  final List<Movie> _watchlist = [];
  final List<Movie> _watched = [];

  // Movie ID -> user's rating
  final Map<int, double> _ratings = {};

  // Movie ID -> watched date
  final Map<int, DateTime> _watchedDates = {};

  // --------------------------------------------------
  // GETTERS
  // --------------------------------------------------

  List<Movie> get favorites => List.unmodifiable(_favorites);

  List<Movie> get watchlist => List.unmodifiable(_watchlist);

  List<Movie> get watched => List.unmodifiable(_watched);

  // --------------------------------------------------
  // CHECK STATUS
  // --------------------------------------------------

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

  // --------------------------------------------------
  // LOAD EVERYTHING
  // --------------------------------------------------

  Future<void> loadAll() async {
    final prefs = await SharedPreferences.getInstance();

    _loadMovieList(prefs.getString(_favoritesKey), _favorites);

    _loadMovieList(prefs.getString(_watchlistKey), _watchlist);

    _loadMovieList(prefs.getString(_watchedKey), _watched);

    _loadRatings(prefs.getString(_ratingsKey));

    _loadWatchedDates(prefs.getString(_watchedDatesKey));
  }

  // --------------------------------------------------
  // LOAD MOVIE LIST
  // --------------------------------------------------

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

  // --------------------------------------------------
  // LOAD RATINGS
  // --------------------------------------------------

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

  // --------------------------------------------------
  // LOAD WATCHED DATES
  // --------------------------------------------------

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

  // --------------------------------------------------
  // SAVE MOVIE LIST
  // --------------------------------------------------

  Future<void> _saveList(String key, List<Movie> movies) async {
    final prefs = await SharedPreferences.getInstance();

    final String encoded = jsonEncode(
      movies.map((movie) => movie.toJson()).toList(),
    );

    await prefs.setString(key, encoded);
  }

  // --------------------------------------------------
  // FAVORITES
  // --------------------------------------------------

  Future<void> toggle(Movie movie) async {
    if (isFavorite(movie)) {
      _favorites.removeWhere((m) => m.id == movie.id);
    } else {
      _favorites.add(movie);
    }

    await _saveList(_favoritesKey, _favorites);
  }

  // --------------------------------------------------
  // WATCHLIST
  // --------------------------------------------------

  Future<void> toggleWatchlist(Movie movie) async {
    if (isInWatchlist(movie)) {
      _watchlist.removeWhere((m) => m.id == movie.id);
    } else {
      _watchlist.add(movie);

      // Moving back to Watchlist means
      // it is no longer marked as Watched.
      _watched.removeWhere((m) => m.id == movie.id);

      _watchedDates.remove(movie.id);

      await _saveList(_watchedKey, _watched);

      await _saveWatchedDates();
    }

    await _saveList(_watchlistKey, _watchlist);
  }

  // --------------------------------------------------
  // WATCHED
  // --------------------------------------------------

  Future<void> toggleWatched(Movie movie) async {
    if (isWatched(movie)) {
      // Remove from watched.
      _watched.removeWhere((m) => m.id == movie.id);

      _watchedDates.remove(movie.id);
    } else {
      // Add to watched.
      _watched.add(movie);

      // Save the exact time it was
      // marked as watched.
      _watchedDates[movie.id] = DateTime.now();

      // Remove it from Watchlist.
      _watchlist.removeWhere((m) => m.id == movie.id);

      await _saveList(_watchlistKey, _watchlist);
    }

    await _saveList(_watchedKey, _watched);

    await _saveWatchedDates();
  }

  // --------------------------------------------------
  // USER RATINGS
  // --------------------------------------------------

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

  // --------------------------------------------------
  // WATCHED DATES
  // --------------------------------------------------

  Future<void> _saveWatchedDates() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, String> datesToSave = _watchedDates.map(
      (movieId, date) => MapEntry(movieId.toString(), date.toIso8601String()),
    );

    await prefs.setString(_watchedDatesKey, jsonEncode(datesToSave));
  }
}

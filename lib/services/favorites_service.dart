import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movie.dart';

class FavoritesService {
  FavoritesService._privateConstructor();
  static final FavoritesService instance =
      FavoritesService._privateConstructor();

  static const String _storageKey = 'favorite_movies';

  final List<Movie> _favorites = [];

  List<Movie> get favorites => _favorites;

  bool isFavorite(Movie movie) {
    return _favorites.any((m) => m.id == movie.id);
  }

  // Load saved favorites from the device. Call this once at app start.
  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString(_storageKey);

    if (stored == null) return;

    final List<dynamic> decoded = jsonDecode(stored);
    _favorites.clear();
    _favorites.addAll(
      decoded.map((item) => Movie.fromJson(item as Map<String, dynamic>)),
    );
  }

  // Save the current list to the device.
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _favorites.map((movie) => movie.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> toggle(Movie movie) async {
    if (isFavorite(movie)) {
      _favorites.removeWhere((m) => m.id == movie.id);
    } else {
      _favorites.add(movie);
    }
    await _save();
  }
}

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/movie.dart';

class MovieService {
  // Shared method for fetching movie lists from TMDB.
  Future<List<Movie>> _fetchMovies(String endpoint) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint'
      '?api_key=${ApiConfig.apiKey}'
      '&language=en-US',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final List<dynamic> results = data['results'] ?? [];

      return results
          .map((movieJson) => Movie.fromJson(movieJson as Map<String, dynamic>))
          .toList();
    }

    throw Exception('TMDB error ${response.statusCode}: ${response.body}');
  }

  Future<List<Movie>> fetchTrendingMovies() {
    return _fetchMovies('/trending/movie/day');
  }

  Future<List<Movie>> fetchPopularMovies() {
    return _fetchMovies('/movie/popular');
  }

  Future<List<Movie>> fetchPopularTvShows() {
    return _fetchMovies('/tv/popular');
  }

  Future<List<Movie>> searchMovies(String query) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/search/movie'
      '?api_key=${ApiConfig.apiKey}'
      '&language=en-US'
      '&query=${Uri.encodeComponent(query)}',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);

      final List<dynamic> results = data['results'] ?? [];

      return results
          .map((movieJson) => Movie.fromJson(movieJson as Map<String, dynamic>))
          .toList();
    }

    throw Exception('TMDB error ${response.statusCode}: ${response.body}');
  }
}

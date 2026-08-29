import '../models/movie.dart';
import 'tmdb_client.dart';

class MovieService {
  Future<List<Movie>> _fetchMovies(String endpoint) async {
    final data = await TmdbClient.getJson(endpoint);
    final List<dynamic> results = data['results'] ?? [];

    return results
        .map((movieJson) => Movie.fromJson(movieJson as Map<String, dynamic>))
        .toList();
  }

  Future<Movie> fetchMovieDetails(int movieId) async {
    final data = await TmdbClient.getJson('/movie/$movieId');
    return Movie.fromJson(data);
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
    final data = await TmdbClient.getJson(
      '/search/movie',
      queryParameters: {'query': query},
    );
    final List<dynamic> results = data['results'] ?? [];

    return results
        .map((movieJson) => Movie.fromJson(movieJson as Map<String, dynamic>))
        .toList();
  }
}

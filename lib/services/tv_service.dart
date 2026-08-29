import '../models/episode.dart';
import '../models/season.dart';
import '../models/tv_show.dart';
import 'tmdb_client.dart';

class TvService {
  Future<Map<String, dynamic>> _getJson(
    String endpoint, {
    Map<String, String> queryParameters = const {},
  }) {
    return TmdbClient.getJson(
      endpoint,
      queryParameters: queryParameters,
    );
  }

  Future<List<TvShow>> fetchTrendingTvShows() async {
    final data = await _getJson('/trending/tv/day');
    final results = data['results'] as List<dynamic>? ?? [];

    return results
        .map((item) => TvShow.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TvShow>> fetchPopularTvShows() async {
    final data = await _getJson('/tv/popular');
    final results = data['results'] as List<dynamic>? ?? [];

    return results
        .map((item) => TvShow.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TvShow>> fetchTopRatedTvShows() async {
    final data = await _getJson('/tv/top_rated');
    final results = data['results'] as List<dynamic>? ?? [];

    return results
        .map((item) => TvShow.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TvShow>> searchTvShows(String query) async {
    final data = await _getJson(
      '/search/tv',
      queryParameters: {'query': query},
    );
    final results = data['results'] as List<dynamic>? ?? [];

    return results
        .map((item) => TvShow.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TvShow> fetchTvShowDetails(int tvId) async {
    final data = await _getJson('/tv/$tvId');
    return TvShow.fromJson(data);
  }

  Future<List<Season>> fetchSeasons(int tvId) async {
    final data = await _getJson('/tv/$tvId');
    final results = data['seasons'] as List<dynamic>? ?? [];

    return results
        .map((item) => Season.fromJson(item as Map<String, dynamic>))
        .where((season) => season.seasonNumber > 0)
        .toList();
  }

  Future<List<Episode>> fetchEpisodes(int tvId, int seasonNumber) async {
    final data = await _getJson('/tv/$tvId/season/$seasonNumber');
    final results = data['episodes'] as List<dynamic>? ?? [];

    return results
        .map((item) => Episode.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

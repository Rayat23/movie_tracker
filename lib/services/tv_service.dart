import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/episode.dart';
import '../models/season.dart';
import '../models/tv_show.dart';

class TvService {
  Future<Map<String, dynamic>> _getJson(String endpoint) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}$endpoint'
      '?api_key=${ApiConfig.apiKey}'
      '&language=en-US',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('TMDB error ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
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

  Future<List<TvShow>> searchTvShows(String query) async {
    final encodedQuery = Uri.encodeComponent(query);
    final data = await _getJson('/search/tv&query=$encodedQuery');
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

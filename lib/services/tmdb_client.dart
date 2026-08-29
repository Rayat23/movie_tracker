import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Shared TMDB transport for both movies and TV.
///
/// Local development can keep using the API key from `api_config.dart`.
/// Production web builds should set `TMDB_PROXY_BASE_URL` so the browser talks
/// to the server-side proxy instead and the TMDB credential is never embedded
/// in the public Flutter JavaScript bundle.
class TmdbClient {
  TmdbClient._();

  static const String proxyBaseUrl =
      String.fromEnvironment('TMDB_PROXY_BASE_URL');

  static const Duration _timeout = Duration(seconds: 20);

  static bool get usesProxy => proxyBaseUrl.trim().isNotEmpty;

  static Future<Map<String, dynamic>> getJson(
    String endpoint, {
    Map<String, String> queryParameters = const {},
  }) async {
    final String baseUrl = usesProxy ? proxyBaseUrl.trim() : ApiConfig.baseUrl;
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedEndpoint = endpoint.startsWith('/') ? endpoint : '/$endpoint';

    final parameters = <String, String>{
      'language': 'en-US',
      ...queryParameters,
    };

    // Only local/direct development sends the TMDB key from the client.
    // Production web builds use the proxy, where the credential stays server-side.
    if (!usesProxy) {
      parameters['api_key'] = ApiConfig.apiKey;
    }

    final uri = Uri.parse('$normalizedBase$normalizedEndpoint').replace(
      queryParameters: parameters,
    );

    final response = await http.get(uri).timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'TMDB request failed (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('TMDB returned an unexpected response.');
    }

    return decoded;
  }
}

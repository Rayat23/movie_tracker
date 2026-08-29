// Local-development fallback only.
//
// Copy this file to api_config.dart and paste your real TMDB key when running
// directly from your own computer. api_config.dart is gitignored.
//
// Public web builds should NOT embed the TMDB key. They set
// TMDB_PROXY_BASE_URL and route requests through the server-side edge proxy.
class ApiConfig {
  static const String apiKey = 'PASTE_YOUR_TMDB_KEY_HERE';
  static const String baseUrl = 'https://api.themoviedb.org/3';
}

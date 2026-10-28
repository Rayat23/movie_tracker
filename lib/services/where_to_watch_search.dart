import 'package:url_launcher/url_launcher.dart';

/// Creates user-initiated Google Search links without using watch-provider APIs.
class WhereToWatchSearch {
  static Uri googleSearchUri({
    required String title,
    required bool isTv,
    String? year,
  }) {
    final name = title.trim();
    if (name.isEmpty) {
      throw ArgumentError.value(title, 'title', 'Cannot search an empty title');
    }

    final cleanedYear = year?.trim() ?? '';
    final includeYear = RegExp(r'^\d{4}$').hasMatch(cleanedYear);
    final query = [
      name,
      if (includeYear) cleanedYear,
      isTv ? 'TV series' : 'movie',
      'where to watch',
    ].join(' ');

    return Uri.https('www.google.com', '/search', {'q': query});
  }

  /// Opens search results in the browser; does not claim provider availability.
  static Future<bool> openGoogle({
    required String title,
    required bool isTv,
    String? year,
  }) {
    return launchUrl(
      googleSearchUri(title: title, isTv: isTv, year: year),
      mode: LaunchMode.externalApplication,
    );
  }
}

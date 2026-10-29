import 'package:flutter_test/flutter_test.dart';
import 'package:movie_tracker/services/where_to_watch_search.dart';

void main() {
  test('movie Google search uses title and release year', () {
    final uri = WhereToWatchSearch.googleSearchUri(
      title: ' Dune: Part Two ',
      year: '2024',
      isTv: false,
    );

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/search');
    expect(
      uri.queryParameters['q'],
      'Dune: Part Two 2024 movie where to watch',
    );
  });

  test('TV search distinguishes series and safely encodes unicode', () {
    final uri = WhereToWatchSearch.googleSearchUri(
      title: 'Pokémon & Friends',
      year: '2025',
      isTv: true,
    );
    expect(
      uri.queryParameters['q'],
      'Pokémon & Friends 2025 TV series where to watch',
    );
    expect(uri.toString(), contains('%26'));
  });

  test('invalid dates are not included in search query', () {
    final uri = WhereToWatchSearch.googleSearchUri(
      title: 'Example',
      year: '2023-01-01',
      isTv: false,
    );
    expect(uri.queryParameters['q'], 'Example movie where to watch');
  });

  test('empty titles are rejected instead of opening generic search', () {
    expect(
      () => WhereToWatchSearch.googleSearchUri(
        title: '  ',
        isTv: false,
      ),
      throwsArgumentError,
    );
  });
}

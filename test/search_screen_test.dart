import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_tracker/models/movie.dart';
import 'package:movie_tracker/models/tv_show.dart';
import 'package:movie_tracker/screens/search_screen.dart';
import 'package:movie_tracker/services/movie_service.dart';
import 'package:movie_tracker/services/tv_service.dart';

class _MovieSearch extends MovieService {
  final queries = <String>[];
  final requests = <Completer<List<Movie>>>[];

  @override
  Future<List<Movie>> searchMovies(String query) {
    queries.add(query);
    final request = Completer<List<Movie>>();
    requests.add(request);
    return request.future;
  }
}

class _TvSearch extends TvService {
  final queries = <String>[];
  final requests = <Completer<List<TvShow>>>[];

  @override
  Future<List<TvShow>> searchTvShows(String query) {
    queries.add(query);
    final request = Completer<List<TvShow>>();
    requests.add(request);
    return request.future;
  }
}

Movie _movie(int id, String title) => Movie.fromJson({
  'id': id,
  'title': title,
  'poster_path': '',
});

TvShow _show(int id, String name) => TvShow.fromJson({
  'id': id,
  'name': name,
  'poster_path': '',
});

Future<void> _open(
  WidgetTester tester,
  _MovieSearch movies,
  _TvSearch tv,
) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SearchScreen(movieService: movies, tvService: tv)),
  ),
);

Future<void> _search(WidgetTester tester, String query) async {
  await tester.enterText(find.byType(TextField), query);
  await tester.testTextInput.receiveAction(TextInputAction.search);
  await tester.pump();
}

void main() {
  late _MovieSearch movies;
  late _TvSearch tv;

  setUp(() {
    movies = _MovieSearch();
    tv = _TvSearch();
  });

  testWidgets('a slow older search cannot replace newer results', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, 'Older');
    await _search(tester, 'Latest');

    movies.requests[1].complete([_movie(2, 'Latest result')]);
    await tester.pump();
    expect(find.text('Latest result'), findsOneWidget);

    movies.requests[0].complete([_movie(1, 'Older result')]);
    await tester.pump();
    expect(find.text('Latest result'), findsOneWidget);
    expect(find.text('Older result'), findsNothing);
    expect(find.text('Results for “Latest”'), findsOneWidget);
  });

  testWidgets('clearing search ignores a pending response', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, 'Pending');
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pump();

    movies.requests.single.complete([_movie(1, 'Pending result')]);
    await tester.pump();
    expect(find.text('Find your next movie'), findsOneWidget);
    expect(find.text('Pending result'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('erasing the input invalidates a pending request', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, 'Pending');
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();

    movies.requests.single.complete([_movie(1, 'Pending result')]);
    await tester.pump();
    expect(find.text('Find your next movie'), findsOneWidget);
    expect(find.text('Pending result'), findsNothing);
  });

  testWidgets('switching to TV ignores the previous movie response', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, 'Shared title');
    await tester.tap(find.text('TV Series'));
    await tester.pump();
    expect(tv.queries, ['Shared title']);

    tv.requests.single.complete([_show(2, 'TV result')]);
    await tester.pump();
    movies.requests.single.complete([_movie(1, 'Movie result')]);
    await tester.pump();
    expect(find.text('TV result'), findsOneWidget);
    expect(find.text('Movie result'), findsNothing);
  });

  testWidgets('an old error cannot stop a newer pending search', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, 'Older');
    await _search(tester, 'Latest');

    movies.requests[0].completeError(StateError('Old request failed'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Search unavailable'), findsNothing);

    movies.requests[1].complete([_movie(2, 'Latest result')]);
    await tester.pump();
    expect(find.text('Latest result'), findsOneWidget);
  });

  testWidgets('an old category error cannot replace successful TV results', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, 'Shared title');
    await tester.tap(find.text('TV Series'));
    await tester.pump();

    tv.requests.single.complete([_show(2, 'TV result')]);
    await tester.pump();
    movies.requests.single.completeError(StateError('Movie request failed'));
    await tester.pump();
    expect(find.text('TV result'), findsOneWidget);
    expect(find.text('Search unavailable'), findsNothing);
  });

  testWidgets('retry submits the failed query again', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, 'Retry me');
    movies.requests.single.completeError(StateError('Offline'));
    await tester.pump();
    expect(find.text('Search unavailable'), findsOneWidget);

    await tester.ensureVisible(find.text('Retry search'));
    await tester.tap(find.text('Retry search'));
    await tester.pump();
    expect(movies.queries, ['Retry me', 'Retry me']);

    movies.requests.last.complete([_movie(3, 'Recovered result')]);
    await tester.pump();
    expect(find.text('Recovered result'), findsOneWidget);
    expect(find.text('Search unavailable'), findsNothing);
  });

  testWidgets('blank queries do not call either service', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, '   ');
    expect(movies.queries, isEmpty);
    expect(tv.queries, isEmpty);
    expect(find.text('Find your next movie'), findsOneWidget);
  });

  testWidgets('a response after leaving search does not update disposed state', (tester) async {
    await _open(tester, movies, tv);
    await _search(tester, 'Pending');
    await tester.pumpWidget(const SizedBox());
    movies.requests.single.complete([_movie(1, 'Pending result')]);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('search controls fit a narrow screen with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(body: SearchScreen(movieService: movies, tvService: tv)),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('TV Series'), findsOneWidget);
  });
}

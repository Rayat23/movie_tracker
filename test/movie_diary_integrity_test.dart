import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_tracker/models/movie.dart';
import 'package:movie_tracker/screens/diary_screen.dart';
import 'package:movie_tracker/services/favorites_service.dart';
import 'package:movie_tracker/services/local_change_service.dart';
import 'package:movie_tracker/services/profile_service.dart';
import 'package:movie_tracker/services/series_tracking_service.dart';

const movie = Movie(
  id: 77,
  title: 'Example Movie',
  posterPath: '',
  rating: 7,
  releaseDate: '2024-01-01',
  overview: '',
  runtimeMinutes: 100,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => LocalChangeService.instance.dispose());

  test('edits only selected duplicate rewatch and preserves unrelated fields',
      () async {
    final original = DateTime.utc(2026, 8, 1, 12);
    final shared = DateTime.utc(2026, 8, 2, 13);
    final next = DateTime.utc(2026, 7, 29, 14);
    final rewatchData = {
      '77': [shared.toIso8601String(), shared.toIso8601String()],
      'legacy_key': ['keep this'],
    };
    SharedPreferences.setMockInitialValues({
      'watched_movies': jsonEncode([movie.toJson()]),
      'watched_dates': jsonEncode({'77': original.toIso8601String()}),
      'movie_rewatch_dates_v1': jsonEncode(rewatchData),
    });
    final prefs = await SharedPreferences.getInstance();
    await ProfileService.instance.initialize();
    await FavoritesService.instance.loadAll();
    final profileId = ProfileService.instance.activeProfile.id;

    expect(await FavoritesService.instance.updateMovieWatchDate(
      movie, shared, next,
      isRewatch: true, sourceIndex: 1, expectedProfileId: profileId,
    ), isTrue);
    final rewatches = jsonDecode(
      prefs.getString('movie_rewatch_dates_v1')!,
    ) as Map<String, dynamic>;
    expect(rewatches['77'], [shared.toIso8601String(), next.toIso8601String()]);
    expect(rewatches['legacy_key'], ['keep this']);
    expect(
      (jsonDecode(prefs.getString('watched_dates')!) as Map)['77'],
      original.toIso8601String(),
    );
    expect(prefs.getBool('auto_sync_pending_v1'), isTrue);

    // The old source event no longer matches the persisted source index.
    final before = prefs.getString('movie_rewatch_dates_v1');
    expect(await FavoritesService.instance.updateMovieWatchDate(
      movie, shared, DateTime.utc(2026, 7, 28),
      isRewatch: true, sourceIndex: 1, expectedProfileId: profileId,
    ), isFalse);
    expect(prefs.getString('movie_rewatch_dates_v1'), before);
  });

  test('profile switch and mismatched stored identity reject stale edits',
      () async {
    final original = DateTime.utc(2026, 8, 1, 12);
    final stored = jsonEncode({'77': original.toIso8601String()});
    SharedPreferences.setMockInitialValues({
      'watched_movies': jsonEncode([movie.toJson()]),
      'watched_dates': stored,
    });
    final prefs = await SharedPreferences.getInstance();
    final profiles = ProfileService.instance;
    await profiles.initialize();
    await FavoritesService.instance.loadAll();
    final firstId = profiles.activeProfile.id;
    await profiles.createProfile('Other profile');
    final secondId = profiles.activeProfile.id;
    await prefs.setString('watched_dates', stored);
    await FavoritesService.instance.loadAll();

    final replacement = DateTime.utc(2026, 7, 1);
    expect(await FavoritesService.instance.updateMovieWatchDate(
      movie, original, replacement,
      isRewatch: false, sourceIndex: 0, expectedProfileId: firstId,
    ), isFalse);
    expect(prefs.getString('watched_dates'), stored);
    expect(prefs.getString('profile:$firstId:watched_dates'), stored);

    await prefs.setString('active_profile_id_v1', firstId);
    expect(await FavoritesService.instance.updateMovieWatchDate(
      movie, original, replacement,
      isRewatch: false, sourceIndex: 0, expectedProfileId: secondId,
    ), isFalse);
    expect(prefs.getString('watched_dates'), stored);
    expect(prefs.getBool('auto_sync_pending_v1'), isNot(true));
  });

  test('legacy invalid rewatch timestamps keep persisted source indices', () async {
    final original = DateTime.utc(2026, 8, 1, 12);
    final duplicate = DateTime.utc(2026, 8, 2, 13);
    final moved = DateTime.utc(2026, 7, 30, 9);
    final initial = {
      '77': ['not-a-date', duplicate.toIso8601String(),
        duplicate.toIso8601String()],
      'legacy_key': ['do not change'],
    };
    SharedPreferences.setMockInitialValues({
      'watched_movies': jsonEncode([movie.toJson()]),
      'watched_dates': jsonEncode({'77': original.toIso8601String()}),
      'movie_rewatch_dates_v1': jsonEncode(initial),
    });
    final prefs = await SharedPreferences.getInstance();
    await ProfileService.instance.initialize();
    await FavoritesService.instance.loadAll();
    final service = FavoritesService.instance;
    final profileId = ProfileService.instance.activeProfile.id;

    expect(service.getMovieRewatchDatesInStorageOrder(movie),
        [duplicate, duplicate]);
    expect(service.getMovieRewatchSourceIndicesInStorageOrder(movie), [1, 2]);

    // The second displayed rewatch is persisted at index 2, not index 1.
    expect(await service.updateMovieWatchDate(
      movie, duplicate, moved,
      isRewatch: true, sourceIndex: 2, expectedProfileId: profileId,
    ), isTrue);
    final actual = jsonDecode(prefs.getString('movie_rewatch_dates_v1')!)
        as Map<String, dynamic>;
    expect(actual['77'], ['not-a-date', duplicate.toIso8601String(),
      moved.toIso8601String()]);
    expect(actual['legacy_key'], ['do not change']);
    expect(service.getMovieRewatchSourceIndicesInStorageOrder(movie), [1, 2]);
    // Dirty-state persistence is separately asserted by the first test.
    // The LocalChangeService singleton retains its prefs reference between tests.

    // Replaying the stale edit must not change the persisted data.
    final before = prefs.getString('movie_rewatch_dates_v1');
    expect(await service.updateMovieWatchDate(
      movie, duplicate, DateTime.utc(2026, 7, 29),
      isRewatch: true, sourceIndex: 2, expectedProfileId: profileId,
    ), isFalse);
    expect(prefs.getString('movie_rewatch_dates_v1'), before);
  });

  testWidgets('diary picker edits persisted index after invalid legacy rewatch',
      (tester) async {
    final original = DateTime(2026, 8, 1, 12);
    final duplicate = DateTime(2026, 8, 2, 13);
    final storedRewatches = [
      'legacy-invalid',
      duplicate.toIso8601String(),
      duplicate.toIso8601String(),
    ];
    SharedPreferences.setMockInitialValues({
      'watched_movies': jsonEncode([movie.toJson()]),
      'watched_dates': jsonEncode({'77': original.toIso8601String()}),
      'movie_rewatch_dates_v1': jsonEncode({'77': storedRewatches}),
    });
    final prefs = await SharedPreferences.getInstance();
    await ProfileService.instance.initialize();
    await FavoritesService.instance.loadAll();
    await SeriesTrackingService.instance.loadAll();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: const DiaryScreen(),
    ));
    expect(find.text('Rewatch #3'), findsOneWidget);
    await tester.tap(find.text('Rewatch #3'));
    await tester.pumpAndSettle();
    expect(find.text('When did you watch it?'), findsOneWidget);
    await tester.tap(find.text('3').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Choose watch time'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final saved = jsonDecode(prefs.getString('movie_rewatch_dates_v1')!)
        as Map<String, dynamic>;
    final values = saved['77'] as List;
    expect(values, hasLength(3));
    expect(values[0], 'legacy-invalid');
    expect(values[1], duplicate.toIso8601String());
    expect(DateTime.parse(values[2] as String).day, 3);
    expect(find.text('Diary time updated.'), findsOneWidget);
    LocalChangeService.instance.dispose();
  });
}

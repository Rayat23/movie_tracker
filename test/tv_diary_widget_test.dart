import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movie_tracker/models/tv_watch_entry.dart';
import 'package:movie_tracker/screens/diary_screen.dart';
import 'package:movie_tracker/services/favorites_service.dart';
import 'package:movie_tracker/services/local_change_service.dart';
import 'package:movie_tracker/services/profile_service.dart';
import 'package:movie_tracker/services/series_tracking_service.dart';

TvWatchEntry episode(DateTime date) => TvWatchEntry(
  showId: 10,
  showName: 'Example Series',
  showPosterPath: '',
  seasonNumber: 1,
  episodeId: 101,
  episodeNumber: 1,
  episodeName: 'Pilot',
  episodeStillPath: '',
  runtimeMinutes: 42,
  watchedAt: date,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() => LocalChangeService.instance.dispose());

  testWidgets('diary UI edits a backdated rewatch without changing its original',
      (tester) async {
    final original = episode(DateTime(2026, 8, 1, 12));
    final rewatch = episode(DateTime(2026, 7, 1, 9));
    SharedPreferences.setMockInitialValues({
      'watched_tv_episodes_v1': jsonEncode([original.toJson()]),
      'rewatched_tv_episodes_v1': jsonEncode([rewatch.toJson()]),
    });
    final prefs = await SharedPreferences.getInstance();
    await ProfileService.instance.initialize();
    await FavoritesService.instance.loadAll();
    await SeriesTrackingService.instance.loadAll();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: const DiaryScreen(),
    ));
    expect(find.text('Rewatch #2'), findsOneWidget);
    expect(find.text('July 1, 2026'), findsOneWidget);

    await tester.tap(find.text('Rewatch #2'));
    await tester.pumpAndSettle();
    expect(find.text('When did you watch it?'), findsOneWidget);
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Choose watch time'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final watched = jsonDecode(prefs.getString('watched_tv_episodes_v1')!) as List;
    final rewatches = jsonDecode(prefs.getString('rewatched_tv_episodes_v1')!) as List;
    expect(watched, hasLength(1));
    expect(rewatches, hasLength(1));
    expect(watched.single['watched_at'], original.watchedAt.toIso8601String());
    expect(DateTime.parse(rewatches.single['watched_at'] as String).day, 2);
    expect(find.text('Rewatch #2'), findsOneWidget);
    expect(prefs.getBool('auto_sync_pending_v1'), isTrue);
  });

  testWidgets('diary UI rejects a picker opened before a profile switch',
      (tester) async {
    final original = episode(DateTime(2026, 8, 1, 12));
    final stored = jsonEncode([original.toJson()]);
    SharedPreferences.setMockInitialValues({
      'watched_tv_episodes_v1': stored,
    });
    final prefs = await SharedPreferences.getInstance();
    final profiles = ProfileService.instance;
    await profiles.initialize();
    final firstId = profiles.activeProfile.id;
    await FavoritesService.instance.loadAll();
    await SeriesTrackingService.instance.loadAll();

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData.dark(),
      home: const DiaryScreen(),
    ));
    await tester.tap(find.text('Example Series'));
    await tester.pumpAndSettle();
    expect(find.text('When did you watch it?'), findsOneWidget);

    await profiles.createProfile('Another');
    final secondId = profiles.activeProfile.id;
    expect(secondId, isNot(firstId));
    expect(prefs.getString('profile:$firstId:watched_tv_episodes_v1'), stored);
    // Simulate the same episode existing in the new profile too.
    await prefs.setString('watched_tv_episodes_v1', stored);

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('That diary entry changed before it could be updated.'),
        findsOneWidget);
    expect(prefs.getString('watched_tv_episodes_v1'), stored);
    expect(prefs.getString('profile:$firstId:watched_tv_episodes_v1'), stored);
    expect(prefs.getBool('auto_sync_pending_v1'), isNot(true));
  });
}

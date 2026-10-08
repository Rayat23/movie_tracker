import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movie_tracker/models/tv_watch_entry.dart';
import 'package:movie_tracker/services/local_change_service.dart';
import 'package:movie_tracker/services/series_tracking_service.dart';
import 'package:movie_tracker/services/tv_watch_timestamp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TV diary timestamp edits preserve watch history and sync state', () async {
    final original = TvWatchEntry(
      showId: 10,
      showName: 'Example Series',
      showPosterPath: '/poster.jpg',
      seasonNumber: 1,
      episodeId: 101,
      episodeNumber: 1,
      episodeName: 'Pilot',
      episodeStillPath: '/still.jpg',
      runtimeMinutes: 42,
      watchedAt: DateTime.utc(2026, 9, 1, 12),
    );
    final rewatch = TvWatchEntry(
      showId: 10,
      showName: 'Example Series',
      showPosterPath: '/poster.jpg',
      seasonNumber: 1,
      episodeId: 101,
      episodeNumber: 1,
      episodeName: 'Pilot',
      episodeStillPath: '/still.jpg',
      runtimeMinutes: 42,
      watchedAt: DateTime.utc(2026, 9, 3, 16),
    );
    final otherEpisode = TvWatchEntry(
      showId: 10,
      showName: 'Example Series',
      showPosterPath: '/poster.jpg',
      seasonNumber: 1,
      episodeId: 102,
      episodeNumber: 2,
      episodeName: 'Second Episode',
      episodeStillPath: '',
      runtimeMinutes: 44,
      watchedAt: DateTime.utc(2026, 9, 2, 12),
    );

    final originalWithExtra = {
      ...original.toJson(),
      'legacy_extra': 'keep this field',
    };
    final primaryJson = jsonEncode([
      originalWithExtra,
      otherEpisode.toJson(),
    ]);
    final rewatchJson = jsonEncode([rewatch.toJson()]);
    final anotherProfileJson = jsonEncode([otherEpisode.toJson()]);

    SharedPreferences.setMockInitialValues({
      'watched_tv_episodes_v1': primaryJson,
      'rewatched_tv_episodes_v1': rewatchJson,
      'profile:another:watched_tv_episodes_v1': anotherProfileJson,
    });
    addTearDown(LocalChangeService.instance.dispose);

    final prefs = await SharedPreferences.getInstance();
    final service = TvWatchTimestampService.instance;

    // Invalid edits must not mutate any persisted watch events.
    expect(
      await service.updateWatchDate(
        entry: original,
        replacement: DateTime.now().add(const Duration(days: 1)),
        isRewatch: false,
      ),
      isFalse,
    );
    expect(
      await service.updateWatchDate(
        entry: TvWatchEntry.fromJson({
          ...original.toJson(),
          'watched_at': DateTime.utc(2026, 8, 1).toIso8601String(),
        }),
        replacement: DateTime.utc(2026, 8, 2),
        isRewatch: false,
      ),
      isFalse,
    );
    expect(prefs.getString('watched_tv_episodes_v1'), primaryJson);
    expect(prefs.getString('rewatched_tv_episodes_v1'), rewatchJson);

    final editedPrimaryDate = DateTime.utc(2026, 8, 30, 19, 45);
    expect(
      await service.updateWatchDate(
        entry: original,
        replacement: editedPrimaryDate,
        isRewatch: false,
      ),
      isTrue,
    );

    final primary = (jsonDecode(prefs.getString('watched_tv_episodes_v1')!)
        as List<dynamic>);
    expect(primary, hasLength(2));
    expect(primary[0]['watched_at'], editedPrimaryDate.toIso8601String());
    expect(primary[0]['legacy_extra'], 'keep this field');
    expect(primary[1], otherEpisode.toJson());
    expect(prefs.getString('rewatched_tv_episodes_v1'), rewatchJson);
    expect(
      prefs.getString('profile:another:watched_tv_episodes_v1'),
      anotherProfileJson,
    );

    final editedRewatchDate = DateTime.utc(2026, 8, 31, 21, 15);
    expect(
      await service.updateWatchDate(
        entry: rewatch,
        replacement: editedRewatchDate,
        isRewatch: true,
      ),
      isTrue,
    );
    final rewatches = (jsonDecode(
      prefs.getString('rewatched_tv_episodes_v1')!,
    ) as List<dynamic>);
    expect(rewatches, hasLength(1));
    expect(rewatches.single['watched_at'], editedRewatchDate.toIso8601String());
    expect(
      prefs.getString('profile:another:watched_tv_episodes_v1'),
      anotherProfileJson,
    );

    // Existing cloud-sync tracking is marked dirty and in-memory TV
    // statistics reload from the edited records without losing events.
    expect(prefs.getBool('auto_sync_pending_v1'), isTrue);
    expect(LocalChangeService.instance.hasPendingChanges, isTrue);
    expect(SeriesTrackingService.instance.totalWatchedEpisodes, 2);
    expect(SeriesTrackingService.instance.totalTvRewatches, 1);
    expect(
      SeriesTrackingService.instance.watchedEpisodes
          .firstWhere((entry) => entry.episodeId == 101)
          .watchedAt
          .isAtSameMomentAs(editedPrimaryDate),
      isTrue,
    );
    expect(
      SeriesTrackingService.instance.rewatchEpisodes.single.watchedAt
          .isAtSameMomentAs(editedRewatchDate),
      isTrue,
    );
  });
}

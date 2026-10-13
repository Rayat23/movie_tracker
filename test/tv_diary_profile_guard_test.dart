import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movie_tracker/models/tv_watch_entry.dart';
import 'package:movie_tracker/services/profile_service.dart';
import 'package:movie_tracker/services/tv_watch_timestamp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TV diary rejects stale edits when the active profile changes', () async {
    final entry = TvWatchEntry(
      showId: 10,
      showName: 'Example Series',
      showPosterPath: '',
      seasonNumber: 1,
      episodeId: 101,
      episodeNumber: 1,
      episodeName: 'Pilot',
      episodeStillPath: '',
      runtimeMinutes: 42,
      watchedAt: DateTime.utc(2026, 9, 1, 12),
    );
    final original = jsonEncode([entry.toJson()]);
    SharedPreferences.setMockInitialValues({
      'watched_tv_episodes_v1': original,
    });
    final prefs = await SharedPreferences.getInstance();
    final profiles = ProfileService.instance;
    await profiles.initialize();
    final firstId = profiles.activeProfile.id;

    // Creating another profile snapshots the first and swaps the base keys.
    await profiles.createProfile('Another');
    final secondId = profiles.activeProfile.id;
    expect(secondId, isNot(firstId));
    expect(prefs.getString('profile:$firstId:watched_tv_episodes_v1'), original);

    // Even an identical episode record in the second profile must not be
    // edited by a date picker opened while the first profile was active.
    await prefs.setString('watched_tv_episodes_v1', original);
    final service = TvWatchTimestampService.instance;
    final replacement = DateTime.utc(2026, 8, 30, 19, 45);
    expect(
      await service.updateWatchDate(
        entry: entry,
        replacement: replacement,
        isRewatch: false,
        sourceIndex: 0,
        expectedProfileId: firstId,
      ),
      isFalse,
    );
    expect(prefs.getString('watched_tv_episodes_v1'), original);
    expect(prefs.getString('profile:$firstId:watched_tv_episodes_v1'), original);
    expect(prefs.getBool('auto_sync_pending_v1'), isNot(true));

    // A mismatch between persisted and in-memory active IDs also rejects
    // the write while a profile switch is in progress.
    await prefs.setString('active_profile_id_v1', firstId);
    expect(
      await service.updateWatchDate(
        entry: entry,
        replacement: replacement,
        isRewatch: false,
        sourceIndex: 0,
        expectedProfileId: secondId,
      ),
      isFalse,
    );
    expect(prefs.getString('watched_tv_episodes_v1'), original);

    // Once both active profile identities agree, the edit is permitted.
    await prefs.setString('active_profile_id_v1', secondId);
    expect(
      await service.updateWatchDate(
        entry: entry,
        replacement: replacement,
        isRewatch: false,
        sourceIndex: 0,
        expectedProfileId: secondId,
      ),
      isTrue,
    );
    final edited = jsonDecode(prefs.getString('watched_tv_episodes_v1')!) as List;
    expect(edited, hasLength(1));
    expect(edited.single['watched_at'], replacement.toIso8601String());
    expect(prefs.getString('profile:$firstId:watched_tv_episodes_v1'), original);
  });
}

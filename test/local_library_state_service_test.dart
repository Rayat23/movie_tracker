import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movie_tracker/services/local_library_state_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('untouched generated profile is safe for clean-device restore', () async {
    SharedPreferences.setMockInitialValues({
      'app_profiles_v1': jsonEncode([
        {
          'id': 'local-default',
          'name': 'My Profile',
          'avatar_index': 0,
          'created_at': '2026-09-05T00:00:00.000Z',
        },
      ]),
      'active_profile_id_v1': 'local-default',
      'favorite_movies': '[]',
      'watchlist_movies': '[]',
    });

    expect(
      await LocalLibraryStateService.instance.hasMeaningfulState(),
      isFalse,
    );
  });

  test('tracking data makes the local library meaningful', () async {
    SharedPreferences.setMockInitialValues({
      'app_profiles_v1': jsonEncode([
        {
          'id': 'local-default',
          'name': 'My Profile',
          'avatar_index': 0,
          'created_at': '2026-09-05T00:00:00.000Z',
        },
      ]),
      'active_profile_id_v1': 'local-default',
      'favorite_movies': '[123]',
    });

    expect(
      await LocalLibraryStateService.instance.hasMeaningfulState(),
      isTrue,
    );
  });

  test('profile customization makes the local library meaningful', () async {
    SharedPreferences.setMockInitialValues({
      'app_profiles_v1': jsonEncode([
        {
          'id': 'custom',
          'name': 'Ray',
          'avatar_index': 0,
          'created_at': '2026-09-05T00:00:00.000Z',
        },
      ]),
      'active_profile_id_v1': 'custom',
    });

    expect(
      await LocalLibraryStateService.instance.hasMeaningfulState(),
      isTrue,
    );
  });
}

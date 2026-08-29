import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movie_tracker/services/local_change_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tracks pending changes and account-scoped cloud baselines', () async {
    SharedPreferences.setMockInitialValues({});

    final service = LocalChangeService.instance;
    await service.initialize();

    expect(service.hasPendingChanges, isFalse);

    await service.markDirty();
    expect(service.hasPendingChanges, isTrue);
    expect(service.lastLocalChange, isNotNull);

    final revision = DateTime.utc(2026, 8, 29, 3, 45);
    await service.markSynced(revision, userId: 'account-a');

    expect(service.hasPendingChanges, isFalse);
    expect(service.cloudBaselineForUser('account-a'), revision);
    expect(service.cloudBaselineForUser('account-b'), isNull);

    service.dispose();
  });
}

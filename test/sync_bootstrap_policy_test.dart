import 'package:flutter_test/flutter_test.dart';

import 'package:movie_tracker/services/sync_bootstrap_policy.dart';

void main() {
  group('SyncBootstrapPolicy', () {
    test('restores cloud automatically on a clean local device', () {
      final action = SyncBootstrapPolicy.decide(
        cloudExists: true,
        hasPendingLocalChanges: false,
        hasMeaningfulLocalState: false,
        hasSharedBaseline: false,
        currentStateMatchesBaseline: false,
        cloudIsNewerThanBaseline: false,
      );

      expect(action, CloudBootstrapAction.restoreCloud);
    });

    test('protects meaningful local data without a shared baseline', () {
      final action = SyncBootstrapPolicy.decide(
        cloudExists: true,
        hasPendingLocalChanges: false,
        hasMeaningfulLocalState: true,
        hasSharedBaseline: false,
        currentStateMatchesBaseline: false,
        cloudIsNewerThanBaseline: false,
      );

      expect(action, CloudBootstrapAction.conflict);
    });

    test('conflicts when local state changed after the confirmed baseline', () {
      final action = SyncBootstrapPolicy.decide(
        cloudExists: true,
        hasPendingLocalChanges: false,
        hasMeaningfulLocalState: true,
        hasSharedBaseline: true,
        currentStateMatchesBaseline: false,
        cloudIsNewerThanBaseline: true,
      );

      expect(action, CloudBootstrapAction.conflict);
    });

    test('pulls newer cloud data when local state still matches baseline', () {
      final action = SyncBootstrapPolicy.decide(
        cloudExists: true,
        hasPendingLocalChanges: false,
        hasMeaningfulLocalState: true,
        hasSharedBaseline: true,
        currentStateMatchesBaseline: true,
        cloudIsNewerThanBaseline: true,
      );

      expect(action, CloudBootstrapAction.restoreCloud);
    });

    test('keeps local state when cloud has not moved past baseline', () {
      final action = SyncBootstrapPolicy.decide(
        cloudExists: true,
        hasPendingLocalChanges: false,
        hasMeaningfulLocalState: true,
        hasSharedBaseline: true,
        currentStateMatchesBaseline: true,
        cloudIsNewerThanBaseline: false,
      );

      expect(action, CloudBootstrapAction.keepLocal);
    });

    test('empty tracking JSON is not meaningful local library data', () {
      expect(SyncBootstrapPolicy.isMeaningfulTrackingValue(null), isFalse);
      expect(SyncBootstrapPolicy.isMeaningfulTrackingValue('[]'), isFalse);
      expect(SyncBootstrapPolicy.isMeaningfulTrackingValue('{}'), isFalse);
      expect(
        SyncBootstrapPolicy.isMeaningfulTrackingValue('[123]'),
        isTrue,
      );
      expect(
        SyncBootstrapPolicy.isMeaningfulTrackingValue('{"123":5}'),
        isTrue,
      );
      expect(
        SyncBootstrapPolicy.isMeaningfulTrackingValue('legacy-value'),
        isTrue,
      );
    });
  });
}

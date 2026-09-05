import 'dart:async';

import 'account_service.dart';
import 'cloud_sync_service.dart';
import 'local_change_service.dart';
import 'profile_service.dart';
import 'sync_bootstrap_policy.dart';

class AutoSyncService {
  AutoSyncService._();

  static final AutoSyncService instance = AutoSyncService._();

  static const Duration _retryInterval = Duration(minutes: 1);
  static const Duration _clockTolerance = Duration(seconds: 2);

  final AccountService _accounts = AccountService.instance;
  final CloudSyncService _cloud = CloudSyncService.instance;
  final LocalChangeService _changes = LocalChangeService.instance;
  final ProfileService _profiles = ProfileService.instance;

  Timer? _retryTimer;
  StreamSubscription<dynamic>? _authSubscription;
  bool _syncing = false;
  bool _bootstrapping = false;
  bool _initialized = false;
  bool _conflictDetected = false;
  String? _lastError;
  DateTime? _lastSuccessfulSync;

  bool get isSyncing => _syncing || _bootstrapping;
  bool get hasPendingChanges => _changes.hasPendingChanges;
  bool get conflictDetected => _conflictDetected;
  String? get lastError => _lastError;
  DateTime? get lastSuccessfulSync => _lastSuccessfulSync;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _changes.initialize();
    _changes.registerSyncHandler(syncIfNeeded);

    if (_accounts.isAvailable) {
      _authSubscription = _accounts.authStateChanges().listen((user) {
        if (user == null) {
          _lastError = null;
          _conflictDetected = false;
          return;
        }
        unawaited(_handleSignedIn());
      });
    }

    _retryTimer = Timer.periodic(_retryInterval, (_) {
      if (_changes.hasPendingChanges) {
        unawaited(syncIfNeeded());
      }
    });

    if (_accounts.isSignedIn) {
      await _handleSignedIn();
    }
  }

  Future<void> _handleSignedIn() async {
    final user = _accounts.currentUser;
    if (user == null || _bootstrapping) return;

    _bootstrapping = true;
    _lastError = null;

    try {
      if (_changes.hasPendingChanges) {
        // Existing unsynced local edits are handled by the normal push path,
        // which already checks cloud revisions before uploading.
        _bootstrapping = false;
        await syncIfNeeded();
        return;
      }

      final cloudRevision = await _cloud.lastCloudUpdate();
      if (cloudRevision == null) {
        _conflictDetected = false;
        return;
      }

      final baseline = _changes.cloudBaselineForUser(user.uid);
      final hasMeaningfulLocalState =
          await _profiles.hasMeaningfulLocalState();
      final currentMatchesBaseline =
          _changes.currentStateMatchesBaselineForUser(user.uid);
      final cloudIsNewer = _isNewerThanBaseline(cloudRevision, baseline);

      final action = SyncBootstrapPolicy.decide(
        cloudExists: true,
        hasPendingLocalChanges: false,
        hasMeaningfulLocalState: hasMeaningfulLocalState,
        hasSharedBaseline: baseline != null,
        currentStateMatchesBaseline: currentMatchesBaseline,
        cloudIsNewerThanBaseline: cloudIsNewer,
      );

      switch (action) {
        case CloudBootstrapAction.restoreCloud:
          final restored = await _cloud.downloadCloudProfiles();
          if (!restored) {
            _conflictDetected = true;
            _lastError =
                'Cloud backup metadata exists, but no usable profile bundle was found. Automatic restore paused to protect local data.';
            return;
          }

          final confirmedRevision =
              await _cloud.lastCloudUpdate() ?? cloudRevision;
          await _changes.markSynced(
            confirmedRevision,
            userId: user.uid,
          );
          _lastSuccessfulSync = confirmedRevision;
          _conflictDetected = false;
          _lastError = null;
          return;

        case CloudBootstrapAction.conflict:
          _conflictDetected = true;
          if (baseline == null && hasMeaningfulLocalState) {
            _lastError =
                'This device has local profile/library data and this account also has cloud data, but there is no confirmed shared sync baseline. Automatic restore paused to avoid overwriting either side.';
          } else if (!currentMatchesBaseline && hasMeaningfulLocalState) {
            _lastError =
                'Local data no longer matches the last confirmed cloud baseline. Automatic restore paused to avoid overwriting local changes.';
          } else {
            _lastError =
                'Local and cloud data both contain changes that cannot be merged safely automatically. Sync is paused until you choose which copy to keep.';
          }
          return;

        case CloudBootstrapAction.keepLocal:
          _conflictDetected = false;
          _lastError = null;
          _lastSuccessfulSync = baseline ?? cloudRevision;
          return;
      }
    } catch (error) {
      // Network/bootstrap lookup failures never block local use. The next sign
      // in, retry, or app launch can try again without altering local data.
      _lastError = _cloud.friendlyError(error);
    } finally {
      _bootstrapping = false;
    }
  }

  Future<void> queueCurrentState() async {
    await _changes.markDirty();
  }

  Future<void> syncIfNeeded() async {
    if (!_initialized) await initialize();

    final user = _accounts.currentUser;
    if (_syncing ||
        _bootstrapping ||
        !_changes.hasPendingChanges ||
        user == null) {
      return;
    }
    if (_conflictDetected) return;

    _syncing = true;
    _lastError = null;

    try {
      final cloudRevision = await _cloud.lastCloudUpdate();
      final baseline = _changes.cloudBaselineForUser(user.uid);

      if (_isNewerThanBaseline(cloudRevision, baseline)) {
        _conflictDetected = true;
        _lastError =
            'A newer cloud backup exists from another session/device. Automatic sync paused to avoid overwriting data.';
        return;
      }

      if (cloudRevision != null && baseline == null) {
        _conflictDetected = true;
        _lastError =
            'Cloud data already exists but this device has unsynced local changes and no shared baseline. Automatic sync paused to avoid data loss.';
        return;
      }

      await _cloud.uploadAllProfiles();
      final confirmedRevision =
          await _cloud.lastCloudUpdate() ?? DateTime.now().toUtc();
      await _changes.markSynced(
        confirmedRevision,
        userId: user.uid,
      );

      _lastSuccessfulSync = confirmedRevision;
      _conflictDetected = false;
      _lastError = null;
    } catch (error) {
      // Keep the persistent dirty flag. The timer, the next local edit, or the
      // next sign-in will retry automatically when connectivity returns.
      _lastError = _cloud.friendlyError(error);
    } finally {
      _syncing = false;
    }
  }

  Future<void> confirmManualBackup(DateTime? cloudRevision) async {
    final user = _accounts.currentUser;
    if (user == null) return;

    final revision = cloudRevision ?? DateTime.now().toUtc();
    await _changes.markSynced(
      revision,
      userId: user.uid,
    );
    _lastSuccessfulSync = revision;
    _conflictDetected = false;
    _lastError = null;
  }

  Future<void> confirmCloudRestore(DateTime? cloudRevision) async {
    final user = _accounts.currentUser;
    if (user == null) return;

    final revision = cloudRevision ?? DateTime.now().toUtc();
    await _changes.markSynced(
      revision,
      userId: user.uid,
    );
    _lastSuccessfulSync = revision;
    _conflictDetected = false;
    _lastError = null;
  }

  void retryNow() {
    _conflictDetected = false;
    _changes.requestRetry();
    if (!_changes.hasPendingChanges && _accounts.isSignedIn) {
      unawaited(_handleSignedIn());
    }
  }

  bool _isNewerThanBaseline(DateTime? cloudRevision, DateTime? baseline) {
    if (cloudRevision == null || baseline == null) return false;
    return cloudRevision.toUtc().isAfter(
          baseline.toUtc().add(_clockTolerance),
        );
  }

  void dispose() {
    _retryTimer?.cancel();
    _authSubscription?.cancel();
  }
}

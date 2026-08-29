import 'dart:async';

import 'account_service.dart';
import 'cloud_sync_service.dart';
import 'local_change_service.dart';

class AutoSyncService {
  AutoSyncService._();

  static final AutoSyncService instance = AutoSyncService._();

  static const Duration _retryInterval = Duration(minutes: 1);
  static const Duration _clockTolerance = Duration(seconds: 2);

  final AccountService _accounts = AccountService.instance;
  final CloudSyncService _cloud = CloudSyncService.instance;
  final LocalChangeService _changes = LocalChangeService.instance;

  Timer? _retryTimer;
  StreamSubscription<dynamic>? _authSubscription;
  bool _syncing = false;
  bool _initialized = false;
  bool _conflictDetected = false;
  String? _lastError;
  DateTime? _lastSuccessfulSync;

  bool get isSyncing => _syncing;
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
    if (_changes.hasPendingChanges) {
      await syncIfNeeded();
      return;
    }

    // When there are no unsynced local edits, remember the current cloud
    // revision as the safe baseline for future conflict checks. This does not
    // replace local data or silently restore anything.
    try {
      final cloudRevision = await _cloud.lastCloudUpdate();
      if (cloudRevision != null) {
        await _changes.adoptCloudBaseline(cloudRevision);
        _lastSuccessfulSync = cloudRevision;
      }
    } catch (_) {
      // A baseline lookup is best-effort. Local tracking must remain usable
      // even when the network is unavailable.
    }
  }

  Future<void> syncIfNeeded() async {
    if (!_initialized) await initialize();
    if (_syncing || !_changes.hasPendingChanges || !_accounts.isSignedIn) {
      return;
    }
    if (_conflictDetected) return;

    _syncing = true;
    _lastError = null;

    try {
      final cloudRevision = await _cloud.lastCloudUpdate();
      final baseline = _changes.cloudBaseline;

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
      await _changes.markSynced(confirmedRevision);

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
    final revision = cloudRevision ?? DateTime.now().toUtc();
    await _changes.markSynced(revision);
    _lastSuccessfulSync = revision;
    _conflictDetected = false;
    _lastError = null;
  }

  Future<void> confirmCloudRestore(DateTime? cloudRevision) async {
    final revision = cloudRevision ?? DateTime.now().toUtc();
    await _changes.markSynced(revision);
    _lastSuccessfulSync = revision;
    _conflictDetected = false;
    _lastError = null;
  }

  void retryNow() {
    _conflictDetected = false;
    _changes.requestRetry();
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

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class LocalChangeService {
  LocalChangeService._();

  static final LocalChangeService instance = LocalChangeService._();

  static const String _pendingKey = 'auto_sync_pending_v1';
  static const String _lastLocalChangeKey = 'auto_sync_last_local_change_v1';
  static const String _cloudBaselineKey = 'auto_sync_cloud_baseline_v1';

  SharedPreferences? _prefs;
  Timer? _debounceTimer;
  Future<void> Function()? _syncHandler;

  bool _hasPendingChanges = false;
  DateTime? _lastLocalChange;
  DateTime? _cloudBaseline;

  bool get hasPendingChanges => _hasPendingChanges;
  DateTime? get lastLocalChange => _lastLocalChange;
  DateTime? get cloudBaseline => _cloudBaseline;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs!;

    _hasPendingChanges = prefs.getBool(_pendingKey) ?? false;
    _lastLocalChange = DateTime.tryParse(
      prefs.getString(_lastLocalChangeKey) ?? '',
    );
    _cloudBaseline = DateTime.tryParse(
      prefs.getString(_cloudBaselineKey) ?? '',
    );
  }

  void registerSyncHandler(Future<void> Function() handler) {
    _syncHandler = handler;
    if (_hasPendingChanges) {
      _scheduleSync(const Duration(seconds: 1));
    }
  }

  Future<void> markDirty() async {
    await initialize();

    final now = DateTime.now().toUtc();
    _hasPendingChanges = true;
    _lastLocalChange = now;

    await _prefs!.setBool(_pendingKey, true);
    await _prefs!.setString(_lastLocalChangeKey, now.toIso8601String());

    _scheduleSync(const Duration(seconds: 2));
  }

  Future<void> markSynced(DateTime cloudRevision) async {
    await initialize();

    _hasPendingChanges = false;
    _cloudBaseline = cloudRevision.toUtc();

    await _prefs!.setBool(_pendingKey, false);
    await _prefs!.setString(
      _cloudBaselineKey,
      _cloudBaseline!.toIso8601String(),
    );
  }

  Future<void> adoptCloudBaseline(DateTime cloudRevision) async {
    await initialize();

    _cloudBaseline = cloudRevision.toUtc();
    await _prefs!.setString(
      _cloudBaselineKey,
      _cloudBaseline!.toIso8601String(),
    );
  }

  void requestRetry() {
    if (!_hasPendingChanges) return;
    _scheduleSync(Duration.zero);
  }

  void _scheduleSync(Duration delay) {
    final handler = _syncHandler;
    if (handler == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      unawaited(handler());
    });
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalChangeService {
  LocalChangeService._();

  static final LocalChangeService instance = LocalChangeService._();

  static const String _pendingKey = 'auto_sync_pending_v1';
  static const String _lastLocalChangeKey = 'auto_sync_last_local_change_v1';
  static const String _cloudBaselineKey = 'auto_sync_cloud_baseline_v1';
  static const String _cloudBaselineUserKey = 'auto_sync_cloud_baseline_user_v1';
  static const String _observedStateKey = 'auto_sync_observed_state_v1';

  static const Set<String> _trackedBaseKeys = {
    'app_profiles_v1',
    'active_profile_id_v1',
    'favorite_movies',
    'watchlist_movies',
    'watched_movies',
    'movie_ratings',
    'watched_dates',
    'movie_rewatch_dates_v1',
    'watched_tv_episodes_v1',
    'rewatched_tv_episodes_v1',
    'favorite_tv_shows_v1',
    'watchlist_tv_shows_v1',
    'tv_show_ratings_v1',
    'tv_season_ratings_v1',
    'tv_episode_ratings_v1',
    'tv_show_episode_totals_v1',
    'tv_season_episode_totals_v1',
  };

  SharedPreferences? _prefs;
  Timer? _debounceTimer;
  Timer? _stateMonitorTimer;
  Future<void> Function()? _syncHandler;

  bool _hasPendingChanges = false;
  DateTime? _lastLocalChange;
  DateTime? _cloudBaseline;
  String? _cloudBaselineUserId;
  String? _lastObservedState;
  bool _initialized = false;

  bool get hasPendingChanges => _hasPendingChanges;
  DateTime? get lastLocalChange => _lastLocalChange;
  DateTime? get cloudBaseline => _cloudBaseline;
  String? get cloudBaselineUserId => _cloudBaselineUserId;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _prefs = await SharedPreferences.getInstance();
    final prefs = _prefs!;

    _hasPendingChanges = prefs.getBool(_pendingKey) ?? false;
    _lastLocalChange = DateTime.tryParse(
      prefs.getString(_lastLocalChangeKey) ?? '',
    );
    _cloudBaseline = DateTime.tryParse(
      prefs.getString(_cloudBaselineKey) ?? '',
    );
    _cloudBaselineUserId = prefs.getString(_cloudBaselineUserKey);

    final currentState = _calculateTrackedState(prefs);
    final storedState = prefs.getString(_observedStateKey);
    _lastObservedState = currentState;

    if (storedState == null) {
      await prefs.setString(_observedStateKey, currentState);
    } else if (storedState != currentState) {
      await _setDirty(DateTime.now().toUtc(), scheduleSync: false);
      await prefs.setString(_observedStateKey, currentState);
    }

    _stateMonitorTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      unawaited(_detectTrackedStateChange());
    });
  }

  void registerSyncHandler(Future<void> Function() handler) {
    _syncHandler = handler;
    if (_hasPendingChanges) {
      _scheduleSync(const Duration(seconds: 1));
    }
  }

  Future<void> markDirty() async {
    await initialize();
    await _setDirty(DateTime.now().toUtc());
    await _recordCurrentTrackedState();
  }

  Future<void> markSynced(
    DateTime cloudRevision, {
    required String userId,
  }) async {
    await initialize();

    _hasPendingChanges = false;
    _cloudBaseline = cloudRevision.toUtc();
    _cloudBaselineUserId = userId;

    await _prefs!.setBool(_pendingKey, false);
    await _prefs!.setString(
      _cloudBaselineKey,
      _cloudBaseline!.toIso8601String(),
    );
    await _prefs!.setString(_cloudBaselineUserKey, userId);
    await _recordCurrentTrackedState();
  }

  Future<void> adoptCloudBaseline(
    DateTime cloudRevision, {
    required String userId,
  }) async {
    await initialize();

    _cloudBaseline = cloudRevision.toUtc();
    _cloudBaselineUserId = userId;
    await _prefs!.setString(
      _cloudBaselineKey,
      _cloudBaseline!.toIso8601String(),
    );
    await _prefs!.setString(_cloudBaselineUserKey, userId);
    await _recordCurrentTrackedState();
  }

  DateTime? cloudBaselineForUser(String userId) {
    return _cloudBaselineUserId == userId ? _cloudBaseline : null;
  }

  Future<void> acceptCurrentStateWithoutUpload() async {
    await initialize();
    await _recordCurrentTrackedState();
  }

  void requestRetry() {
    if (!_hasPendingChanges) return;
    _scheduleSync(Duration.zero);
  }

  Future<void> _detectTrackedStateChange() async {
    final prefs = _prefs;
    if (prefs == null) return;

    final currentState = _calculateTrackedState(prefs);
    if (currentState == _lastObservedState) return;

    _lastObservedState = currentState;
    await prefs.setString(_observedStateKey, currentState);
    await _setDirty(DateTime.now().toUtc());
  }

  Future<void> _setDirty(
    DateTime changedAt, {
    bool scheduleSync = true,
  }) async {
    _hasPendingChanges = true;
    _lastLocalChange = changedAt;

    await _prefs!.setBool(_pendingKey, true);
    await _prefs!.setString(
      _lastLocalChangeKey,
      changedAt.toIso8601String(),
    );

    if (scheduleSync) {
      _scheduleSync(const Duration(seconds: 2));
    }
  }

  Future<void> _recordCurrentTrackedState() async {
    final prefs = _prefs!;
    final state = _calculateTrackedState(prefs);
    _lastObservedState = state;
    await prefs.setString(_observedStateKey, state);
  }

  String _calculateTrackedState(SharedPreferences prefs) {
    final keys = prefs
        .getKeys()
        .where(
          (key) => _trackedBaseKeys.contains(key) || key.startsWith('profile:'),
        )
        .toList()
      ..sort();

    final buffer = StringBuffer();
    for (final key in keys) {
      final value = prefs.get(key);
      buffer
        ..write(key)
        ..write('=')
        ..write(value is String ? value : jsonEncode(value))
        ..write('\n');
    }

    return _fnv1a(buffer.toString());
  }

  String _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  void _scheduleSync(Duration delay) {
    final handler = _syncHandler;
    if (handler == null) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      unawaited(handler());
    });
  }

  void dispose() {
    _debounceTimer?.cancel();
    _stateMonitorTimer?.cancel();
  }
}

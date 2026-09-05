import 'dart:convert';

enum CloudBootstrapAction {
  keepLocal,
  restoreCloud,
  conflict,
}

class SyncBootstrapPolicy {
  const SyncBootstrapPolicy._();

  /// Chooses the safest action when a signed-in session discovers cloud data.
  ///
  /// A clean local device can restore automatically. Meaningful local state is
  /// only replaced when it is still byte-for-byte at a previously confirmed
  /// cloud baseline and the cloud has moved forward since that baseline.
  static CloudBootstrapAction decide({
    required bool cloudExists,
    required bool hasPendingLocalChanges,
    required bool hasMeaningfulLocalState,
    required bool hasSharedBaseline,
    required bool currentStateMatchesBaseline,
    required bool cloudIsNewerThanBaseline,
  }) {
    if (!cloudExists) return CloudBootstrapAction.keepLocal;

    if (hasPendingLocalChanges) {
      return CloudBootstrapAction.conflict;
    }

    // The generated, untouched "My Profile" shell on a new browser is safe to
    // replace with the authenticated account's cloud bundle.
    if (!hasMeaningfulLocalState) {
      return CloudBootstrapAction.restoreCloud;
    }

    // Existing local data without a proven shared ancestor must never be
    // silently replaced.
    if (!hasSharedBaseline || !currentStateMatchesBaseline) {
      return CloudBootstrapAction.conflict;
    }

    // If this device has not changed since its confirmed baseline and another
    // device advanced the cloud, pulling the cloud state is safe.
    if (cloudIsNewerThanBaseline) {
      return CloudBootstrapAction.restoreCloud;
    }

    return CloudBootstrapAction.keepLocal;
  }

  /// Tracking values are JSON strings in SharedPreferences. Empty arrays/maps
  /// are bookkeeping, not meaningful user library state.
  static bool isMeaningfulTrackingValue(String? raw) {
    if (raw == null) return false;
    final value = raw.trim();
    if (value.isEmpty) return false;

    try {
      final decoded = jsonDecode(value);
      if (decoded == null) return false;
      if (decoded is List) return decoded.isNotEmpty;
      if (decoded is Map) return decoded.isNotEmpty;
      if (decoded is String) return decoded.trim().isNotEmpty;
      if (decoded is num) return decoded != 0;
      if (decoded is bool) return decoded;
      return true;
    } catch (_) {
      // Unknown legacy values are treated as meaningful so automation errs on
      // the side of preserving data instead of replacing it.
      return true;
    }
  }
}

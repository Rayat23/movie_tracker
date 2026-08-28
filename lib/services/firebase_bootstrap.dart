import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase configuration is supplied at run/build time with --dart-define.
///
/// The app still runs in local-only mode when these values are not present,
/// which keeps development and CI builds safe and credential-free.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const String storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String measurementId =
      String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  static bool _initialized = false;

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (!isConfigured || _initialized) return;

    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: authDomain.isEmpty ? null : authDomain,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
        measurementId: measurementId.isEmpty ? null : measurementId,
      ),
    );

    // Firestore's normal WebChannel transport can be buffered indefinitely by
    // some local proxies, antivirus/network filters, VPNs, and browser setups.
    // Authentication can still work in that situation while Firestore reads and
    // writes appear to hang. Force long polling on web to use a more compatible
    // transport. Firestore settings must be set before the first Firestore call.
    if (kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        webExperimentalForceLongPolling: true,
      );
    }

    _initialized = true;
  }
}

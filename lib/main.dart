import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/auto_sync_service.dart';
import 'services/favorites_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/profile_service.dart';
import 'services/series_tracking_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is optional during development/CI. When --dart-define Firebase
  // values are supplied, account authentication and Firestore sync turn on.
  await FirebaseBootstrap.initialize();

  await ProfileService.instance.initialize();

  await Future.wait([
    FavoritesService.instance.loadAll(),
    SeriesTrackingService.instance.loadAll(),
  ]);

  // Automatic sync is offline-first: local writes never wait for the network.
  // Pending changes are persisted and retried whenever connectivity returns.
  await AutoSyncService.instance.initialize();

  runApp(const MovieTrackerApp());
}

class MovieTrackerApp extends StatelessWidget {
  const MovieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Tracker',
      theme: AppTheme.dark(),
      home: const HomeScreen(),
    );
  }
}

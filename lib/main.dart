import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/favorites_service.dart';
import 'services/profile_service.dart';
import 'services/series_tracking_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ProfileService.instance.initialize();

  await Future.wait([
    FavoritesService.instance.loadAll(),
    SeriesTrackingService.instance.loadAll(),
  ]);

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

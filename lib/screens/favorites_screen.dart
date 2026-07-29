import 'package:flutter/material.dart';

import '../services/favorites_service.dart';
import '../widgets/movie_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService favorites = FavoritesService.instance;

  @override
  Widget build(BuildContext context) {
    final favMovies = favorites.favorites;

    if (favMovies.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No favorites yet",
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Tap the heart on any movie to save it here.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: favMovies.length,
        itemBuilder: (context, index) {
          return MovieCard(movie: favMovies[index]);
        },
      ),
    );
  }
}

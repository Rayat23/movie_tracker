import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/favorites_service.dart';

class DetailsScreen extends StatefulWidget {
  final Movie movie;

  const DetailsScreen({super.key, required this.movie});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final FavoritesService favorites = FavoritesService.instance;

  @override
  Widget build(BuildContext context) {
    final movie = widget.movie;
    final isFav = favorites.isFavorite(movie);

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
        actions: [
          IconButton(
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.white,
            ),
            onPressed: () {
              setState(() {
                favorites.toggle(movie);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 1),
                  content: Text(
                    favorites.isFavorite(movie)
                        ? "Added to Favorites"
                        : "Removed from Favorites",
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 400,
              child: movie.posterPath.isNotEmpty
                  ? Image.network(
                      movie.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Icon(Icons.movie, size: 80),
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[900],
                      child: const Center(child: Icon(Icons.movie, size: 80)),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movie.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.star, size: 20, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        movie.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      if (movie.releaseDate.isNotEmpty)
                        Text(
                          movie.releaseDate,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Overview",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    movie.overview.isNotEmpty
                        ? movie.overview
                        : "No description available.",
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

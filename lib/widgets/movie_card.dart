import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../screens/details_screen.dart';
import '../services/favorites_service.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onReturn;

  // Used by Library → Watched.
  final bool showUserRating;

  const MovieCard({
    super.key,
    required this.movie,
    this.onReturn,
    this.showUserRating = false,
  });

  @override
  Widget build(BuildContext context) {
    final double? userRating = FavoritesService.instance.getUserRating(movie);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie)),
        );

        onReturn?.call();
      },
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: movie.posterPath.isNotEmpty
                    ? Image.network(
                        movie.posterUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _posterPlaceholder();
                        },
                      )
                    : _posterPlaceholder(),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              movie.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            // TMDB rating
            Row(
              children: [
                const Icon(Icons.star, size: 17, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  'TMDB ${movie.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),

            // Personal rating shown only when requested.
            if (showUserRating) ...[
              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    userRating != null ? Icons.star : Icons.star_border,
                    size: 17,
                    color: userRating != null ? Colors.amber : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    userRating != null
                        ? 'You ${userRating.toStringAsFixed(0)}/10'
                        : 'Not rated',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: userRating != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: userRating != null ? Colors.white : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: double.infinity,
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.movie, size: 50, color: Colors.grey),
      ),
    );
  }
}

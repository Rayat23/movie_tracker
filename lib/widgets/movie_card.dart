import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../screens/details_screen.dart';

class MovieCard extends StatelessWidget {
  final Movie movie;

  const MovieCard({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie)),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: movie.posterPath.isNotEmpty
                    ? Image.network(
                        movie.posterUrl,
                        width: 150,
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
            Row(
              children: [
                const Icon(Icons.star, size: 17, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  movie.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 150,
      color: Colors.grey[900],
      child: const Center(child: Icon(Icons.movie, size: 50)),
    );
  }
}

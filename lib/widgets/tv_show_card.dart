import 'package:flutter/material.dart';

import '../models/tv_show.dart';
import '../screens/tv_details_screen.dart';
import '../services/series_tracking_service.dart';

class TvShowCard extends StatelessWidget {
  final TvShow show;
  final VoidCallback? onReturn;
  final bool showUserRating;

  const TvShowCard({
    super.key,
    required this.show,
    this.onReturn,
    this.showUserRating = false,
  });

  @override
  Widget build(BuildContext context) {
    final userRating = SeriesTrackingService.instance.getUserRating(show);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TvDetailsScreen(show: show),
          ),
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
                child: show.posterPath.isNotEmpty
                    ? Image.network(
                        show.posterUrl,
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
              show.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 17, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  'TMDB ${show.rating.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
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
        child: Icon(Icons.tv, size: 50, color: Colors.grey),
      ),
    );
  }
}

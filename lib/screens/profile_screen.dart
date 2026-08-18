import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/favorites_service.dart';
import 'details_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoritesService favorites = FavoritesService.instance;

    final List<Movie> watchedMovies = favorites.watched;

    final List<Movie> ratedMovies = watchedMovies.where((movie) {
      return favorites.getUserRating(movie) != null;
    }).toList();

    double averageRating = 0;

    if (ratedMovies.isNotEmpty) {
      double total = 0;

      for (final movie in ratedMovies) {
        total += favorites.getUserRating(movie) ?? 0;
      }

      averageRating = total / ratedMovies.length;
    }

    final List<Movie> highestRated = List<Movie>.from(ratedMovies);

    highestRated.sort((a, b) {
      final double ratingA = favorites.getUserRating(a) ?? 0;

      final double ratingB = favorites.getUserRating(b) ?? 0;

      return ratingB.compareTo(ratingA);
    });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Movie Stats',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'A summary of your Movie Tracker activity.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),

              const SizedBox(height: 28),

              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    icon: Icons.favorite,
                    title: 'Favorites',
                    value: '${favorites.favorites.length}',
                    iconColor: Colors.red,
                  ),

                  _buildStatCard(
                    icon: Icons.bookmark,
                    title: 'Watchlist',
                    value: '${favorites.watchlist.length}',
                    iconColor: Colors.blueGrey,
                  ),

                  _buildStatCard(
                    icon: Icons.check_circle,
                    title: 'Watched',
                    value: '${favorites.watched.length}',
                    iconColor: Colors.green,
                  ),

                  _buildStatCard(
                    icon: Icons.star,
                    title: 'Rated',
                    value: '${ratedMovies.length}',
                    iconColor: Colors.amber,
                  ),

                  _buildStatCard(
                    icon: Icons.bar_chart,
                    title: 'Average Rating',
                    value: ratedMovies.isEmpty
                        ? '—'
                        : '${averageRating.toStringAsFixed(1)}/10',
                    iconColor: Colors.amber,
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Text(
                'Your Highest Rated',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              if (highestRated.isEmpty)
                _buildEmptyRatings()
              else
                _buildHighestRatedList(context, highestRated, favorites),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),

          const SizedBox(height: 14),

          Text(
            value,
            style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 4),

          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyRatings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.star_border, size: 55, color: Colors.grey),

          SizedBox(height: 12),

          Text(
            'No rated movies yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),

          SizedBox(height: 6),

          Text(
            'Rate movies you have watched and they will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildHighestRatedList(
    BuildContext context,
    List<Movie> movies,
    FavoritesService favorites,
  ) {
    final int numberToShow = movies.length > 5 ? 5 : movies.length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: numberToShow,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 10);
      },
      itemBuilder: (context, index) {
        final Movie movie = movies[index];

        final double rating = favorites.getUserRating(movie) ?? 0;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailsScreen(movie: movie),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(width: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: movie.posterPath.isNotEmpty
                      ? Image.network(
                          movie.posterUrl,
                          width: 55,
                          height: 82,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _posterPlaceholder();
                          },
                        )
                      : _posterPlaceholder(),
                ),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 19),
                          const SizedBox(width: 5),
                          Text(
                            '${rating.toStringAsFixed(0)}/10',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 55,
      height: 82,
      color: Colors.grey[850],
      child: const Icon(Icons.movie, color: Colors.grey),
    );
  }
}

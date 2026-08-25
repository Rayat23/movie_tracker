import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/favorites_service.dart';
import '../services/series_tracking_service.dart';
import 'details_screen.dart';
import 'diary_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FavoritesService favorites = FavoritesService.instance;
    final SeriesTrackingService seriesTracking =
        SeriesTrackingService.instance;

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

    final movieMinutes = favorites.totalMovieMinutes;
    final tvMinutes = seriesTracking.totalTvMinutes;
    final totalMinutes = movieMinutes + tvMinutes;
    final totalRewatches =
        favorites.totalMovieRewatches + seriesTracking.totalTvRewatches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Stats',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Movies, TV completion, ratings, rewatches, diary, and total watch time.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiaryScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.menu_book),
                    label: const Text('View Diary'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildStatCard(
                    icon: Icons.movie,
                    title: 'Movies Watched',
                    value: '${favorites.watched.length}',
                    iconColor: Colors.green,
                  ),
                  _buildStatCard(
                    icon: Icons.replay_circle_filled,
                    title: 'Movie Watches',
                    value: '${favorites.totalMovieWatchEvents}',
                    iconColor: Colors.deepPurpleAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.tv,
                    title: 'Series Started',
                    value: '${seriesTracking.watchedSeriesCount}',
                    iconColor: Colors.lightBlueAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.task_alt,
                    title: 'Series Completed',
                    value: '${seriesTracking.completedSeriesCount}',
                    iconColor: Colors.greenAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.video_library,
                    title: 'Seasons Completed',
                    value: '${seriesTracking.completedSeasonCount}',
                    iconColor: Colors.tealAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.play_circle,
                    title: 'Episodes Watched',
                    value: '${seriesTracking.totalWatchedEpisodes}',
                    iconColor: Colors.greenAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.replay,
                    title: 'Episode Watches',
                    value: '${seriesTracking.totalTvWatchEvents}',
                    iconColor: Colors.deepPurpleAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.repeat,
                    title: 'Total Rewatches',
                    value: '$totalRewatches',
                    iconColor: Colors.purpleAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.movie_filter,
                    title: 'Movie Watch Time',
                    value: _formatMinutes(movieMinutes),
                    iconColor: Colors.redAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.live_tv,
                    title: 'TV Watch Time',
                    value: _formatMinutes(tvMinutes),
                    iconColor: Colors.cyanAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.timelapse,
                    title: 'Total Watch Time',
                    value: _formatMinutes(totalMinutes),
                    iconColor: Colors.purpleAccent,
                  ),
                  _buildStatCard(
                    icon: Icons.favorite,
                    title: 'Movie Favorites',
                    value: '${favorites.favorites.length}',
                    iconColor: Colors.red,
                  ),
                  _buildStatCard(
                    icon: Icons.bookmark,
                    title: 'Movie Watchlist',
                    value: '${favorites.watchlist.length}',
                    iconColor: Colors.blueGrey,
                  ),
                  _buildStatCard(
                    icon: Icons.star,
                    title: 'Movies Rated',
                    value: '${ratedMovies.length}',
                    iconColor: Colors.amber,
                  ),
                  _buildStatCard(
                    icon: Icons.star_half,
                    title: 'Series Rated',
                    value: '${seriesTracking.ratedSeriesCount}',
                    iconColor: Colors.amber,
                  ),
                  _buildStatCard(
                    icon: Icons.stars,
                    title: 'Seasons Rated',
                    value: '${seriesTracking.ratedSeasonsCount}',
                    iconColor: Colors.amber,
                  ),
                  _buildStatCard(
                    icon: Icons.grade,
                    title: 'Episodes Rated',
                    value: '${seriesTracking.ratedEpisodesCount}',
                    iconColor: Colors.amber,
                  ),
                  _buildStatCard(
                    icon: Icons.bar_chart,
                    title: 'Average Movie Rating',
                    value: ratedMovies.isEmpty
                        ? '—'
                        : '${averageRating.toStringAsFixed(1)}/10',
                    iconColor: Colors.amber,
                  ),
                  _buildStatCard(
                    icon: Icons.query_stats,
                    title: 'Average Series Rating',
                    value: seriesTracking.ratedSeriesCount == 0
                        ? '—'
                        : '${seriesTracking.averageSeriesRating.toStringAsFixed(1)}/10',
                    iconColor: Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Series and season completion use TMDB episode totals saved when you track a season or episode. Older TV activity may need one new tracking action before completion totals are fully backfilled. Watch-time totals include rewatches.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Your Highest Rated Movies',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
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
      width: 205,
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
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';

    final days = minutes ~/ (24 * 60);
    final remainingAfterDays = minutes % (24 * 60);
    final hours = remainingAfterDays ~/ 60;
    final remainingMinutes = remainingAfterDays % 60;

    if (days > 0) {
      if (hours == 0 && remainingMinutes == 0) return '${days}d';
      if (remainingMinutes == 0) return '${days}d ${hours}h';
      return '${days}d ${hours}h ${remainingMinutes}m';
    }

    if (hours == 0) return '${remainingMinutes}m';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
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
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final Movie movie = movies[index];
        final double rating = favorites.getUserRating(movie) ?? 0;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            await Navigator.push(
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
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 19,
                          ),
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

import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
import '../services/series_tracking_service.dart';
import 'details_screen.dart';
import 'diary_screen.dart';
import 'profiles_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesService.instance;
    final seriesTracking = SeriesTrackingService.instance;
    final profileService = ProfileService.instance;
    final profile = profileService.activeProfile;

    final watchedMovies = favorites.watched;
    final ratedMovies = watchedMovies
        .where((movie) => favorites.getUserRating(movie) != null)
        .toList();

    double averageRating = 0;
    if (ratedMovies.isNotEmpty) {
      final total = ratedMovies.fold<double>(
        0,
        (sum, movie) => sum + (favorites.getUserRating(movie) ?? 0),
      );
      averageRating = total / ratedMovies.length;
    }

    final highestRated = List<Movie>.from(ratedMovies)
      ..sort((a, b) {
        final ratingA = favorites.getUserRating(a) ?? 0;
        final ratingB = favorites.getUserRating(b) ?? 0;
        return ratingB.compareTo(ratingA);
      });

    final movieMinutes = favorites.totalMovieMinutes;
    final tvMinutes = seriesTracking.totalTvMinutes;
    final totalMinutes = movieMinutes + tvMinutes;
    final totalRewatches =
        favorites.totalMovieRewatches + seriesTracking.totalTvRewatches;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(context, profile.name, profile.initials),
              const SizedBox(height: 28),
              const Text(
                'Tracking Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Everything below belongs only to the active profile.',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _statCard(Icons.movie, 'Movies Watched', '${favorites.watched.length}', Colors.greenAccent),
                  _statCard(Icons.replay_circle_filled, 'Movie Watches', '${favorites.totalMovieWatchEvents}', Colors.deepPurpleAccent),
                  _statCard(Icons.tv, 'Series Started', '${seriesTracking.watchedSeriesCount}', Colors.lightBlueAccent),
                  _statCard(Icons.task_alt, 'Series Completed', '${seriesTracking.completedSeriesCount}', Colors.greenAccent),
                  _statCard(Icons.video_library, 'Seasons Completed', '${seriesTracking.completedSeasonCount}', Colors.tealAccent),
                  _statCard(Icons.play_circle, 'Episodes Watched', '${seriesTracking.totalWatchedEpisodes}', Colors.greenAccent),
                  _statCard(Icons.replay, 'Episode Watches', '${seriesTracking.totalTvWatchEvents}', Colors.deepPurpleAccent),
                  _statCard(Icons.repeat, 'Total Rewatches', '$totalRewatches', Colors.purpleAccent),
                  _statCard(Icons.movie_filter, 'Movie Watch Time', _formatMinutes(movieMinutes), Colors.redAccent),
                  _statCard(Icons.live_tv, 'TV Watch Time', _formatMinutes(tvMinutes), Colors.cyanAccent),
                  _statCard(Icons.timelapse, 'Total Watch Time', _formatMinutes(totalMinutes), Colors.purpleAccent),
                  _statCard(Icons.favorite, 'Movie Favorites', '${favorites.favorites.length}', Colors.redAccent),
                  _statCard(Icons.bookmark, 'Movie Watchlist', '${favorites.watchlist.length}', Colors.blueGrey),
                  _statCard(Icons.star, 'Movies Rated', '${ratedMovies.length}', Colors.amber),
                  _statCard(Icons.star_half, 'Series Rated', '${seriesTracking.ratedSeriesCount}', Colors.amber),
                  _statCard(Icons.stars, 'Seasons Rated', '${seriesTracking.ratedSeasonsCount}', Colors.amber),
                  _statCard(Icons.grade, 'Episodes Rated', '${seriesTracking.ratedEpisodesCount}', Colors.amber),
                  _statCard(
                    Icons.bar_chart,
                    'Average Movie Rating',
                    ratedMovies.isEmpty ? '—' : '${averageRating.toStringAsFixed(1)}/10',
                    Colors.amber,
                  ),
                  _statCard(
                    Icons.query_stats,
                    'Average Series Rating',
                    seriesTracking.ratedSeriesCount == 0
                        ? '—'
                        : '${seriesTracking.averageSeriesRating.toStringAsFixed(1)}/10',
                    Colors.amber,
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Highest Rated Movies',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    '${ratedMovies.length} rated',
                    style: const TextStyle(color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (highestRated.isEmpty)
                _emptyRatings()
              else
                _highestRatedList(context, highestRated, favorites),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader(BuildContext context, String name, String initials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF291719),
            Color(0xFF151722),
            Color(0xFF0F1118),
          ],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 650;

          final identity = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.18),
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Personal movie & TV profile',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DiaryScreen()),
                  );
                },
                icon: const Icon(Icons.menu_book_rounded),
                label: const Text('Open Diary'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilesScreen()),
                  );
                },
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Manage Profiles'),
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: 20),
                actions,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value, Color iconColor) {
    return Container(
      width: 208,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
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

  Widget _emptyRatings() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: const Column(
        children: [
          Icon(Icons.star_border_rounded, size: 52, color: Colors.white30),
          SizedBox(height: 12),
          Text(
            'No rated movies yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Rate movies you have watched and your favorites will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _highestRatedList(
    BuildContext context,
    List<Movie> movies,
    FavoritesService favorites,
  ) {
    final numberToShow = movies.length > 5 ? 5 : movies.length;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: numberToShow,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final movie = movies[index];
        final rating = favorites.getUserRating(movie) ?? 0;

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailsScreen(movie: movie)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF11131A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white30,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: movie.posterPath.isNotEmpty
                      ? Image.network(
                          movie.posterUrl,
                          width: 54,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _posterPlaceholder(),
                        )
                      : _posterPlaceholder(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 19),
                          const SizedBox(width: 5),
                          Text(
                            '${rating.toStringAsFixed(0)}/10',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      width: 54,
      height: 80,
      color: Colors.white10,
      child: const Icon(Icons.movie_outlined, color: Colors.white30),
    );
  }
}

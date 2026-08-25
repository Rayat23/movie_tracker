import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/favorites_service.dart';
import '../services/movie_service.dart';

class DetailsScreen extends StatefulWidget {
  final Movie movie;

  const DetailsScreen({super.key, required this.movie});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final FavoritesService favorites = FavoritesService.instance;
  final MovieService movieService = MovieService();

  late Movie currentMovie;

  @override
  void initState() {
    super.initState();
    currentMovie = widget.movie;
    _loadMovieDetails();
  }

  Future<void> _loadMovieDetails() async {
    try {
      final detailedMovie = await movieService.fetchMovieDetails(widget.movie.id);
      await favorites.syncMovieMetadata(detailedMovie);

      if (!mounted) return;

      setState(() {
        currentMovie = detailedMovie;
      });
    } catch (_) {
      // Keep using the list/search result if detailed metadata is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final Movie movie = currentMovie;

    final bool isFav = favorites.isFavorite(movie);
    final bool isWatchlist = favorites.isInWatchlist(movie);
    final bool isWatched = favorites.isWatched(movie);
    final double? userRating = favorites.getUserRating(movie);
    final DateTime? watchedDate = favorites.getWatchedDate(movie);

    return Scaffold(
      appBar: AppBar(
        title: Text(movie.title),
        actions: [
          IconButton(
            tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
            icon: Icon(
              isFav ? Icons.favorite : Icons.favorite_border,
              color: isFav ? Colors.red : Colors.white,
            ),
            onPressed: () async {
              await favorites.toggle(movie);
              if (!mounted) return;
              setState(() {});
              _showMessage(
                favorites.isFavorite(movie)
                    ? 'Added to Favorites'
                    : 'Removed from Favorites',
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isDesktop = constraints.maxWidth >= 800;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: isDesktop
                    ? _buildDesktopLayout(
                        movie,
                        isFav,
                        isWatchlist,
                        isWatched,
                        userRating,
                        watchedDate,
                      )
                    : _buildMobileLayout(
                        movie,
                        isFav,
                        isWatchlist,
                        isWatched,
                        userRating,
                        watchedDate,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(
    Movie movie,
    bool isFav,
    bool isWatchlist,
    bool isWatched,
    double? userRating,
    DateTime? watchedDate,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 280, child: _buildPoster(movie)),
        const SizedBox(width: 32),
        Expanded(
          child: _buildMovieInformation(
            movie,
            isFav,
            isWatchlist,
            isWatched,
            userRating,
            watchedDate,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    Movie movie,
    bool isFav,
    bool isWatchlist,
    bool isWatched,
    double? userRating,
    DateTime? watchedDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: SizedBox(width: 240, child: _buildPoster(movie))),
        const SizedBox(height: 24),
        _buildMovieInformation(
          movie,
          isFav,
          isWatchlist,
          isWatched,
          userRating,
          watchedDate,
        ),
      ],
    );
  }

  Widget _buildPoster(Movie movie) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: movie.posterPath.isNotEmpty
            ? Image.network(
                movie.posterUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _posterPlaceholder();
                },
              )
            : _posterPlaceholder(),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.movie, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _buildMovieInformation(
    Movie movie,
    bool isFav,
    bool isWatchlist,
    bool isWatched,
    double? userRating,
    DateTime? watchedDate,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 22),
                const SizedBox(width: 6),
                Text(
                  'TMDB ${movie.rating.toStringAsFixed(1)}',
                  style: const TextStyle(fontSize: 17),
                ),
              ],
            ),
            if (movie.releaseDate.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month,
                    size: 20,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    movie.releaseDate,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            if (movie.runtimeMinutes > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.schedule, size: 20, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _formatRuntime(movie.runtimeMinutes),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
        if (isWatched && watchedDate != null) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Watched ${_formatDate(watchedDate)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                userRating != null ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 26,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Rating',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    userRating != null
                        ? '${userRating.toStringAsFixed(0)}/10'
                        : 'Not rated',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {
                  _showRatingDialog(movie, userRating);
                },
                child: Text(
                  userRating == null ? 'Rate Movie' : 'Change Rating',
                ),
              ),
              if (userRating != null)
                IconButton(
                  tooltip: 'Remove Rating',
                  onPressed: () async {
                    await favorites.removeUserRating(movie);
                    if (!mounted) return;
                    setState(() {});
                    _showMessage('Rating removed');
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await favorites.toggle(movie);
                if (!mounted) return;
                setState(() {});
                _showMessage(
                  favorites.isFavorite(movie)
                      ? 'Added to Favorites'
                      : 'Removed from Favorites',
                );
              },
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
              label: Text(isFav ? 'Favorite' : 'Add Favorite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isFav ? Colors.red : Colors.grey[850],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await favorites.toggleWatchlist(movie);
                if (!mounted) return;
                setState(() {});
                _showMessage(
                  favorites.isInWatchlist(movie)
                      ? 'Added to Watchlist'
                      : 'Removed from Watchlist',
                );
              },
              icon: Icon(isWatchlist ? Icons.bookmark : Icons.bookmark_border),
              label: Text(isWatchlist ? 'In Watchlist' : 'Watchlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isWatchlist ? Colors.blueGrey : Colors.grey[850],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await favorites.toggleWatched(movie);
                if (!mounted) return;
                setState(() {});
                _showMessage(
                  favorites.isWatched(movie)
                      ? 'Marked as Watched'
                      : 'Removed from Watched',
                );
              },
              icon: Icon(
                isWatched ? Icons.check_circle : Icons.check_circle_outline,
              ),
              label: Text(isWatched ? 'Watched' : 'Mark Watched'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isWatched ? Colors.green : Colors.grey[850],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Overview',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          movie.overview.isNotEmpty
              ? movie.overview
              : 'No description available.',
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  String _formatRuntime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) return '$remainingMinutes min';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _showRatingDialog(Movie movie, double? currentRating) async {
    int selectedRating = currentRating?.toInt() ?? 0;

    final int? rating = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate ${movie.title}'),
              content: SizedBox(
                width: 350,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Choose a rating from 1 to 10'),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: List.generate(10, (index) {
                        final int value = index + 1;
                        return ChoiceChip(
                          label: Text('$value'),
                          selected: selectedRating == value,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedRating = value;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    if (selectedRating > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 30),
                          const SizedBox(width: 8),
                          Text(
                            '$selectedRating/10',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () {
                          Navigator.pop(dialogContext, selectedRating);
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (rating == null) return;

    await favorites.setUserRating(movie, rating.toDouble());
    if (!mounted) return;
    setState(() {});
    _showMessage('You rated ${movie.title} $rating/10');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(duration: const Duration(seconds: 1), content: Text(message)),
      );
  }
}

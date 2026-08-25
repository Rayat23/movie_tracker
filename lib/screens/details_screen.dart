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
      setState(() => currentMovie = detailedMovie);
    } catch (_) {
      // Keep the list/search result if detailed metadata is unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final movie = currentMovie;
    final isFav = favorites.isFavorite(movie);
    final isWatchlist = favorites.isInWatchlist(movie);
    final isWatched = favorites.isWatched(movie);
    final userRating = favorites.getUserRating(movie);
    final latestWatchDate = favorites.getLatestMovieWatchDate(movie);
    final watchCount = favorites.getMovieWatchCount(movie);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.28),
        elevation: 0,
        title: const Text('Movie Details'),
        actions: [
          IconButton(
            tooltip: isFav ? 'Remove from Favorites' : 'Add to Favorites',
            onPressed: () => _toggleFavorite(movie),
            icon: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFav ? Colors.redAccent : Colors.white,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _cinematicHero(
              movie,
              isFav: isFav,
              isWatchlist: isWatchlist,
              isWatched: isWatched,
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 46),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _trackingSection(
                        movie,
                        isWatched: isWatched,
                        latestWatchDate: latestWatchDate,
                        watchCount: watchCount,
                      ),
                      const SizedBox(height: 18),
                      _ratingCard(movie, userRating),
                      const SizedBox(height: 30),
                      _sectionHeading(
                        'Overview',
                        'About this movie',
                        Icons.subject_rounded,
                      ),
                      const SizedBox(height: 12),
                      _overviewCard(movie.overview),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cinematicHero(
    Movie movie, {
    required bool isFav,
    required bool isWatchlist,
    required bool isWatched,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 820;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: desktop ? 520 : 760),
          decoration: const BoxDecoration(color: Color(0xFF0B0D12)),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(child: _backdrop(movie)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.18),
                        const Color(0xFF0B0D12).withValues(alpha: 0.92),
                        const Color(0xFF0B0D12),
                      ],
                      stops: const [0, 0.35, 0.82, 1],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        22,
                        desktop ? 78 : 86,
                        22,
                        30,
                      ),
                      child: desktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(width: 250, child: _poster(movie)),
                                const SizedBox(width: 30),
                                Expanded(
                                  child: _heroInfo(
                                    movie,
                                    isFav: isFav,
                                    isWatchlist: isWatchlist,
                                    isWatched: isWatched,
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: SizedBox(
                                    width: 205,
                                    child: _poster(movie),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _heroInfo(
                                  movie,
                                  isFav: isFav,
                                  isWatchlist: isWatchlist,
                                  isWatched: isWatched,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _backdrop(Movie movie) {
    if (movie.backdropPath.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF35181B), Color(0xFF151824), Color(0xFF0B0D12)],
          ),
        ),
      );
    }

    return Image.network(
      movie.backdropUrl,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) {
        return Container(color: const Color(0xFF11131A));
      },
    );
  }

  Widget _poster(Movie movie) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: movie.posterPath.isNotEmpty
              ? Image.network(
                  movie.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _posterPlaceholder(),
                )
              : _posterPlaceholder(),
        ),
      ),
    );
  }

  Widget _posterPlaceholder() {
    return Container(
      color: const Color(0xFF151821),
      child: const Center(
        child: Icon(Icons.movie_rounded, size: 70, color: Colors.white24),
      ),
    );
  }

  Widget _heroInfo(
    Movie movie, {
    required bool isFav,
    required bool isWatchlist,
    required bool isWatched,
  }) {
    final year = movie.releaseDate.length >= 4
        ? movie.releaseDate.substring(0, 4)
        : movie.releaseDate;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: const Text(
            'MOVIE',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
              color: Colors.white70,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          movie.title,
          style: const TextStyle(
            fontSize: 38,
            height: 1.05,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _metaChip(
              Icons.star_rounded,
              movie.rating.toStringAsFixed(1),
              Colors.amber,
            ),
            if (year.isNotEmpty)
              _metaChip(Icons.calendar_month_rounded, year, Colors.white70),
            if (movie.runtimeMinutes > 0)
              _metaChip(
                Icons.schedule_rounded,
                _formatRuntime(movie.runtimeMinutes),
                Colors.white70,
              ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionButton(
              icon: isWatched
                  ? Icons.check_circle_rounded
                  : Icons.check_circle_outline_rounded,
              label: isWatched ? 'Watched' : 'Mark Watched',
              selected: isWatched,
              selectedColor: Colors.green,
              onPressed: () => _toggleWatched(movie),
            ),
            _actionButton(
              icon: isWatchlist
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: isWatchlist ? 'In Watchlist' : 'Watchlist',
              selected: isWatchlist,
              selectedColor: Colors.blueGrey,
              onPressed: () => _toggleWatchlist(movie),
            ),
            _actionButton(
              icon: isFav
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: 'Favorite',
              selected: isFav,
              selectedColor: Colors.red,
              onPressed: () => _toggleFavorite(movie),
            ),
            if (isWatched)
              _actionButton(
                icon: Icons.replay_rounded,
                label: 'Log Rewatch',
                selected: true,
                selectedColor: Colors.deepPurple,
                onPressed: () => _logRewatch(movie),
              ),
          ],
        ),
      ],
    );
  }

  Widget _metaChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required bool selected,
    required Color selectedColor,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected
            ? selectedColor
            : Colors.white.withValues(alpha: 0.09),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        side: BorderSide(
          color: selected
              ? selectedColor.withValues(alpha: 0.8)
              : Colors.white12,
        ),
      ),
    );
  }

  Widget _trackingSection(
    Movie movie, {
    required bool isWatched,
    required DateTime? latestWatchDate,
    required int watchCount,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;

        final status = _detailPanel(
          icon: isWatched ? Icons.check_circle_rounded : Icons.history_rounded,
          iconColor: isWatched ? Colors.greenAccent : Colors.white54,
          title: 'Watch status',
          value: isWatched
              ? (watchCount > 1 ? 'Watched $watchCount times' : 'Watched')
              : 'Not watched yet',
          detail: isWatched && latestWatchDate != null
              ? 'Latest ${_formatDate(latestWatchDate)}'
              : 'Mark it watched to start your diary history.',
        );

        final runtime = _detailPanel(
          icon: Icons.timer_outlined,
          iconColor: Colors.cyanAccent,
          title: 'Runtime',
          value: movie.runtimeMinutes > 0
              ? _formatRuntime(movie.runtimeMinutes)
              : 'Unknown',
          detail: movie.runtimeMinutes > 0
              ? 'Included in your watch-time statistics.'
              : 'Runtime will appear when TMDB provides it.',
        );

        if (compact) {
          return Column(
            children: [
              status,
              const SizedBox(height: 12),
              runtime,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: status),
            const SizedBox(width: 12),
            Expanded(child: runtime),
          ],
        );
      },
    );
  }

  Widget _detailPanel({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String detail,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingCard(Movie movie, double? userRating) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B1710), Color(0xFF11131A)],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              userRating != null
                  ? Icons.star_rounded
                  : Icons.star_border_rounded,
              color: Colors.amber,
              size: 28,
            ),
          ),
          SizedBox(
            width: 190,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your rating',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  userRating == null
                      ? 'Not rated'
                      : '${userRating.toStringAsFixed(0)}/10',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showRatingDialog(movie, userRating),
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(userRating == null ? 'Rate Movie' : 'Change Rating'),
          ),
          if (userRating != null)
            TextButton.icon(
              onPressed: () async {
                await favorites.removeUserRating(movie);
                if (!mounted) return;
                setState(() {});
                _showMessage('Rating removed');
              },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Remove'),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white70, size: 21),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _overviewCard(String overview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        overview.isNotEmpty ? overview : 'No description available.',
        style: const TextStyle(
          fontSize: 16,
          height: 1.65,
          color: Colors.white70,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Movie movie) async {
    await favorites.toggle(movie);
    if (!mounted) return;
    setState(() {});
    _showMessage(
      favorites.isFavorite(movie)
          ? 'Added to Favorites'
          : 'Removed from Favorites',
    );
  }

  Future<void> _toggleWatchlist(Movie movie) async {
    await favorites.toggleWatchlist(movie);
    if (!mounted) return;
    setState(() {});
    _showMessage(
      favorites.isInWatchlist(movie)
          ? 'Added to Watchlist'
          : 'Removed from Watchlist',
    );
  }

  Future<void> _toggleWatched(Movie movie) async {
    await favorites.toggleWatched(movie);
    if (!mounted) return;
    setState(() {});
    _showMessage(
      favorites.isWatched(movie) ? 'Marked as Watched' : 'Removed from Watched',
    );
  }

  Future<void> _logRewatch(Movie movie) async {
    await favorites.logRewatch(movie);
    if (!mounted) return;
    setState(() {});
    _showMessage(
      'Rewatch logged • ${favorites.getMovieWatchCount(movie)} total watches',
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

    final rating = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate ${movie.title}'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Choose your personal rating from 1 to 10.'),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      alignment: WrapAlignment.center,
                      children: List.generate(10, (index) {
                        final value = index + 1;
                        return ChoiceChip(
                          label: Text('$value'),
                          selected: selectedRating == value,
                          onSelected: (_) {
                            setDialogState(() => selectedRating = value);
                          },
                        );
                      }),
                    ),
                    if (selectedRating > 0) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: 30,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$selectedRating/10',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () => Navigator.pop(dialogContext, selectedRating),
                  child: const Text('Save Rating'),
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
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(message),
        ),
      );
  }
}

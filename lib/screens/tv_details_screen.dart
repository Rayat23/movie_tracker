import 'package:flutter/material.dart';

import '../models/season.dart';
import '../models/tv_show.dart';
import '../services/series_tracking_service.dart';
import '../services/tv_service.dart';
import 'season_screen.dart';

class TvDetailsScreen extends StatefulWidget {
  final TvShow show;

  const TvDetailsScreen({super.key, required this.show});

  @override
  State<TvDetailsScreen> createState() => _TvDetailsScreenState();
}

class _TvDetailsScreenState extends State<TvDetailsScreen> {
  final TvService tvService = TvService();
  final SeriesTrackingService tracking = SeriesTrackingService.instance;

  late Future<TvShow> detailsFuture;
  late Future<List<Season>> seasonsFuture;

  @override
  void initState() {
    super.initState();
    detailsFuture = tvService.fetchTvShowDetails(widget.show.id);
    seasonsFuture = tvService.fetchSeasons(widget.show.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.28),
        elevation: 0,
        title: const Text('Series Details'),
      ),
      body: FutureBuilder<TvShow>(
        future: detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final show = snapshot.data ?? widget.show;

          if (snapshot.hasError && snapshot.data == null) {
            return _errorState(snapshot.error.toString());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                _cinematicHero(show),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _progressCard(show),
                          const SizedBox(height: 18),
                          _ratingCard(show),
                          const SizedBox(height: 30),
                          _sectionHeading(
                            'Overview',
                            'About this series',
                            Icons.subject_rounded,
                          ),
                          const SizedBox(height: 12),
                          _overviewCard(show.overview),
                          const SizedBox(height: 34),
                          _sectionHeading(
                            'Seasons',
                            'Continue tracking episode by episode',
                            Icons.video_library_rounded,
                          ),
                          const SizedBox(height: 16),
                          _seasonsSection(show),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cinematicHero(TvShow show) {
    final isFavorite = tracking.isFavorite(show);
    final isWatchlist = tracking.isInWatchlist(show);
    final watchedEpisodes = tracking.watchedEpisodeCountForShow(show.id);
    final completed = tracking.isShowComplete(show.id);

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 820;

        return Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: desktop ? 540 : 790),
          color: const Color(0xFF0B0D12),
          child: Stack(
            children: [
              Positioned.fill(child: _backdrop(show)),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.34),
                        Colors.black.withValues(alpha: 0.18),
                        const Color(0xFF0B0D12).withValues(alpha: 0.93),
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
                        desktop ? 78 : 88,
                        22,
                        30,
                      ),
                      child: desktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(width: 250, child: _poster(show)),
                                const SizedBox(width: 30),
                                Expanded(
                                  child: _heroInfo(
                                    show,
                                    isFavorite: isFavorite,
                                    isWatchlist: isWatchlist,
                                    watchedEpisodes: watchedEpisodes,
                                    completed: completed,
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
                                    child: _poster(show),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _heroInfo(
                                  show,
                                  isFavorite: isFavorite,
                                  isWatchlist: isWatchlist,
                                  watchedEpisodes: watchedEpisodes,
                                  completed: completed,
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

  Widget _backdrop(TvShow show) {
    if (show.backdropPath.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF132B32), Color(0xFF161827), Color(0xFF0B0D12)],
          ),
        ),
      );
    }

    return Image.network(
      show.backdropUrl,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (context, error, stackTrace) =>
          Container(color: const Color(0xFF11131A)),
    );
  }

  Widget _poster(TvShow show) {
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
          child: show.posterPath.isNotEmpty
              ? Image.network(
                  show.posterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _placeholder(),
                )
              : _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFF151821),
      child: const Center(
        child: Icon(Icons.tv_rounded, size: 70, color: Colors.white24),
      ),
    );
  }

  Widget _heroInfo(
    TvShow show, {
    required bool isFavorite,
    required bool isWatchlist,
    required int watchedEpisodes,
    required bool completed,
  }) {
    final year = show.firstAirDate.length >= 4
        ? show.firstAirDate.substring(0, 4)
        : show.firstAirDate;

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
            'TV SERIES',
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
          show.name,
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
            _metaChip(Icons.star_rounded, show.rating.toStringAsFixed(1), Colors.amber),
            if (year.isNotEmpty)
              _metaChip(Icons.calendar_month_rounded, year, Colors.white70),
            if (show.numberOfSeasons > 0)
              _metaChip(
                Icons.video_library_rounded,
                '${show.numberOfSeasons} seasons',
                Colors.lightBlueAccent,
              ),
            if (show.numberOfEpisodes > 0)
              _metaChip(
                Icons.play_circle_rounded,
                '${show.numberOfEpisodes} episodes',
                Colors.greenAccent,
              ),
            if (watchedEpisodes > 0)
              _metaChip(
                completed ? Icons.task_alt_rounded : Icons.visibility_rounded,
                completed ? 'Completed' : '$watchedEpisodes watched',
                completed ? Colors.greenAccent : Colors.white70,
              ),
          ],
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _actionButton(
              icon: isWatchlist
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              label: isWatchlist ? 'In Watchlist' : 'Watchlist',
              selected: isWatchlist,
              selectedColor: Colors.blueGrey,
              onPressed: () => _toggleWatchlist(show),
            ),
            _actionButton(
              icon: isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              label: 'Favorite',
              selected: isFavorite,
              selectedColor: Colors.red,
              onPressed: () => _toggleFavorite(show),
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

  Widget _progressCard(TvShow show) {
    final watchedEpisodes = tracking.watchedEpisodeCountForShow(show.id);
    final totalEpisodes = show.numberOfEpisodes;
    final progress = totalEpisodes > 0 ? watchedEpisodes / totalEpisodes : 0.0;
    final watchedMinutes = tracking.watchedMinutesForShow(show.id);
    final completed = totalEpisodes > 0 && watchedEpisodes >= totalEpisodes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: completed
              ? Colors.green.withValues(alpha: 0.28)
              : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: (completed ? Colors.greenAccent : Colors.redAccent)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  completed ? Icons.task_alt_rounded : Icons.track_changes_rounded,
                  color: completed ? Colors.greenAccent : Colors.redAccent,
                ),
              ),
              SizedBox(
                width: 280,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      completed ? 'Series complete' : 'Watching progress',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      totalEpisodes > 0
                          ? '$watchedEpisodes of $totalEpisodes episodes watched'
                          : '$watchedEpisodes episodes watched',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (watchedMinutes > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    _formatMinutes(watchedMinutes),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          if (totalEpisodes > 0) ...[
            const SizedBox(height: 17),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                color: completed ? Colors.green : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).round()}% complete',
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ratingCard(TvShow show) {
    final userRating = tracking.getUserRating(show);

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
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your series rating',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  userRating == null
                      ? 'Not rated'
                      : '${userRating.toStringAsFixed(0)}/10',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showRatingDialog(show, userRating),
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(userRating == null ? 'Rate Series' : 'Change Rating'),
          ),
          if (userRating != null)
            TextButton.icon(
              onPressed: () async {
                await tracking.removeUserRating(show);
                if (!mounted) return;
                setState(() {});
                _showMessage('Series rating removed');
              },
              icon: const Icon(Icons.close_rounded),
              label: const Text('Remove'),
            ),
        ],
      ),
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
        style: const TextStyle(fontSize: 16, height: 1.65, color: Colors.white70),
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
        Expanded(
          child: Column(
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
        ),
      ],
    );
  }

  Widget _seasonsSection(TvShow show) {
    return FutureBuilder<List<Season>>(
      future: seasonsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _inlineMessage('Could not load seasons. ${snapshot.error}');
        }

        final seasons = snapshot.data ?? const <Season>[];
        if (seasons.isEmpty) {
          return _inlineMessage('No season information is available yet.');
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth < 520 ? 160.0 : 190.0;

            return Wrap(
              spacing: 14,
              runSpacing: 14,
              children: seasons
                  .map(
                    (season) => _SeasonCard(
                      width: cardWidth,
                      show: show,
                      season: season,
                      watchedCount: tracking.watchedEpisodeCountForSeason(
                        show.id,
                        season.seasonNumber,
                      ),
                      seasonRating: tracking.getSeasonRating(
                        show.id,
                        season.seasonNumber,
                      ),
                      onReturn: () {
                        if (!mounted) return;
                        setState(() {});
                      },
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _inlineMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white54)),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _inlineMessage(message),
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(TvShow show) async {
    await tracking.toggleFavorite(show);
    if (!mounted) return;
    setState(() {});
    _showMessage(
      tracking.isFavorite(show)
          ? 'Added to TV Favorites'
          : 'Removed from TV Favorites',
    );
  }

  Future<void> _toggleWatchlist(TvShow show) async {
    await tracking.toggleWatchlist(show);
    if (!mounted) return;
    setState(() {});
    _showMessage(
      tracking.isInWatchlist(show)
          ? 'Added to TV Watchlist'
          : 'Removed from TV Watchlist',
    );
  }

  Future<void> _showRatingDialog(
    TvShow show,
    double? currentRating,
  ) async {
    int selectedRating = currentRating?.toInt() ?? 0;

    final rating = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Rate ${show.name}'),
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
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 30),
                          const SizedBox(width: 7),
                          Text(
                            '$selectedRating/10',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
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
    await tracking.setUserRating(show, rating.toDouble());
    if (!mounted) return;
    setState(() {});
    _showMessage('You rated ${show.name} $rating/10');
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$remainingMinutes min watched';
    if (remainingMinutes == 0) return '${hours}h watched';
    return '${hours}h ${remainingMinutes}m watched';
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

class _SeasonCard extends StatelessWidget {
  final double width;
  final TvShow show;
  final Season season;
  final int watchedCount;
  final double? seasonRating;
  final VoidCallback onReturn;

  const _SeasonCard({
    required this.width,
    required this.show,
    required this.season,
    required this.watchedCount,
    required this.seasonRating,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final total = season.episodeCount;
    final complete = total > 0 && watchedCount >= total;
    final progress = total > 0 ? watchedCount / total : 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeasonScreen(show: show, season: season),
          ),
        );
        onReturn();
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF11131A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: complete
                ? Colors.green.withValues(alpha: 0.38)
                : Colors.white10,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: season.posterPath.isNotEmpty
                    ? Image.network(
                        season.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _seasonPlaceholder(),
                      )
                    : _seasonPlaceholder(),
              ),
            ),
            const SizedBox(height: 11),
            Text(
              season.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              total > 0 ? '$watchedCount / $total episodes' : '$watchedCount watched',
              style: TextStyle(
                fontSize: 12,
                color: complete ? Colors.greenAccent : Colors.white54,
              ),
            ),
            if (seasonRating != null) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                  const SizedBox(width: 4),
                  Text(
                    'You ${seasonRating!.toStringAsFixed(0)}/10',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ],
            if (total > 0) ...[
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  color: complete ? Colors.green : Colors.redAccent,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _seasonPlaceholder() {
    return Container(
      color: const Color(0xFF151821),
      child: const Center(
        child: Icon(Icons.video_library_rounded, size: 42, color: Colors.white24),
      ),
    );
  }
}

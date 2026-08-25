import 'package:flutter/material.dart';

import '../models/season.dart';
import '../models/tv_show.dart';
import '../services/series_tracking_service.dart';
import '../services/tv_service.dart';
import 'season_screen.dart';

class TvDetailsScreen extends StatefulWidget {
  final TvShow show;

  const TvDetailsScreen({
    super.key,
    required this.show,
  });

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
      appBar: AppBar(title: Text(widget.show.name)),
      body: FutureBuilder<TvShow>(
        future: detailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final show = snapshot.data ?? widget.show;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1150),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool desktop = constraints.maxWidth >= 760;

                        if (desktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 280,
                                child: _poster(show),
                              ),
                              const SizedBox(width: 32),
                              Expanded(child: _showInfo(show)),
                            ],
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: SizedBox(
                                width: 240,
                                child: _poster(show),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _showInfo(show),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 36),
                    const Text(
                      'Seasons',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder<List<Season>>(
                      future: seasonsFuture,
                      builder: (context, seasonSnapshot) {
                        if (seasonSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (seasonSnapshot.hasError) {
                          return Text(seasonSnapshot.error.toString());
                        }

                        final seasons = seasonSnapshot.data ?? [];

                        if (seasons.isEmpty) {
                          return const Text(
                            'No season information is available yet.',
                            style: TextStyle(color: Colors.grey),
                          );
                        }

                        return Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: seasons
                              .map(
                                (season) => _SeasonCard(
                                  show: show,
                                  season: season,
                                  watchedCount:
                                      tracking.watchedEpisodeCountForSeason(
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
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _poster(TvShow show) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
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
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Icon(Icons.tv, size: 80, color: Colors.grey),
      ),
    );
  }

  Widget _showInfo(TvShow show) {
    final watchedEpisodes = tracking.watchedEpisodeCountForShow(show.id);
    final totalEpisodes = show.numberOfEpisodes;
    final progress = totalEpisodes > 0
        ? watchedEpisodes / totalEpisodes
        : 0.0;
    final watchedMinutes = tracking.watchedMinutesForShow(show.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          show.name,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 10,
          children: [
            _infoChip(
              Icons.star,
              'TMDB ${show.rating.toStringAsFixed(1)}',
              Colors.amber,
            ),
            if (show.firstAirDate.isNotEmpty)
              _infoChip(
                Icons.calendar_month,
                show.firstAirDate,
                Colors.grey,
              ),
            if (show.numberOfSeasons > 0)
              _infoChip(
                Icons.video_library,
                '${show.numberOfSeasons} seasons',
                Colors.lightBlueAccent,
              ),
            if (show.numberOfEpisodes > 0)
              _infoChip(
                Icons.play_circle_outline,
                '${show.numberOfEpisodes} episodes',
                Colors.greenAccent,
              ),
          ],
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.track_changes, color: Colors.redAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      totalEpisodes > 0
                          ? '$watchedEpisodes of $totalEpisodes episodes watched'
                          : '$watchedEpisodes episodes watched',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (watchedMinutes > 0)
                    Text(
                      _formatMinutes(watchedMinutes),
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
              if (totalEpisodes > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 9,
                    backgroundColor: Colors.black26,
                    color: progress >= 1 ? Colors.green : Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).round()}% complete',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          show.overview.isNotEmpty
              ? show.overview
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

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours == 0) {
      return '$remainingMinutes min watched';
    }

    if (remainingMinutes == 0) {
      return '${hours}h watched';
    }

    return '${hours}h ${remainingMinutes}m watched';
  }
}

class _SeasonCard extends StatelessWidget {
  final TvShow show;
  final Season season;
  final int watchedCount;
  final VoidCallback onReturn;

  const _SeasonCard({
    required this.show,
    required this.season,
    required this.watchedCount,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final total = season.episodeCount;
    final complete = total > 0 && watchedCount >= total;
    final progress = total > 0 ? watchedCount / total : 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeasonScreen(
              show: show,
              season: season,
            ),
          ),
        );

        onReturn();
      },
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: complete
              ? Border.all(color: Colors.green.withValues(alpha: 0.45))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
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
            const SizedBox(height: 10),
            Text(
              season.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              total > 0
                  ? '$watchedCount / $total episodes'
                  : '$watchedCount watched',
              style: TextStyle(
                fontSize: 13,
                color: complete ? Colors.greenAccent : Colors.grey,
              ),
            ),
            if (total > 0) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.black26,
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
      color: Colors.black26,
      child: const Center(
        child: Icon(Icons.video_library, size: 42, color: Colors.grey),
      ),
    );
  }
}

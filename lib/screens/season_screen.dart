import 'package:flutter/material.dart';

import '../models/episode.dart';
import '../models/season.dart';
import '../models/tv_show.dart';
import '../services/series_tracking_service.dart';
import '../services/tv_service.dart';

class SeasonScreen extends StatefulWidget {
  final TvShow show;
  final Season season;

  const SeasonScreen({
    super.key,
    required this.show,
    required this.season,
  });

  @override
  State<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends State<SeasonScreen> {
  final TvService tvService = TvService();
  final SeriesTrackingService tracking = SeriesTrackingService.instance;

  late Future<List<Episode>> episodesFuture;

  @override
  void initState() {
    super.initState();
    episodesFuture = tvService.fetchEpisodes(
      widget.show.id,
      widget.season.seasonNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.show.name} • ${widget.season.name}'),
      ),
      body: FutureBuilder<List<Episode>>(
        future: episodesFuture,
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

          final episodes = snapshot.data ?? [];

          if (episodes.isEmpty) {
            return const Center(
              child: Text('No episodes found for this season.'),
            );
          }

          final watchedCount = tracking.watchedEpisodeCountForSeason(
            widget.show.id,
            widget.season.seasonNumber,
          );
          final isComplete = watchedCount >= episodes.length;
          final progress = watchedCount / episodes.length;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: episodes.length + 1,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 14),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _SeasonProgressCard(
                  watchedCount: watchedCount,
                  totalCount: episodes.length,
                  progress: progress,
                  isComplete: isComplete,
                  onToggleSeason: () async {
                    await tracking.setSeasonWatched(
                      show: widget.show,
                      season: widget.season,
                      episodes: episodes,
                      watched: !isComplete,
                    );

                    if (!mounted) return;
                    setState(() {});
                  },
                );
              }

              final episode = episodes[index - 1];
              final isWatched = tracking.isEpisodeWatched(
                widget.show.id,
                episode.id,
              );
              final latestWatchAt = tracking.latestWatchDateForEpisode(
                widget.show.id,
                episode.id,
              );
              final watchCount = tracking.episodeWatchCount(
                widget.show.id,
                episode.id,
              );

              return _EpisodeTile(
                episode: episode,
                isWatched: isWatched,
                latestWatchAt: latestWatchAt,
                watchCount: watchCount,
                onToggle: () async {
                  await tracking.toggleEpisodeWatched(
                    widget.show,
                    episode,
                  );

                  if (!mounted) return;
                  setState(() {});
                },
                onRewatch: () async {
                  await tracking.logEpisodeRewatch(
                    widget.show,
                    episode,
                  );

                  if (!mounted || !context.mounted) return;
                  setState(() {});

                  final count = tracking.episodeWatchCount(
                    widget.show.id,
                    episode.id,
                  );

                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 1),
                        content: Text(
                          'Rewatch logged • $count total watches',
                        ),
                      ),
                    );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SeasonProgressCard extends StatelessWidget {
  final int watchedCount;
  final int totalCount;
  final double progress;
  final bool isComplete;
  final Future<void> Function() onToggleSeason;

  const _SeasonProgressCard({
    required this.watchedCount,
    required this.totalCount,
    required this.progress,
    required this.isComplete,
    required this.onToggleSeason,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Season progress',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$watchedCount of $totalCount episodes watched',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await onToggleSeason();
                },
                icon: Icon(
                  isComplete ? Icons.replay : Icons.done_all,
                ),
                label: Text(
                  isComplete ? 'Unmark season' : 'Mark season watched',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isComplete ? Colors.grey[800] : Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: Colors.black26,
              color: isComplete ? Colors.green : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final bool isWatched;
  final DateTime? latestWatchAt;
  final int watchCount;
  final Future<void> Function() onToggle;
  final Future<void> Function() onRewatch;

  const _EpisodeTile({
    required this.episode,
    required this.isWatched,
    required this.latestWatchAt,
    required this.watchCount,
    required this.onToggle,
    required this.onRewatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
        border: isWatched
            ? Border.all(color: Colors.green.withValues(alpha: 0.45))
            : null,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool compact = constraints.maxWidth < 650;

          final image = ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: compact ? double.infinity : 220,
              height: compact ? 190 : 124,
              child: episode.stillPath.isNotEmpty
                  ? Image.network(
                      episode.stillUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _placeholder();
                      },
                    )
                  : _placeholder(),
            ),
          );

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'E${episode.episodeNumber} • ${episode.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  if (episode.airDate.isNotEmpty)
                    Text(
                      episode.airDate,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (episode.runtimeMinutes > 0)
                    Text(
                      '${episode.runtimeMinutes} min',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  if (isWatched && latestWatchAt != null)
                    Text(
                      watchCount > 1
                          ? 'Watched $watchCount times • latest ${_formatDate(latestWatchAt!)}'
                          : 'Watched ${_formatDate(latestWatchAt!)}',
                      style: const TextStyle(color: Colors.greenAccent),
                    ),
                ],
              ),
              if (episode.overview.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  episode.overview,
                  maxLines: compact ? 4 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    height: 1.45,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await onToggle();
                    },
                    icon: Icon(
                      isWatched
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                    ),
                    label: Text(
                      isWatched ? 'Watched' : 'Mark episode watched',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isWatched ? Colors.green : Colors.grey[800],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (isWatched)
                    ElevatedButton.icon(
                      onPressed: () async {
                        await onRewatch();
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Log Rewatch'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(height: 14),
                info,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              image,
              const SizedBox(width: 16),
              Expanded(child: info),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _placeholder() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Icon(Icons.live_tv, size: 45, color: Colors.grey),
      ),
    );
  }
}

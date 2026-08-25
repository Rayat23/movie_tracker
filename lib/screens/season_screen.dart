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
          final seasonRating = tracking.getSeasonRating(
            widget.show.id,
            widget.season.seasonNumber,
          );

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
                  seasonRating: seasonRating,
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
                  onRateSeason: () async {
                    final rating = await _showRatingDialog(
                      title: 'Rate ${widget.season.name}',
                      currentRating: seasonRating,
                    );

                    if (rating == null) return;

                    await tracking.setSeasonRating(
                      widget.show.id,
                      widget.season.seasonNumber,
                      rating.toDouble(),
                    );

                    if (!mounted) return;
                    setState(() {});
                    _showMessage(
                      '${widget.season.name} rated $rating/10',
                    );
                  },
                  onRemoveSeasonRating: seasonRating == null
                      ? null
                      : () async {
                          await tracking.removeSeasonRating(
                            widget.show.id,
                            widget.season.seasonNumber,
                          );

                          if (!mounted) return;
                          setState(() {});
                          _showMessage('Season rating removed');
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
              final episodeRating = tracking.getEpisodeRating(
                widget.show.id,
                episode.id,
              );

              return _EpisodeTile(
                episode: episode,
                isWatched: isWatched,
                latestWatchAt: latestWatchAt,
                watchCount: watchCount,
                userRating: episodeRating,
                onToggle: () async {
                  await tracking.toggleEpisodeWatched(
                    widget.show,
                    episode,
                    seasonEpisodeCount: widget.season.episodeCount,
                  );

                  if (!mounted) return;
                  setState(() {});
                },
                onRewatch: () async {
                  await tracking.logEpisodeRewatch(
                    widget.show,
                    episode,
                    seasonEpisodeCount: widget.season.episodeCount,
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
                onRate: () async {
                  final rating = await _showRatingDialog(
                    title: 'Rate E${episode.episodeNumber} • ${episode.name}',
                    currentRating: episodeRating,
                  );

                  if (rating == null) return;

                  await tracking.setEpisodeRating(
                    widget.show.id,
                    episode.id,
                    rating.toDouble(),
                  );

                  if (!mounted) return;
                  setState(() {});
                  _showMessage(
                    'Episode rated $rating/10',
                  );
                },
                onRemoveRating: episodeRating == null
                    ? null
                    : () async {
                        await tracking.removeEpisodeRating(
                          widget.show.id,
                          episode.id,
                        );

                        if (!mounted) return;
                        setState(() {});
                        _showMessage('Episode rating removed');
                      },
              );
            },
          );
        },
      ),
    );
  }

  Future<int?> _showRatingDialog({
    required String title,
    double? currentRating,
  }) async {
    int selectedRating = currentRating?.toInt() ?? 0;

    return showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
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
                        final value = index + 1;

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
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 30,
                          ),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () => Navigator.pop(dialogContext, selectedRating),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
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

class _SeasonProgressCard extends StatelessWidget {
  final int watchedCount;
  final int totalCount;
  final double progress;
  final bool isComplete;
  final double? seasonRating;
  final Future<void> Function() onToggleSeason;
  final Future<void> Function() onRateSeason;
  final Future<void> Function()? onRemoveSeasonRating;

  const _SeasonProgressCard({
    required this.watchedCount,
    required this.totalCount,
    required this.progress,
    required this.isComplete,
    required this.seasonRating,
    required this.onToggleSeason,
    required this.onRateSeason,
    required this.onRemoveSeasonRating,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: isComplete
            ? Border.all(color: Colors.green.withValues(alpha: 0.45))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isComplete ? 'Season complete' : 'Season progress',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isComplete) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.green,
                          ),
                        ],
                      ],
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
              OutlinedButton.icon(
                onPressed: () async {
                  await onRateSeason();
                },
                icon: const Icon(Icons.star, color: Colors.amber),
                label: Text(
                  seasonRating == null
                      ? 'Rate season'
                      : '${seasonRating!.toStringAsFixed(0)}/10',
                ),
              ),
              if (onRemoveSeasonRating != null)
                IconButton(
                  tooltip: 'Remove season rating',
                  onPressed: () async {
                    await onRemoveSeasonRating!();
                  },
                  icon: const Icon(Icons.close, color: Colors.grey),
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
  final double? userRating;
  final Future<void> Function() onToggle;
  final Future<void> Function() onRewatch;
  final Future<void> Function() onRate;
  final Future<void> Function()? onRemoveRating;

  const _EpisodeTile({
    required this.episode,
    required this.isWatched,
    required this.latestWatchAt,
    required this.watchCount,
    required this.userRating,
    required this.onToggle,
    required this.onRewatch,
    required this.onRate,
    required this.onRemoveRating,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'E${episode.episodeNumber} • ${episode.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (userRating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text('${userRating!.toStringAsFixed(0)}/10'),
                        ],
                      ),
                    ),
                ],
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
                  OutlinedButton.icon(
                    onPressed: () async {
                      await onRate();
                    },
                    icon: const Icon(Icons.star_border),
                    label: Text(
                      userRating == null
                          ? 'Rate episode'
                          : 'Change rating',
                    ),
                  ),
                  if (onRemoveRating != null)
                    IconButton(
                      tooltip: 'Remove episode rating',
                      onPressed: () async {
                        await onRemoveRating!();
                      },
                      icon: const Icon(Icons.close, color: Colors.grey),
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

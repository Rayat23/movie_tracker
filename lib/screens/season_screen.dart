import 'package:flutter/material.dart';

import '../models/episode.dart';
import '../models/season.dart';
import '../models/tv_show.dart';
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

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: episodes.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: 14),
            itemBuilder: (context, index) {
              return _EpisodeTile(episode: episodes[index]);
            },
          );
        },
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;

  const _EpisodeTile({required this.episode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(14),
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
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: Colors.grey,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Episode tracking is the next step',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
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

  Widget _placeholder() {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Icon(Icons.live_tv, size: 45, color: Colors.grey),
      ),
    );
  }
}

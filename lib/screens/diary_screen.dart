import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/tv_watch_entry.dart';
import '../services/favorites_service.dart';
import '../services/series_tracking_service.dart';

enum _DiaryFilter { all, movies, tv }

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  _DiaryFilter _filter = _DiaryFilter.all;

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesService.instance;
    final seriesTracking = SeriesTrackingService.instance;
    final records = <_DiaryRecord>[];

    for (final movie in favorites.watched) {
      final dates = favorites.getMovieWatchDates(movie);
      for (int index = 0; index < dates.length; index++) {
        records.add(_DiaryRecord(
          kind: 'Movie',
          title: movie.title,
          subtitle: favorites.getUserRating(movie) == null
              ? 'Movie'
              : 'Movie • Your rating ${favorites.getUserRating(movie)!.toStringAsFixed(0)}/10',
          watchedAt: dates[index],
          imageUrl: movie.posterPath.isEmpty ? null : movie.posterUrl,
          runtimeMinutes: movie.runtimeMinutes > 0 ? movie.runtimeMinutes : null,
          watchNumber: index + 1,
          movie: movie,
        ));
      }
    }

    final groupedTvEvents = <String, List<TvWatchEntry>>{};
    for (final entry in seriesTracking.allWatchEvents) {
      final key = '${entry.showId}:${entry.episodeId}';
      groupedTvEvents.putIfAbsent(key, () => <TvWatchEntry>[]).add(entry);
    }
    for (final events in groupedTvEvents.values) {
      events.sort((a, b) => a.watchedAt.compareTo(b.watchedAt));
      for (int index = 0; index < events.length; index++) {
        final entry = events[index];
        String? imageUrl;
        if (entry.episodeStillPath.isNotEmpty) {
          imageUrl = 'https://image.tmdb.org/t/p/w780${entry.episodeStillPath}';
        } else if (entry.showPosterPath.isNotEmpty) {
          imageUrl = 'https://image.tmdb.org/t/p/w500${entry.showPosterPath}';
        }
        records.add(_DiaryRecord(
          kind: 'TV Episode',
          title: entry.showName,
          subtitle: 'S${entry.seasonNumber.toString().padLeft(2, '0')}E${entry.episodeNumber.toString().padLeft(2, '0')} • ${entry.episodeName}',
          watchedAt: entry.watchedAt,
          imageUrl: imageUrl,
          runtimeMinutes: entry.runtimeMinutes,
          watchNumber: index + 1,
        ));
      }
    }

    records.sort((a, b) => b.watchedAt.compareTo(a.watchedAt));

    final movieCount = records.where((record) => record.kind == 'Movie').length;
    final tvCount = records.where((record) => record.kind == 'TV Episode').length;
    final rewatchCount = records.where((record) => record.isRewatch).length;
    final visibleRecords = records.where((record) {
      switch (_filter) {
        case _DiaryFilter.all:
          return true;
        case _DiaryFilter.movies:
          return record.kind == 'Movie';
        case _DiaryFilter.tv:
          return record.kind == 'TV Episode';
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Diary')),
      body: records.isEmpty
          ? const Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.menu_book_outlined, size: 75, color: Colors.grey),
                SizedBox(height: 16),
                Text('Your diary is empty', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Movies and TV episodes you mark watched will appear here.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
              ]),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _DiarySummaryCard(
                  totalEntries: records.length,
                  movieCount: movieCount,
                  tvCount: tvCount,
                  rewatchCount: rewatchCount,
                ),
                const SizedBox(height: 16),
                _DiaryFilters(
                  selected: _filter,
                  onChanged: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 12),
                Text(
                  _filter == _DiaryFilter.movies
                      ? 'Tap a movie entry to change when you watched it.'
                      : _filter == _DiaryFilter.tv
                          ? 'TV episode date editing is coming in a later safe update.'
                          : 'Tap a movie entry to change when you watched it.',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                if (visibleRecords.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text('No diary entries in this filter.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ..._buildDiaryWidgets(visibleRecords),
              ],
            ),
    );
  }

  List<Widget> _buildDiaryWidgets(List<_DiaryRecord> records) {
    final widgets = <Widget>[];
    DateTime? previousDate;
    for (final record in records) {
      if (previousDate == null || !_sameDay(previousDate, record.watchedAt)) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Text(_formatDay(record.watchedAt), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ));
      }
      widgets.add(_DiaryTile(record: record, onEdit: record.movie == null ? null : () => _editMovieWatchTime(record)));
      widgets.add(const SizedBox(height: 10));
      previousDate = record.watchedAt;
    }
    return widgets;
  }

  Future<void> _editMovieWatchTime(_DiaryRecord record) async {
    final movie = record.movie;
    if (movie == null) return;
    final date = await showDatePicker(
      context: context,
      initialDate: record.watchedAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'When did you watch it?',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(record.watchedAt),
      helpText: 'Choose watch time',
    );
    if (time == null || !mounted) return;
    final replacement = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (replacement.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Watch time cannot be in the future.')));
      return;
    }
    await FavoritesService.instance.updateMovieWatchDate(movie, record.watchedAt, replacement);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diary time updated.')));
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDay(DateTime date) {
    const months = ['January','February','March','April','May','June','July','August','September','October','November','December'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _DiaryFilters extends StatelessWidget {
  final _DiaryFilter selected;
  final ValueChanged<_DiaryFilter> onChanged;

  const _DiaryFilters({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('All'),
          selected: selected == _DiaryFilter.all,
          onSelected: (_) => onChanged(_DiaryFilter.all),
        ),
        ChoiceChip(
          label: const Text('Movies'),
          selected: selected == _DiaryFilter.movies,
          onSelected: (_) => onChanged(_DiaryFilter.movies),
        ),
        ChoiceChip(
          label: const Text('TV'),
          selected: selected == _DiaryFilter.tv,
          onSelected: (_) => onChanged(_DiaryFilter.tv),
        ),
      ],
    );
  }
}

class _DiarySummaryCard extends StatelessWidget {
  final int totalEntries;
  final int movieCount;
  final int tvCount;
  final int rewatchCount;

  const _DiarySummaryCard({
    required this.totalEntries,
    required this.movieCount,
    required this.tvCount,
    required this.rewatchCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(16)),
      child: Wrap(spacing: 28, runSpacing: 14, children: [
        _summaryItem(Icons.menu_book, '$totalEntries', 'Entries', Colors.redAccent),
        _summaryItem(Icons.movie_outlined, '$movieCount', 'Movies', Colors.orangeAccent),
        _summaryItem(Icons.tv_outlined, '$tvCount', 'TV episodes', Colors.lightBlueAccent),
        _summaryItem(Icons.replay, '$rewatchCount', 'Rewatches', Colors.deepPurpleAccent),
      ]),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 26),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ]),
    ]);
  }
}

class _DiaryTile extends StatelessWidget {
  final _DiaryRecord record;
  final VoidCallback? onEdit;
  const _DiaryTile({required this.record, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(14),
            border: record.isRewatch ? Border.all(color: Colors.deepPurpleAccent.withValues(alpha: 0.45)) : null,
          ),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: SizedBox(
                width: 90,
                height: 90,
                child: record.imageUrl == null
                    ? _placeholder()
                    : Image.network(record.imageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => _placeholder()),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(record.kind == 'Movie' ? Icons.movie : Icons.tv, size: 17, color: record.kind == 'Movie' ? Colors.redAccent : Colors.lightBlueAccent),
                  const SizedBox(width: 6),
                  Text(record.kind, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
                if (record.isRewatch)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(20)),
                    child: Text('Rewatch #${record.watchNumber}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepPurpleAccent)),
                  ),
              ]),
              const SizedBox(height: 5),
              Text(record.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(record.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 7),
              Wrap(spacing: 12, runSpacing: 5, children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.access_time, size: 15, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(_formatTime(record.watchedAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
                if (record.runtimeMinutes != null && record.runtimeMinutes! > 0)
                  Text(_formatRuntime(record.runtimeMinutes!), style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ]),
            ])),
            if (onEdit != null) const Padding(padding: EdgeInsets.only(right: 8), child: Icon(Icons.edit_calendar_outlined, size: 19, color: Colors.white54)),
            Icon(record.isRewatch ? Icons.replay : Icons.check_circle, color: record.isRewatch ? Colors.deepPurpleAccent : Colors.green),
          ]),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
  }

  String _formatRuntime(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) return '$remainingMinutes min';
    if (remainingMinutes == 0) return '${hours}h';
    return '${hours}h ${remainingMinutes}m';
  }

  Widget _placeholder() => Container(color: Colors.black26, child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.grey, size: 38)));
}

class _DiaryRecord {
  final String kind;
  final String title;
  final String subtitle;
  final DateTime watchedAt;
  final String? imageUrl;
  final int? runtimeMinutes;
  final int watchNumber;
  final Movie? movie;

  const _DiaryRecord({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.watchedAt,
    required this.imageUrl,
    required this.runtimeMinutes,
    required this.watchNumber,
    this.movie,
  });

  bool get isRewatch => watchNumber > 1;
}

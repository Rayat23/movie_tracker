import 'tv_watch_entry.dart';

/// A watch event with its original storage identity, independent of its date.
class TvDiaryEvent {
  const TvDiaryEvent({
    required this.entry,
    required this.isRewatch,
    required this.watchNumber,
  });

  final TvWatchEntry entry;
  final bool isRewatch;
  final int watchNumber;
}

/// Rewatch identity must come from the source collection, not date order.
///
/// A user can backdate a rewatch to before the first watch. Inferring
/// "rewatch" from chronological position would then edit the wrong
/// SharedPreferences collection and display the wrong badge.
List<TvDiaryEvent> buildTvDiaryEvents({
  required Iterable<TvWatchEntry> watchedEpisodes,
  required Iterable<TvWatchEntry> rewatchEpisodes,
}) {
  final grouped = <String, List<MapEntry<TvWatchEntry, bool>>>{};

  void add(TvWatchEntry entry, bool isRewatch) {
    final key = '${entry.showId}:${entry.episodeId}';
    grouped.putIfAbsent(key, () => []).add(MapEntry(entry, isRewatch));
  }

  for (final entry in watchedEpisodes) {
    add(entry, false);
  }
  for (final entry in rewatchEpisodes) {
    add(entry, true);
  }

  final result = <TvDiaryEvent>[];
  for (final events in grouped.values) {
    events.sort((a, b) => a.key.watchedAt.compareTo(b.key.watchedAt));
    var rewatchCount = 0;
    for (final event in events) {
      if (event.value) rewatchCount++;
      result.add(TvDiaryEvent(
        entry: event.key,
        isRewatch: event.value,
        watchNumber: event.value ? rewatchCount + 1 : 1,
      ));
    }
  }
  return result;
}

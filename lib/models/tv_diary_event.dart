import 'tv_watch_entry.dart';

/// A watch event with its original storage identity, independent of its date.
class TvDiaryEvent {
  const TvDiaryEvent({
    required this.entry,
    required this.isRewatch,
    required this.watchNumber,
    required this.sourceIndex,
  });

  final TvWatchEntry entry;
  final bool isRewatch;
  final int watchNumber;
  /// Index in the original persisted watch or rewatch list.
  final int sourceIndex;
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
  final grouped = <String, List<_TvEventSource>>{};

  void add(TvWatchEntry entry, bool isRewatch, int sourceIndex) {
    final key = '${entry.showId}:${entry.episodeId}';
    grouped.putIfAbsent(key, () => []).add(
      _TvEventSource(entry, isRewatch, sourceIndex),
    );
  }

  var sourceIndex = 0;
  for (final entry in watchedEpisodes) {
    add(entry, false, sourceIndex++);
  }
  sourceIndex = 0;
  for (final entry in rewatchEpisodes) {
    add(entry, true, sourceIndex++);
  }

  final result = <TvDiaryEvent>[];
  for (final events in grouped.values) {
    events.sort((a, b) => a.entry.watchedAt.compareTo(b.entry.watchedAt));
    var rewatchCount = 0;
    for (final event in events) {
      if (event.isRewatch) rewatchCount++;
      result.add(TvDiaryEvent(
        entry: event.entry,
        isRewatch: event.isRewatch,
        watchNumber: event.isRewatch ? rewatchCount + 1 : 1,
        sourceIndex: event.sourceIndex,
      ));
    }
  }
  return result;
}

class _TvEventSource {
  const _TvEventSource(this.entry, this.isRewatch, this.sourceIndex);

  final TvWatchEntry entry;
  final bool isRewatch;
  final int sourceIndex;
}

/// Counts calendar days with at least one movie or TV watch event.
///
/// Timestamps may be stored as UTC or local times. Grouping in local time
/// keeps the result consistent with the dates shown to the user in the diary.
/// Multiple watches on the same day count as one active watch day.
int countActiveWatchDays(Iterable<DateTime> watchDates) {
  final days = <String>{};
  for (final timestamp in watchDates) {
    final local = timestamp.toLocal();
    days.add('${local.year}-${local.month}-${local.day}');
  }
  return days.length;
}

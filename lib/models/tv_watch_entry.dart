class TvWatchEntry {
  final int showId;
  final String showName;
  final String showPosterPath;
  final int seasonNumber;
  final int episodeId;
  final int episodeNumber;
  final String episodeName;
  final String episodeStillPath;
  final int runtimeMinutes;
  final DateTime watchedAt;

  const TvWatchEntry({
    required this.showId,
    required this.showName,
    required this.showPosterPath,
    required this.seasonNumber,
    required this.episodeId,
    required this.episodeNumber,
    required this.episodeName,
    required this.episodeStillPath,
    required this.runtimeMinutes,
    required this.watchedAt,
  });

  factory TvWatchEntry.fromJson(Map<String, dynamic> json) {
    return TvWatchEntry(
      showId: json['show_id'] as int? ?? 0,
      showName: json['show_name'] as String? ?? 'Unknown series',
      showPosterPath: json['show_poster_path'] as String? ?? '',
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeId: json['episode_id'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      episodeName: json['episode_name'] as String? ?? 'Episode',
      episodeStillPath: json['episode_still_path'] as String? ?? '',
      runtimeMinutes: json['runtime_minutes'] as int? ?? 0,
      watchedAt:
          DateTime.tryParse(json['watched_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'show_id': showId,
      'show_name': showName,
      'show_poster_path': showPosterPath,
      'season_number': seasonNumber,
      'episode_id': episodeId,
      'episode_number': episodeNumber,
      'episode_name': episodeName,
      'episode_still_path': episodeStillPath,
      'runtime_minutes': runtimeMinutes,
      'watched_at': watchedAt.toIso8601String(),
    };
  }
}

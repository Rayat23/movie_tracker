class Episode {
  final int id;
  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final String overview;
  final String stillPath;
  final String airDate;
  final int runtimeMinutes;

  const Episode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    required this.overview,
    required this.stillPath,
    required this.airDate,
    required this.runtimeMinutes,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      episodeNumber: json['episode_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Episode',
      overview: json['overview'] as String? ?? '',
      stillPath: json['still_path'] as String? ?? '',
      airDate: json['air_date'] as String? ?? '',
      runtimeMinutes: json['runtime'] as int? ?? 0,
    );
  }

  String get stillUrl => 'https://image.tmdb.org/t/p/w780$stillPath';
}

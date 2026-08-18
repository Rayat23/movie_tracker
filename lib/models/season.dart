class Season {
  final int id;
  final int seasonNumber;
  final String name;
  final String overview;
  final String posterPath;
  final String airDate;
  final int episodeCount;

  const Season({
    required this.id,
    required this.seasonNumber,
    required this.name,
    required this.overview,
    required this.posterPath,
    required this.airDate,
    required this.episodeCount,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      id: json['id'] as int? ?? 0,
      seasonNumber: json['season_number'] as int? ?? 0,
      name: json['name'] as String? ?? 'Season',
      overview: json['overview'] as String? ?? '',
      posterPath: json['poster_path'] as String? ?? '',
      airDate: json['air_date'] as String? ?? '',
      episodeCount: json['episode_count'] as int? ?? 0,
    );
  }

  String get posterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';
}

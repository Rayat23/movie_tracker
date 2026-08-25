class TvShow {
  final int id;
  final String name;
  final String posterPath;
  final String backdropPath;
  final double rating;
  final String firstAirDate;
  final String overview;
  final int numberOfSeasons;
  final int numberOfEpisodes;

  const TvShow({
    required this.id,
    required this.name,
    required this.posterPath,
    required this.backdropPath,
    required this.rating,
    required this.firstAirDate,
    required this.overview,
    this.numberOfSeasons = 0,
    this.numberOfEpisodes = 0,
  });

  factory TvShow.fromJson(Map<String, dynamic> json) {
    return TvShow(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown series',
      posterPath: json['poster_path'] as String? ?? '',
      backdropPath: json['backdrop_path'] as String? ?? '',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      firstAirDate: json['first_air_date'] as String? ?? '',
      overview: json['overview'] as String? ?? '',
      numberOfSeasons: json['number_of_seasons'] as int? ?? 0,
      numberOfEpisodes: json['number_of_episodes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': rating,
      'first_air_date': firstAirDate,
      'overview': overview,
      'number_of_seasons': numberOfSeasons,
      'number_of_episodes': numberOfEpisodes,
    };
  }

  String get posterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';

  String get backdropUrl => 'https://image.tmdb.org/t/p/original$backdropPath';
}

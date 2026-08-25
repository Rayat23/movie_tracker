class Movie {
  final int id;
  final String title;
  final String posterPath;
  final String backdropPath;
  final double rating;
  final String releaseDate;
  final String overview;
  final int runtimeMinutes;

  const Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    this.backdropPath = '',
    required this.rating,
    required this.releaseDate,
    required this.overview,
    this.runtimeMinutes = 0,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int? ?? 0,
      title:
          json['title'] as String? ??
          json['name'] as String? ??
          'Unknown title',
      posterPath: json['poster_path'] as String? ?? '',
      backdropPath: json['backdrop_path'] as String? ?? '',
      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      releaseDate:
          json['release_date'] as String? ??
          json['first_air_date'] as String? ??
          '',
      overview: json['overview'] as String? ?? '',
      runtimeMinutes: json['runtime'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'backdrop_path': backdropPath,
      'vote_average': rating,
      'release_date': releaseDate,
      'overview': overview,
      'runtime': runtimeMinutes,
    };
  }

  String get posterUrl => 'https://image.tmdb.org/t/p/w500$posterPath';

  String get backdropUrl =>
      'https://image.tmdb.org/t/p/original$backdropPath';
}

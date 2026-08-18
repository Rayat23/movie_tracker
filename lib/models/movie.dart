class Movie {
  final int id;
  final String title;
  final String posterPath;
  final double rating;
  final String releaseDate;
  final String overview;

  const Movie({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.rating,
    required this.releaseDate,
    required this.overview,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'] as int? ?? 0,

      title:
          json['title'] as String? ??
          json['name'] as String? ??
          'Unknown title',

      posterPath: json['poster_path'] as String? ?? '',

      rating: (json['vote_average'] as num?)?.toDouble() ?? 0.0,

      releaseDate:
          json['release_date'] as String? ??
          json['first_air_date'] as String? ??
          '',

      overview: json['overview'] as String? ?? '',
    );
  }

  // Converts Movie into a map so it can be saved.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'poster_path': posterPath,
      'vote_average': rating,
      'release_date': releaseDate,
      'overview': overview,
    };
  }

  String get posterUrl {
    return 'https://image.tmdb.org/t/p/w500$posterPath';
  }
}

import 'package:flutter_test/flutter_test.dart';

import 'package:movie_tracker/models/episode.dart';
import 'package:movie_tracker/models/movie.dart';
import 'package:movie_tracker/models/tv_show.dart';

void main() {
  test('Movie parses TMDB data including runtime', () {
    final movie = Movie.fromJson({
      'id': 1,
      'title': 'Example Movie',
      'poster_path': '/poster.jpg',
      'vote_average': 8.2,
      'release_date': '2026-01-01',
      'overview': 'Example overview',
      'runtime': 149,
    });

    expect(movie.id, 1);
    expect(movie.title, 'Example Movie');
    expect(movie.rating, 8.2);
    expect(movie.runtimeMinutes, 149);
    expect(movie.toJson()['runtime'], 149);
  });

  test('TV show and episode parse TMDB data', () {
    final show = TvShow.fromJson({
      'id': 10,
      'name': 'Example Series',
      'poster_path': '/show.jpg',
      'vote_average': 9.0,
      'first_air_date': '2025-01-01',
      'number_of_seasons': 2,
      'number_of_episodes': 20,
    });

    final episode = Episode.fromJson({
      'id': 100,
      'season_number': 1,
      'episode_number': 3,
      'name': 'Episode Three',
      'runtime': 48,
    });

    expect(show.name, 'Example Series');
    expect(show.numberOfEpisodes, 20);
    expect(episode.episodeNumber, 3);
    expect(episode.runtimeMinutes, 48);
  });
}

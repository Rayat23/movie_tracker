import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/tv_show.dart';
import '../services/movie_service.dart';
import '../services/tv_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/tv_show_card.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;
  int homeCategoryIndex = 0;

  final MovieService movieService = MovieService();
  final TvService tvService = TvService();

  late Future<List<Movie>> trendingMovies;
  late Future<List<Movie>> popularMovies;

  late Future<List<TvShow>> trendingTvShows;
  late Future<List<TvShow>> popularTvShows;
  late Future<List<TvShow>> topRatedTvShows;

  @override
  void initState() {
    super.initState();

    trendingMovies = movieService.fetchTrendingMovies();
    popularMovies = movieService.fetchPopularMovies();

    trendingTvShows = tvService.fetchTrendingTvShows();
    popularTvShows = tvService.fetchPopularTvShows();
    topRatedTvShows = tvService.fetchTopRatedTvShows();
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget horizontalMovieList(Future<List<Movie>> future) {
    return SizedBox(
      height: 310,
      child: FutureBuilder<List<Movie>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final movies = snapshot.data ?? [];

          if (movies.isEmpty) {
            return const Center(child: Text('No movies found'));
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return MovieCard(movie: movies[index]);
            },
          );
        },
      ),
    );
  }

  Widget horizontalTvList(Future<List<TvShow>> future) {
    return SizedBox(
      height: 310,
      child: FutureBuilder<List<TvShow>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final shows = snapshot.data ?? [];

          if (shows.isEmpty) {
            return const Center(child: Text('No TV series found'));
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shows.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return TvShowCard(show: shows[index]);
            },
          );
        },
      ),
    );
  }

  Widget categoryButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = homeCategoryIndex == index;

    if (selected) {
      return Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              homeCategoryIndex = index;
            });
          },
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      );
    }

    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            homeCategoryIndex = index;
          });
        },
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  List<Widget> movieHomeContent() {
    return [
      sectionTitle('Trending Movies'),
      horizontalMovieList(trendingMovies),
      sectionTitle('Popular Movies'),
      horizontalMovieList(popularMovies),
    ];
  }

  List<Widget> tvHomeContent() {
    return [
      sectionTitle('Trending TV Series'),
      horizontalTvList(trendingTvShows),
      sectionTitle('Popular TV Series'),
      horizontalTvList(popularTvShows),
      sectionTitle('Top Rated TV Series'),
      horizontalTvList(topRatedTvShows),
    ];
  }

  Widget homePage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          TextField(
            readOnly: true,
            onTap: () {
              setState(() {
                selectedIndex = 1;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search movies or TV shows...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              categoryButton(
                index: 0,
                icon: Icons.movie_outlined,
                label: 'Movies',
              ),
              const SizedBox(width: 12),
              categoryButton(
                index: 1,
                icon: Icons.tv,
                label: 'TV Series',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(homeCategoryIndex == 0
              ? movieHomeContent()
              : tvHomeContent()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎬 Movie Tracker'),
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [
          homePage(),
          const SearchScreen(),
          LibraryScreen(key: ValueKey(selectedIndex)),
          ProfileScreen(key: ValueKey(selectedIndex)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

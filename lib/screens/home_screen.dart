import 'profile_screen.dart';
import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_card.dart';
import 'library_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  final MovieService movieService = MovieService();

  late Future<List<Movie>> trendingMovies;
  late Future<List<Movie>> popularMovies;
  late Future<List<Movie>> popularTvShows;

  @override
  void initState() {
    super.initState();

    trendingMovies = movieService.fetchTrendingMovies();
    popularMovies = movieService.fetchPopularMovies();
    popularTvShows = movieService.fetchPopularTvShows();
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget horizontalList(Future<List<Movie>> future) {
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

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No movies found'));
          }

          final movies = snapshot.data!;

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) {
              return const SizedBox(width: 12);
            },
            itemBuilder: (context, index) {
              return MovieCard(movie: movies[index]);
            },
          );
        },
      ),
    );
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

          const SizedBox(height: 20),

          sectionTitle('Trending Movies'),
          horizontalList(trendingMovies),

          sectionTitle('Popular Movies'),
          horizontalList(popularMovies),

          sectionTitle('Popular TV Shows'),
          horizontalList(popularTvShows),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎬 Movie Tracker')),

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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Library',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

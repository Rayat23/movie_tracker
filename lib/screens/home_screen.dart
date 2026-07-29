import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_card.dart';
import 'favorites_screen.dart';
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

  final List<String> pages = ["Home", "Search", "Favorites", "Profile"];

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

  // Now takes a future, so we can reuse it for every row.
  Widget horizontalList(Future<List<Movie>> future) {
    return SizedBox(
      height: 280,
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
            return const Center(child: Text("No movies found"));
          }

          final movies = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
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
            decoration: InputDecoration(
              hintText: "Search movies or TV shows...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 20),

          sectionTitle("Trending Movies"),
          horizontalList(trendingMovies),

          sectionTitle("Popular Movies"),
          horizontalList(popularMovies),

          sectionTitle("Popular TV Shows"),
          horizontalList(popularTvShows),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🎬 Movie Tracker")),

      body: IndexedStack(
        index: selectedIndex,
        children: [
          homePage(),
          const SearchScreen(),
          FavoritesScreen(key: ValueKey(selectedIndex)),
          Center(
            child: Text(
              pages[3],
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

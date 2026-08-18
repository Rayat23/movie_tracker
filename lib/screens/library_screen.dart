import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/favorites_service.dart';
import '../widgets/movie_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final FavoritesService favorites = FavoritesService.instance;

  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.black,
          child: TabBar(
            controller: tabController,
            indicatorColor: Colors.red,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
              Tab(icon: Icon(Icons.bookmark), text: 'Watchlist'),
              Tab(icon: Icon(Icons.check_circle), text: 'Watched'),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              // -----------------------------
              // FAVORITES
              // -----------------------------
              _buildMovieList(
                movies: favorites.favorites,
                emptyIcon: Icons.favorite_border,
                emptyTitle: 'No favorites yet',
                emptyMessage: 'Movies you favorite will appear here.',
              ),

              // -----------------------------
              // WATCHLIST
              // -----------------------------
              _buildMovieList(
                movies: favorites.watchlist,
                emptyIcon: Icons.bookmark_border,
                emptyTitle: 'Your watchlist is empty',
                emptyMessage: 'Add movies you want to watch later.',
              ),

              // -----------------------------
              // WATCHED
              // -----------------------------
              _buildMovieList(
                movies: favorites.watched,
                emptyIcon: Icons.check_circle_outline,
                emptyTitle: 'No watched movies yet',
                emptyMessage: 'Movies you mark as watched will appear here.',
                showUserRating: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovieList({
    required List<Movie> movies,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
    bool showUserRating = false,
  }) {
    // -----------------------------
    // EMPTY STATE
    // -----------------------------
    if (movies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 75, color: Colors.grey),

            const SizedBox(height: 16),

            Text(
              emptyTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // -----------------------------
    // MOVIE GRID
    // -----------------------------
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,

          // Watched cards need slightly more height
          // because we show the user's rating too.
          mainAxisExtent: showUserRating ? 335 : 315,

          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return MovieCard(
            movie: movies[index],

            // Only Watched tab will show
            // the user's personal rating.
            showUserRating: showUserRating,

            // Refresh Library after returning
            // from the Details page.
            onReturn: () {
              if (!mounted) return;

              setState(() {});
            },
          );
        },
      ),
    );
  }
}

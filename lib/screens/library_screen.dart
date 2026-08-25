import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/tv_show.dart';
import '../services/favorites_service.dart';
import '../services/series_tracking_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/tv_show_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final FavoritesService favorites = FavoritesService.instance;
  final SeriesTrackingService seriesTracking = SeriesTrackingService.instance;

  late TabController tabController;
  int mediaTypeIndex = 0;

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
    final isMovies = mediaTypeIndex == 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              _mediaButton(
                index: 0,
                icon: Icons.movie_outlined,
                label: 'Movies',
              ),
              const SizedBox(width: 12),
              _mediaButton(
                index: 1,
                icon: Icons.tv,
                label: 'TV Series',
              ),
            ],
          ),
        ),
        Container(
          color: Colors.black,
          child: TabBar(
            controller: tabController,
            indicatorColor: Colors.red,
            labelColor: Colors.red,
            unselectedLabelColor: Colors.grey,
            tabs: [
              const Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
              const Tab(icon: Icon(Icons.bookmark), text: 'Watchlist'),
              Tab(
                icon: Icon(
                  isMovies ? Icons.check_circle : Icons.play_circle_outline,
                ),
                text: isMovies ? 'Watched' : 'Started',
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: isMovies ? _movieTabs() : _tvTabs(),
          ),
        ),
      ],
    );
  }

  Widget _mediaButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = mediaTypeIndex == index;

    if (selected) {
      return Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            setState(() {
              mediaTypeIndex = index;
            });
          },
          icon: Icon(icon),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }

    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            mediaTypeIndex = index;
          });
        },
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white70,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  List<Widget> _movieTabs() {
    return [
      _buildMovieList(
        movies: favorites.favorites,
        emptyIcon: Icons.favorite_border,
        emptyTitle: 'No movie favorites yet',
        emptyMessage: 'Movies you favorite will appear here.',
      ),
      _buildMovieList(
        movies: favorites.watchlist,
        emptyIcon: Icons.bookmark_border,
        emptyTitle: 'Your movie watchlist is empty',
        emptyMessage: 'Add movies you want to watch later.',
      ),
      _buildMovieList(
        movies: favorites.watched,
        emptyIcon: Icons.check_circle_outline,
        emptyTitle: 'No watched movies yet',
        emptyMessage: 'Movies you mark as watched will appear here.',
        showUserRating: true,
      ),
    ];
  }

  List<Widget> _tvTabs() {
    return [
      _buildTvList(
        shows: seriesTracking.favorites,
        emptyIcon: Icons.favorite_border,
        emptyTitle: 'No TV favorites yet',
        emptyMessage: 'Series you favorite will appear here.',
        showUserRating: true,
      ),
      _buildTvList(
        shows: seriesTracking.watchlist,
        emptyIcon: Icons.bookmark_border,
        emptyTitle: 'Your TV watchlist is empty',
        emptyMessage: 'Add series you want to watch later.',
        showUserRating: true,
      ),
      _buildTvList(
        shows: seriesTracking.startedShows,
        emptyIcon: Icons.play_circle_outline,
        emptyTitle: 'No started series yet',
        emptyMessage: 'Series appear here after you watch an episode.',
        showUserRating: true,
      ),
    ];
  }

  Widget _buildMovieList({
    required List<Movie> movies,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
    bool showUserRating = false,
  }) {
    if (movies.isEmpty) {
      return _emptyState(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: showUserRating ? 335 : 315,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        itemCount: movies.length,
        itemBuilder: (context, index) {
          return MovieCard(
            movie: movies[index],
            showUserRating: showUserRating,
            onReturn: _refresh,
          );
        },
      ),
    );
  }

  Widget _buildTvList({
    required List<TvShow> shows,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptyMessage,
    bool showUserRating = false,
  }) {
    if (shows.isEmpty) {
      return _emptyState(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: showUserRating ? 335 : 315,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        itemCount: shows.length,
        itemBuilder: (context, index) {
          return TvShowCard(
            show: shows[index],
            showUserRating: showUserRating,
            onReturn: _refresh,
          );
        },
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 75, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
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
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }
}

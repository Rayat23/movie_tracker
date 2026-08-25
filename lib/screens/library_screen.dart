import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/tv_show.dart';
import '../services/favorites_service.dart';
import '../services/profile_service.dart';
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
  final ProfileService profiles = ProfileService.instance;

  late final TabController tabController;
  int mediaTypeIndex = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 3, vsync: this);
    tabController.addListener(_refresh);
  }

  @override
  void dispose() {
    tabController.removeListener(_refresh);
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMovies = mediaTypeIndex == 0;
    final profile = profiles.activeProfile;

    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _pageHeader(profile.name),
                          const SizedBox(height: 20),
                          _summaryStrip(),
                          const SizedBox(height: 22),
                          _mediaSelector(),
                          const SizedBox(height: 14),
                          _tabBar(isMovies),
                          const SizedBox(height: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                      child: TabBarView(
                        controller: tabController,
                        children: isMovies ? _movieTabs() : _tvTabs(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pageHeader(String profileName) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 650;

        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Library',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '$profileName’s private collection of favorites, watchlists, and watch history.',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        );

        final badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 17,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 7),
              const Text(
                'Profile-only data',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), badge],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: title),
            const SizedBox(width: 18),
            badge,
          ],
        );
      },
    );
  }

  Widget _summaryStrip() {
    final movieSaved = favorites.favorites.length + favorites.watchlist.length;
    final tvSaved = seriesTracking.favorites.length + seriesTracking.watchlist.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard(
              Icons.bookmarks_rounded,
              '${movieSaved + tvSaved}',
              'Saved titles',
              Colors.redAccent,
              constraints.maxWidth,
            ),
            _summaryCard(
              Icons.movie_rounded,
              '${favorites.watched.length}',
              'Movies watched',
              Colors.greenAccent,
              constraints.maxWidth,
            ),
            _summaryCard(
              Icons.play_circle_fill_rounded,
              '${seriesTracking.totalWatchedEpisodes}',
              'Episodes watched',
              Colors.lightBlueAccent,
              constraints.maxWidth,
            ),
            _summaryCard(
              Icons.task_alt_rounded,
              '${seriesTracking.completedSeriesCount}',
              'Series completed',
              Colors.tealAccent,
              constraints.maxWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(
    IconData icon,
    String value,
    String label,
    Color color,
    double availableWidth,
  ) {
    final compact = availableWidth < 700;

    return Container(
      width: compact ? (availableWidth - 12) / 2 : 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mediaSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F15),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _mediaButton(0, Icons.movie_outlined, 'Movies'),
          const SizedBox(width: 6),
          _mediaButton(1, Icons.tv_outlined, 'TV Series'),
        ],
      ),
    );
  }

  Widget _mediaButton(int index, IconData icon, String label) {
    final selected = mediaTypeIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            mediaTypeIndex = index;
            tabController.index = 0;
          });
        },
        borderRadius: BorderRadius.circular(13),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBar(bool isMovies) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: TabBar(
        controller: tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        tabs: [
          const Tab(icon: Icon(Icons.favorite_outline), text: 'Favorites'),
          const Tab(icon: Icon(Icons.bookmark_outline), text: 'Watchlist'),
          Tab(
            icon: Icon(
              isMovies ? Icons.check_circle_outline : Icons.play_circle_outline,
            ),
            text: isMovies ? 'Watched' : 'Started',
          ),
        ],
      ),
    );
  }

  List<Widget> _movieTabs() {
    return [
      _buildMovieList(
        movies: favorites.favorites,
        emptyIcon: Icons.favorite_border_rounded,
        emptyTitle: 'No favorite movies yet',
        emptyMessage: 'Tap the heart on a movie to build your favorites collection.',
      ),
      _buildMovieList(
        movies: favorites.watchlist,
        emptyIcon: Icons.bookmark_border_rounded,
        emptyTitle: 'Your movie watchlist is empty',
        emptyMessage: 'Save movies here when you want to watch them later.',
      ),
      _buildMovieList(
        movies: favorites.watched,
        emptyIcon: Icons.check_circle_outline_rounded,
        emptyTitle: 'No watched movies yet',
        emptyMessage: 'Movies you mark watched will appear here with your ratings.',
        showUserRating: true,
      ),
    ];
  }

  List<Widget> _tvTabs() {
    return [
      _buildTvList(
        shows: seriesTracking.favorites,
        emptyIcon: Icons.favorite_border_rounded,
        emptyTitle: 'No favorite series yet',
        emptyMessage: 'Favorite a series and it will stay in this collection.',
        showUserRating: true,
      ),
      _buildTvList(
        shows: seriesTracking.watchlist,
        emptyIcon: Icons.bookmark_border_rounded,
        emptyTitle: 'Your TV watchlist is empty',
        emptyMessage: 'Save series you want to start later.',
        showUserRating: true,
      ),
      _buildTvList(
        shows: seriesTracking.startedShows,
        emptyIcon: Icons.play_circle_outline_rounded,
        emptyTitle: 'No started series yet',
        emptyMessage: 'A series appears here as soon as you watch its first episode.',
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

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 18),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 205,
        mainAxisExtent: showUserRating ? 345 : 325,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: movies.length,
      itemBuilder: (context, index) {
        return MovieCard(
          movie: movies[index],
          showUserRating: showUserRating,
          onReturn: _refresh,
        );
      },
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

    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 18),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 205,
        mainAxisExtent: showUserRating ? 345 : 325,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: shows.length,
      itemBuilder: (context, index) {
        return TvShowCard(
          show: shows[index],
          showUserRating: showUserRating,
          onReturn: _refresh,
        );
      },
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 42),
        decoration: BoxDecoration(
          color: const Color(0xFF11131A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: Colors.white38),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
  }
}

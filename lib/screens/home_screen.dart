import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/tv_show.dart';
import '../services/favorites_service.dart';
import '../services/movie_service.dart';
import '../services/profile_service.dart';
import '../services/series_tracking_service.dart';
import '../services/tv_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/tv_show_card.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'profiles_screen.dart';
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
  final ProfileService profiles = ProfileService.instance;
  final FavoritesService favorites = FavoritesService.instance;
  final SeriesTrackingService seriesTracking = SeriesTrackingService.instance;

  late Future<List<Movie>> trendingMovies;
  late Future<List<Movie>> popularMovies;
  late Future<List<TvShow>> trendingTvShows;
  late Future<List<TvShow>> popularTvShows;
  late Future<List<TvShow>> topRatedTvShows;

  static const List<Color> avatarColors = [
    Color(0xFFE53935),
    Color(0xFF7E57C2),
    Color(0xFF42A5F5),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFFEC407A),
    Color(0xFF66BB6A),
    Color(0xFF78909C),
  ];

  @override
  void initState() {
    super.initState();
    trendingMovies = movieService.fetchTrendingMovies();
    popularMovies = movieService.fetchPopularMovies();
    trendingTvShows = tvService.fetchTrendingTvShows();
    popularTvShows = tvService.fetchPopularTvShows();
    topRatedTvShows = tvService.fetchTopRatedTvShows();
  }

  @override
  Widget build(BuildContext context) {
    final profile = profiles.activeProfile;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.movie_filter_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Movie Tracker',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Movies • Series • Diary',
                  style: TextStyle(fontSize: 10, color: Colors.white38),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: _openProfiles,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: avatarColors[
                              profile.avatarIndex % avatarColors.length]
                          .withValues(alpha: 0.2),
                      child: Text(
                        profile.initials,
                        style: TextStyle(
                          color: avatarColors[
                              profile.avatarIndex % avatarColors.length],
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: Text(
                        profile.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more, size: 18, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          final content = _contentStack();

          if (!isDesktop) {
            return content;
          }

          return Row(
            children: [
              Container(
                width: 208,
                decoration: const BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.white10)),
                ),
                child: NavigationRail(
                  extended: true,
                  minExtendedWidth: 208,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.none,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: Text('Home'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.search_outlined),
                      selectedIcon: Icon(Icons.search_rounded),
                      label: Text('Search'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.video_library_outlined),
                      selectedIcon: Icon(Icons.video_library_rounded),
                      label: Text('Library'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: Text('Profile'),
                    ),
                  ],
                ),
              ),
              Expanded(child: content),
            ],
          );
        },
      ),
      bottomNavigationBar: MediaQuery.sizeOf(context).width < 900
          ? NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search_outlined),
                  selectedIcon: Icon(Icons.search_rounded),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.video_library_outlined),
                  selectedIcon: Icon(Icons.video_library_rounded),
                  label: 'Library',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            )
          : null,
    );
  }

  Widget _contentStack() {
    final profileId = profiles.activeProfile.id;

    return IndexedStack(
      index: selectedIndex,
      children: [
        _homePage(),
        const SearchScreen(),
        LibraryScreen(key: ValueKey('library-$profileId')),
        ProfileScreen(key: ValueKey('profile-$profileId')),
      ],
    );
  }

  Widget _homePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(),
              const SizedBox(height: 24),
              TextField(
                readOnly: true,
                onTap: () {
                  setState(() {
                    selectedIndex = 1;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search movies, series, cast and more...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 20),
              _categorySelector(),
              const SizedBox(height: 18),
              ...(homeCategoryIndex == 0
                  ? _movieHomeContent()
                  : _tvHomeContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    final profile = profiles.activeProfile;
    final movieWatchlist = favorites.watchlist.length;
    final tvWatchlist = seriesTracking.watchlist.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
            const Color(0xFF161827),
            const Color(0xFF0E1017),
          ],
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;

          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, ${profile.name}',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Track what you watch, build your personal diary, and keep every movie and episode organized.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedIndex = 2;
                      });
                    },
                    icon: const Icon(Icons.video_library_rounded),
                    label: const Text('Open Library'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        selectedIndex = 3;
                      });
                    },
                    icon: const Icon(Icons.insights_rounded),
                    label: const Text('View Stats'),
                  ),
                ],
              ),
            ],
          );

          final stats = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _miniStat(
                Icons.movie_rounded,
                '${favorites.watched.length}',
                'Movies watched',
              ),
              _miniStat(
                Icons.play_circle_rounded,
                '${seriesTracking.totalWatchedEpisodes}',
                'Episodes watched',
              ),
              _miniStat(
                Icons.bookmark_rounded,
                '${movieWatchlist + tvWatchlist}',
                'In watchlists',
              ),
            ],
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                intro,
                const SizedBox(height: 24),
                stats,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 5, child: intro),
              const SizedBox(width: 30),
              Expanded(flex: 4, child: stats),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 21),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _categorySelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _categoryButton(0, Icons.movie_outlined, 'Movies'),
          const SizedBox(width: 6),
          _categoryButton(1, Icons.tv_outlined, 'TV Series'),
        ],
      ),
    );
  }

  Widget _categoryButton(int index, IconData icon, String label) {
    final selected = homeCategoryIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            homeCategoryIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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

  List<Widget> _movieHomeContent() {
    return [
      _sectionTitle('Trending Movies', 'What people are watching now'),
      _horizontalMovieList(trendingMovies),
      _sectionTitle('Popular Movies', 'Big titles worth adding to your list'),
      _horizontalMovieList(popularMovies),
    ];
  }

  List<Widget> _tvHomeContent() {
    return [
      _sectionTitle('Trending TV Series', 'Series getting attention right now'),
      _horizontalTvList(trendingTvShows),
      _sectionTitle('Popular TV Series', 'Fan favorites across TMDB'),
      _horizontalTvList(popularTvShows),
      _sectionTitle('Top Rated TV Series', 'Highly rated series to discover'),
      _horizontalTvList(topRatedTvShows),
    ];
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 18, 2, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _horizontalMovieList(Future<List<Movie>> future) {
    return SizedBox(
      height: 315,
      child: FutureBuilder<List<Movie>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          final movies = snapshot.data ?? [];
          if (movies.isEmpty) return const Center(child: Text('No movies found'));

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: movies.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) => MovieCard(movie: movies[index]),
          );
        },
      ),
    );
  }

  Widget _horizontalTvList(Future<List<TvShow>> future) {
    return SizedBox(
      height: 315,
      child: FutureBuilder<List<TvShow>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString());
          }

          final shows = snapshot.data ?? [];
          if (shows.isEmpty) return const Center(child: Text('No TV series found'));

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shows.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, index) => TvShowCard(show: shows[index]),
          );
        },
      ),
    );
  }

  Widget _errorState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _openProfiles() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ProfilesScreen()),
    );

    if (changed == true && mounted) {
      setState(() {});
    }
  }
}

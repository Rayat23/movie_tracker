import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../models/tv_show.dart';
import '../services/movie_service.dart';
import '../services/tv_service.dart';
import '../widgets/movie_card.dart';
import '../widgets/tv_show_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MovieService movieService = MovieService();
  final TvService tvService = TvService();
  final TextEditingController controller = TextEditingController();

  int categoryIndex = 0;
  List<Movie> movieResults = [];
  List<TvShow> tvResults = [];

  bool isLoading = false;
  bool hasSearched = false;
  String? errorMessage;
  String lastQuery = '';

  Future<void> doSearch() async {
    final query = controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      hasSearched = true;
      errorMessage = null;
      lastQuery = query;
    });

    try {
      if (categoryIndex == 0) {
        final movies = await movieService.searchMovies(query);
        if (!mounted) return;

        setState(() {
          movieResults = movies;
          isLoading = false;
        });
      } else {
        final shows = await tvService.searchTvShows(query);
        if (!mounted) return;

        setState(() {
          tvResults = shows;
          isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        if (categoryIndex == 0) {
          movieResults = [];
        } else {
          tvResults = [];
        }
        isLoading = false;
        errorMessage = 'Search could not be completed. Please try again.';
      });
    }
  }

  void changeCategory(int index) {
    if (categoryIndex == index) return;

    setState(() {
      categoryIndex = index;
      hasSearched = false;
      isLoading = false;
      errorMessage = null;
    });

    if (controller.text.trim().isNotEmpty) {
      doSearch();
    }
  }

  void _clearSearch() {
    controller.clear();
    setState(() {
      movieResults = [];
      tvResults = [];
      hasSearched = false;
      isLoading = false;
      errorMessage = null;
      lastQuery = '';
    });
  }

  void _searchSuggestion(String query) {
    controller.text = query;
    controller.selection = TextSelection.collapsed(offset: query.length);
    doSearch();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Search TMDB for movies and TV series, then add them to your personal profile.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _searchPanel(),
              const SizedBox(height: 18),
              _categorySelector(),
              const SizedBox(height: 18),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF11131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => doSearch(),
            decoration: InputDecoration(
              hintText: categoryIndex == 0
                  ? 'Search movies by title...'
                  : 'Search TV series by title...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.text.isNotEmpty || hasSearched)
                    IconButton(
                      tooltip: 'Clear search',
                      onPressed: _clearSearch,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton.filled(
                      tooltip: 'Search',
                      onPressed: doSearch,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ],
              ),
            ),
            onChanged: (_) {
              setState(() {});
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Try:',
                style: TextStyle(fontSize: 12, color: Colors.white38),
              ),
              _suggestionChip(categoryIndex == 0 ? 'Dune' : 'Breaking Bad'),
              _suggestionChip(categoryIndex == 0 ? 'Interstellar' : 'The Last of Us'),
              _suggestionChip(categoryIndex == 0 ? 'The Batman' : 'Stranger Things'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _searchSuggestion(label),
      side: const BorderSide(color: Colors.white10),
      backgroundColor: Colors.white.withValues(alpha: 0.04),
      labelStyle: const TextStyle(fontSize: 12, color: Colors.white70),
    );
  }

  Widget _categorySelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D0F15),
        borderRadius: BorderRadius.circular(17),
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
    final selected = categoryIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => changeCategory(index),
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

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 14),
            Text('Searching TMDB...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return _messageState(
        icon: Icons.wifi_off_rounded,
        title: 'Search unavailable',
        message: errorMessage!,
      );
    }

    if (!hasSearched) {
      return _messageState(
        icon: categoryIndex == 0
            ? Icons.local_movies_outlined
            : Icons.live_tv_outlined,
        title: categoryIndex == 0
            ? 'Find your next movie'
            : 'Find your next series',
        message: categoryIndex == 0
            ? 'Search by movie title and add results to Favorites, Watchlist, or Watched.'
            : 'Search for a TV series, then track seasons and individual episodes.',
      );
    }

    final resultCount = categoryIndex == 0 ? movieResults.length : tvResults.length;

    if (resultCount == 0) {
      return _messageState(
        icon: Icons.search_off_rounded,
        title: 'No results for “$lastQuery”',
        message: 'Try another spelling or a shorter title.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Results for “$lastQuery”',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(
                '$resultCount results',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: categoryIndex == 0 ? _movieGrid() : _tvGrid(),
        ),
      ],
    );
  }

  Widget _movieGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 18),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 205,
        mainAxisExtent: 325,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: movieResults.length,
      itemBuilder: (context, index) {
        return MovieCard(movie: movieResults[index]);
      },
    );
  }

  Widget _tvGrid() {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 18),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 205,
        mainAxisExtent: 325,
        crossAxisSpacing: 16,
        mainAxisSpacing: 20,
      ),
      itemCount: tvResults.length,
      itemBuilder: (context, index) {
        return TvShowCard(show: tvResults[index]);
      },
    );
  }

  Widget _messageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 44),
        decoration: BoxDecoration(
          color: const Color(0xFF11131A),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 35, color: Colors.white38),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
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
}

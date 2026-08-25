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

  Future<void> doSearch() async {
    final query = controller.text.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      isLoading = true;
      hasSearched = true;
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        if (categoryIndex == 0) {
          movieResults = [];
        } else {
          tvResults = [];
        }
        isLoading = false;
      });
    }
  }

  void changeCategory(int index) {
    if (categoryIndex == index) return;

    setState(() {
      categoryIndex = index;
      hasSearched = false;
      isLoading = false;
    });

    if (controller.text.trim().isNotEmpty) {
      doSearch();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget categoryButton({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = categoryIndex == index;

    return Expanded(
      child: selected
          ? ElevatedButton.icon(
              onPressed: () => changeCategory(index),
              icon: Icon(icon),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            )
          : OutlinedButton.icon(
              onPressed: () => changeCategory(index),
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasSearched) {
      return Center(
        child: Text(
          categoryIndex == 0
              ? 'Search for a movie above'
              : 'Search for a TV series above',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (categoryIndex == 0) {
      if (movieResults.isEmpty) {
        return const Center(
          child: Text(
            'No movie results found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        );
      }

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: 315,
          crossAxisSpacing: 14,
          mainAxisSpacing: 18,
        ),
        itemCount: movieResults.length,
        itemBuilder: (context, index) {
          return MovieCard(movie: movieResults[index]);
        },
      );
    }

    if (tvResults.isEmpty) {
      return const Center(
        child: Text(
          'No TV series results found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        mainAxisExtent: 315,
        crossAxisSpacing: 14,
        mainAxisSpacing: 18,
      ),
      itemCount: tvResults.length,
      itemBuilder: (context, index) {
        return TvShowCard(show: tvResults[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => doSearch(),
            decoration: InputDecoration(
              hintText: categoryIndex == 0
                  ? 'Search movies...'
                  : 'Search TV series...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: doSearch,
              ),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 16),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }
}

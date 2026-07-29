import 'package:flutter/material.dart';

import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final MovieService movieService = MovieService();
  final TextEditingController controller = TextEditingController();

  List<Movie> results = [];
  bool isLoading = false;
  bool hasSearched = false;

  void doSearch() async {
    final query = controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
      hasSearched = true;
    });

    try {
      final movies = await movieService.searchMovies(query);
      setState(() {
        results = movies;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        results = [];
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!hasSearched) {
      return const Center(
        child: Text(
          "Search for a movie above",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (results.isEmpty) {
      return const Center(
        child: Text(
          "No results found",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.55,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return MovieCard(movie: results[index]);
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
              hintText: "Search movies...",
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
          const SizedBox(height: 16),
          Expanded(child: buildBody()),
        ],
      ),
    );
  }
}

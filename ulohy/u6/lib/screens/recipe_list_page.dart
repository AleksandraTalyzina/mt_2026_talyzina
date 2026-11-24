import 'dart:async';

import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_api.dart';
import '../services/search_log.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key, required this.api});

  final RecipeApi api;

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = ''; // trimmed text that is being searched
  int _requestCounter = 0; // id of the newest request

  List<Recipe>? _recipes;
  String _resultsQuery = ''; // query that _recipes belong to
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _query = text.trim();
      _load();
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _query = '';
    _load();
  }

  // used for the first load, searching, "Skúsiť znova" and pull-to-refresh
  Future<void> _load() async {
    final id = ++_requestCounter;
    final query = _query;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipes = await widget.api.fetchRecipes(
        query: query,
        requestId: id,
      );
      if (!mounted) return;
      // a newer request was sent meanwhile -> this answer is too old
      if (id != _requestCounter) {
        logSearch(
          id,
          '←',
          query,
          '${countResults(recipes.length)} ZAHODENÉ (aktuálna je #$_requestCounter)',
        );
        return;
      }
      logSearch(id, '←', query, '${countResults(recipes.length)} ZOBRAZENÉ');
      // the old list is replaced only after a successful response
      setState(() {
        _recipes = recipes;
        _resultsQuery = query;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (id != _requestCounter) {
        logSearch(
          id,
          '←',
          query,
          'chyba ZAHODENÉ (aktuálna je #$_requestCounter)',
        );
        return;
      }
      logSearch(id, '←', query, 'chyba ZOBRAZENÉ: $e');
      setState(() {
        _loading = false;
        if (_recipes == null) _error = '$e';
      });
      if (_recipes != null) {
        // keep the old data, just tell the user
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Načítanie zlyhalo. $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recepty'),
        actions: [
          const Text('Pomalá sieť'),
          Tooltip(
            message: 'Náhodné oneskorenie 0–3 s pri každej požiadavke',
            child: Switch(
              key: const Key('slowNetworkSwitch'),
              value: widget.api.slowNetwork,
              onChanged: (value) {
                setState(() => widget.api.slowNetwork = value);
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ValueListenableBuilder(
              valueListenable: _searchController,
              builder: (context, value, child) => TextField(
                key: const Key('searchField'),
                controller: _searchController,
                onChanged: _onSearchChanged,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Hľadať recept',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: value.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: 'Vymazať',
                          onPressed: _clearSearch,
                        ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          // old results stay visible, a thin bar shows that a request runs
          SizedBox(
            height: 4,
            child: _loading && _recipes != null
                ? const LinearProgressIndicator()
                : null,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final recipes = _recipes;
    if (recipes != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: recipes.isEmpty
            ? ListView(
                // pull-to-refresh works even with nothing in the list
                physics: const AlwaysScrollableScrollPhysics(),
                children: [EmptyView(query: _resultsQuery)],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: recipes.length,
                itemBuilder: (context, index) =>
                    RecipeTile(recipe: recipes[index]),
              ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return ErrorView(message: _error ?? '', onRetry: _load);
  }
}

class RecipeTile extends StatelessWidget {
  const RecipeTile({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          recipe.image,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 56,
            height: 56,
            child: Icon(Icons.restaurant),
          ),
        ),
      ),
      title: Text(recipe.name),
      subtitle: Text('${recipe.cuisine} • ${recipe.prepTimeMinutes} min'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(recipe.rating.toStringAsFixed(1)),
        ],
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 64),
          const SizedBox(height: 16),
          Text(
            query.isEmpty
                ? 'Nenašiel sa žiadny recept.'
                : 'Pre „$query“ sa nenašiel žiadny recept.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64),
            const SizedBox(height: 16),
            Text(
              'Recepty sa nepodarilo načítať',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Skúsiť znova'),
            ),
          ],
        ),
      ),
    );
  }
}

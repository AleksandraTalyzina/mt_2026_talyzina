import 'package:flutter/material.dart';

import '../models/recipe.dart';
import '../services/recipe_api.dart';

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key, required this.api});

  final RecipeApi api;

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  List<Recipe>? _recipes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // used for the first load, "Skúsiť znova" and pull-to-refresh
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final recipes = await widget.api.fetchRecipes();
      if (!mounted) return;
      // the old list is replaced only after a successful response
      setState(() => _recipes = recipes);
    } catch (e) {
      if (!mounted) return;
      if (_recipes == null) {
        setState(() => _error = '$e');
      } else {
        // refresh failed -> keep the old data, just tell the user
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Obnova zlyhala. $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recepty')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final recipes = _recipes;
    if (recipes != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          // pull-to-refresh works even when the list is short
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: recipes.length,
          itemBuilder: (context, index) => RecipeTile(recipe: recipes[index]),
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

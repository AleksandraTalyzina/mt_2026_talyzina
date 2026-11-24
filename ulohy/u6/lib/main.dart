import 'package:flutter/material.dart';

import 'screens/recipe_list_page.dart';
import 'services/recipe_api.dart';

void main() {
  runApp(RecipeApp(api: RecipeApi()));
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key, required this.api});

  // created once, so the "Pomalá sieť" setting survives rebuilds
  final RecipeApi api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recepty',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: RecipeListPage(api: api),
    );
  }
}

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

const String appTitle = 'Pasta Carbonara';

class Ingredient {
  const Ingredient(this.name, this.amount);
  final String name;
  final String amount;
}

class MethodSection {
  const MethodSection(this.title, this.steps);
  final String title;
  final List<String> steps;
}

class Recipe {
  const Recipe({
    required this.name,
    required this.photoColors,
    required this.ingredients,
    required this.nutrition,
    required this.method,
  });

  final String name;
  final List<Color> photoColors;       // 3 farebné plochy
  final List<Ingredient> ingredients;
  final List<Ingredient> nutrition;    // rovnaký tvar: názov – hodnota
  final List<MethodSection> method;
}

const Recipe pastaCarbonara = Recipe(
  name: 'Pasta Carbonara',
  photoColors: [Colors.amber, Colors.orange, Colors.deepOrange],
  ingredients: [
    Ingredient('Spaghetti', '400 g'),
    Ingredient('Egg yolks', '4 pcs'),
    Ingredient('Guanciale', '150 g'),
    Ingredient('Pecorino', '80 g'),
    Ingredient('Black pepper', 'to taste'),
    Ingredient('Salt', 'to taste'),
  ],
  nutrition: [
    Ingredient('Energy', '620 kcal'),
    Ingredient('Protein', '27 g'),
    Ingredient('Fat', '24 g'),
    Ingredient('Carbohydrates', '71 g'),
  ],
  method: [
    MethodSection('Preparation', [
      'Bring a large pot of salted water to the boil.',
      'Cut the guanciale into small strips.',
      'Whisk the egg yolks with grated pecorino and black pepper.',
    ]),
    MethodSection('Cooking', [
      'Cook the spaghetti until al dente.',
      'Fry the guanciale in a dry pan until crispy.',
      'Take the pan off the heat and add the drained pasta.',
      'Pour in the egg mixture and stir quickly so the eggs do not scramble.',
      'Add pasta water little by little until the sauce is creamy.',
    ]),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const RecipeDetailPage(recipe: pastaCarbonara),
    );
  }
}

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // veľký nadpis sa pri scrolle zmenší, lišta ostane pripnutá
          SliverAppBar.large(title: Text(recipe.name)),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoSection(colors: recipe.photoColors),
                const SectionTitle('Ingredients'),
                IngredientSection(ingredients: recipe.ingredients),
                NutritionSection(nutrition: recipe.nutrition),
                const SectionTitle('Method'),
                MethodCard(section: recipe.method[0], firstStep: 1),
                MethodCard(section: recipe.method[1], firstStep: 4),
              ],
            ),
          ),
        ],
      ),
      // tlačidlo nie je v CustomScrollView, preto ostane pripnuté dole
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.restaurant),
            label: const Text('Start cooking'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

// fotky – PageView, dá sa potiahnuť do strany
class PhotoSection extends StatelessWidget {
  const PhotoSection({super.key, required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: PageView(
        children: [
          for (final color in colors)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: color,
              child: const Center(
                child: Icon(Icons.restaurant, size: 80, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ingrediencie – vodorovný ListView
class IngredientSection extends StatelessWidget {
  const IngredientSection({super.key, required this.ingredients});

  final List<Ingredient> ingredients;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final ingredient in ingredients)
            IngredientCard(ingredient: ingredient),
        ],
      ),
    );
  }
}

class IngredientCard extends StatelessWidget {
  const IngredientCard({super.key, required this.ingredient});

  final Ingredient ingredient;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(ingredient.name, style: text.titleMedium),
            Text(ingredient.amount,
                style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// nutričné hodnoty – ExpansionTile, ťuknutím sa rozbalí
class NutritionSection extends StatelessWidget {
  const NutritionSection({super.key, required this.nutrition});

  final List<Ingredient> nutrition;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Nutrition facts',
          style: Theme.of(context).textTheme.titleLarge),
      subtitle: const Text('per serving'),
      children: [
        for (final item in nutrition)
          ListTile(title: Text(item.name), trailing: Text(item.amount)),
      ],
    );
  }
}

class MethodCard extends StatelessWidget {
  const MethodCard({
    super.key,
    required this.section,
    required this.firstStep,
  });

  final MethodSection section;
  final int firstStep;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(section.title, style: Theme.of(context).textTheme.titleMedium),
            for (var i = 0; i < section.steps.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text('${firstStep + i}.'),
                  Expanded(child: Text(section.steps[i])),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

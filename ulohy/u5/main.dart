import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

const String appTitle = 'Pasta Carbonara';

class Ingredient {
  const Ingredient(this.name, this.quantity, this.unit);
  final String name;
  final double? quantity;   // null = "to taste", nedá sa prepočítať
  final String unit;

  String get amount => amountFor(1);

  // množstvo prepočítané podľa porcií – vypočíta sa, neukladá sa do stavu
  String amountFor(double factor) {
    final q = quantity;
    if (q == null) return unit;
    var text = (q * factor).toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return '$text $unit';
  }
}

class MethodSection {
  const MethodSection(this.title, this.steps);
  final String title;
  final List<String> steps;
}

class Recipe {
  const Recipe({
    required this.name,
    required this.baseServings,
    required this.photoColors,
    required this.ingredients,
    required this.nutrition,
    required this.method,
  });

  final String name;
  final int baseServings;              // pre koľko porcií sú množstvá
  final List<Color> photoColors;       // 3 farebné plochy
  final List<Ingredient> ingredients;
  final List<Ingredient> nutrition;    // rovnaký tvar: názov – hodnota
  final List<MethodSection> method;

  // všetky kroky za sebou (3 + 5 = 8)
  List<String> get allSteps => [for (final section in method) ...section.steps];
}

const Recipe pastaCarbonara = Recipe(
  name: 'Pasta Carbonara',
  baseServings: 4,
  photoColors: [Colors.amber, Colors.orange, Colors.deepOrange],
  ingredients: [
    Ingredient('Spaghetti', 400, 'g'),
    Ingredient('Egg yolks', 4, 'pcs'),
    Ingredient('Guanciale', 150, 'g'),
    Ingredient('Pecorino', 80, 'g'),
    Ingredient('Black pepper', null, 'to taste'),
    Ingredient('Salt', null, 'to taste'),
  ],
  nutrition: [
    Ingredient('Energy', 620, 'kcal'),
    Ingredient('Protein', 27, 'g'),
    Ingredient('Fat', 24, 'g'),
    Ingredient('Carbohydrates', 71, 'g'),
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

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({super.key, required this.recipe});

  final Recipe recipe;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  // spoločný stav – potrebuje ho viac častí obrazovky, preto je u rodiča
  late int _servings = widget.recipe.baseServings;
  final Set<int> _doneSteps = {};        // poradie krokov v celom recepte, 0–7

  // prvý neodškrtnutý krok – odtiaľ začne režim varenia
  int get _firstUndoneStep {
    var i = 0;
    while (_doneSteps.contains(i)) {
      i++;
    }
    return i;
  }

  void _toggleStep(int index) {
    setState(() {
      if (_doneSteps.contains(index)) {
        _doneSteps.remove(index);
      } else {
        _doneSteps.add(index);
      }
    });
  }

  // dáta tam (kroky, od ktorého začať), výsledok späť (koľko krokov je hotových)
  Future<void> _startCooking() async {
    final steps = widget.recipe.allSteps;
    final start = _firstUndoneStep;
    final done = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => CookingPage(
          title: widget.recipe.name,
          steps: steps,
          startStep: start == steps.length ? 0 : start,
        ),
      ),
    );
    // null = odchod systémovým tlačidlom späť, nič sa nemení
    if (done == null || !mounted) return;
    setState(() => _doneSteps.addAll([for (var i = 0; i < done; i++) i]));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(done == steps.length
            ? 'Bon appétit! All ${steps.length} steps done.'
            : 'Paused at step ${done + 1} of ${steps.length}.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final totalSteps = recipe.allSteps.length;
    final doneCount = _doneSteps.length;

    // číslo prvého kroku každej sekcie sa vypočíta, nie je natvrdo 1 a 4
    final methodCards = <Widget>[];
    var firstStep = 0;
    for (final section in recipe.method) {
      methodCards.add(MethodCard(
        section: section,
        firstStep: firstStep,
        doneSteps: _doneSteps,
        onToggle: _toggleStep,
      ));
      firstStep += section.steps.length;
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // veľký nadpis sa pri scrolle zmenší, lišta ostane pripnutá
          SliverAppBar.large(
            title: Text(recipe.name),
            actions: const [FavoriteButton()],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoSection(colors: recipe.photoColors),
                SectionTitle(
                  'Ingredients',
                  trailing: ServingsStepper(
                    value: _servings,
                    onChanged: (value) => setState(() => _servings = value),
                  ),
                ),
                IngredientSection(
                  ingredients: recipe.ingredients,
                  factor: _servings / recipe.baseServings,
                ),
                NutritionSection(nutrition: recipe.nutrition),
                SectionTitle(
                  'Method',
                  trailing: Text('$doneCount / $totalSteps',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: LinearProgressIndicator(value: doneCount / totalSteps),
                ),
                ...methodCards,
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
            onPressed: _startCooking,
            icon: const Icon(Icons.restaurant),
            label: Text(doneCount == 0
                ? 'Start cooking'
                : doneCount == totalSteps
                    ? 'Cook again'
                    : 'Continue cooking ($doneCount / $totalSteps)'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
            ),
          ),
        ),
      ),
    );
  }
}

// obľúbené – stav je len tu, nikto iný ho nepotrebuje
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      isSelected: _isFavorite,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: const Icon(Icons.favorite, color: Colors.red),
      tooltip: _isFavorite ? 'Remove from favourites' : 'Add to favourites',
      onPressed: () => setState(() => _isFavorite = !_isFavorite),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          ?trailing,                     // pridá sa, len ak nie je null
        ],
      ),
    );
  }
}

// kontrolovaný vstup – hodnotu dostane od rodiča, zmenu len ohlási cez callback
class ServingsStepper extends StatelessWidget {
  const ServingsStepper({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove),
          tooltip: 'Fewer servings',
        ),
        SizedBox(
          width: 88,
          child: Text(
            value == 1 ? '1 serving' : '$value servings',
            textAlign: TextAlign.center,
          ),
        ),
        IconButton.filledTonal(
          onPressed: value < 12 ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add),
          tooltip: 'More servings',
        ),
      ],
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

// ingrediencie – vodorovný ListView, ťuknutím sa odškrtnú
// odškrtnutie potrebuje len tento zoznam, preto je stav tu – nie v karte,
// lebo ListView karty mimo obrazovky zahodí a stav by sa stratil
class IngredientSection extends StatefulWidget {
  const IngredientSection({
    super.key,
    required this.ingredients,
    required this.factor,
  });

  final List<Ingredient> ingredients;
  final double factor;                   // porcie / pôvodné porcie

  @override
  State<IngredientSection> createState() => _IngredientSectionState();
}

class _IngredientSectionState extends State<IngredientSection> {
  final Set<int> _checked = {};

  void _toggle(int index) {
    setState(() {
      if (_checked.contains(index)) {
        _checked.remove(index);
      } else {
        _checked.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ingredients = widget.ingredients;
    return SizedBox(
      height: 90,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (var i = 0; i < ingredients.length; i++)
            IngredientCard(
              ingredient: ingredients[i],
              amount: ingredients[i].amountFor(widget.factor),
              checked: _checked.contains(i),
              onTap: () => _toggle(i),
            ),
        ],
      ),
    );
  }
}

class IngredientCard extends StatelessWidget {
  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.amount,
    required this.checked,
    required this.onTap,
  });

  final Ingredient ingredient;
  final String amount;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    // odškrtnutá ingrediencia je prečiarknutá
    final decoration = checked ? TextDecoration.lineThrough : null;
    return Card(
      clipBehavior: Clip.antiAlias,      // aby efekt ťuknutia nepretekal cez rohy
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            children: [
              Icon(
                checked ? Icons.check_circle : Icons.circle_outlined,
                color: colors.primary,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(ingredient.name,
                      style: text.titleMedium
                          ?.copyWith(decoration: decoration)),
                  Text(amount,
                      style: text.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          decoration: decoration)),
                ],
              ),
            ],
          ),
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
    required this.doneSteps,
    required this.onToggle,
  });

  final MethodSection section;
  final int firstStep;                   // poradie prvého kroku v celom recepte
  final Set<int> doneSteps;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(section.title, style: Theme.of(context).textTheme.titleMedium),
            for (var i = 0; i < section.steps.length; i++)
              CheckboxListTile(
                value: doneSteps.contains(firstStep + i),
                onChanged: (_) => onToggle(firstStep + i),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${firstStep + i + 1}. ${section.steps[i]}',
                  style: doneSteps.contains(firstStep + i)
                      ? TextStyle(
                          color: colors.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// režim varenia – krok po kroku, aktuálny krok pozná len táto stránka
class CookingPage extends StatefulWidget {
  const CookingPage({
    super.key,
    required this.title,
    required this.steps,
    required this.startStep,
  });

  final String title;
  final List<String> steps;
  final int startStep;

  @override
  State<CookingPage> createState() => _CookingPageState();
}

class _CookingPageState extends State<CookingPage> {
  late int _current = widget.startStep;

  @override
  Widget build(BuildContext context) {
    final steps = widget.steps;
    final isLast = _current == steps.length - 1;
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        // zavretie vráti počet hotových krokov – všetky pred aktuálnym
        leading: CloseButton(onPressed: () => Navigator.pop(context, _current)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 16,
          children: [
            LinearProgressIndicator(value: (_current + 1) / steps.length),
            Text('Step ${_current + 1} of ${steps.length}',
                style: text.titleMedium?.copyWith(color: colors.primary)),
            Expanded(
              child: SingleChildScrollView(
                child: Text(steps[_current], style: text.headlineSmall),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            spacing: 16,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      _current > 0 ? () => setState(() => _current--) : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isLast
                      ? () => Navigator.pop(context, steps.length)
                      : () => setState(() => _current++),
                  icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                  label: Text(isLast ? 'Finish' : 'Next'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

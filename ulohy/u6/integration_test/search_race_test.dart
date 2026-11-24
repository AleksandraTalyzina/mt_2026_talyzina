import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:recipe_app/main.dart';
import 'package:recipe_app/screens/recipe_list_page.dart';
import 'package:recipe_app/services/recipe_api.dart';

// Works with the real DummyJSON API, so it waits in real time:
// pumps until [done] is true, but at least [atLeast] and at most 30 s.
Future<void> waitFor(
  WidgetTester tester,
  bool Function() done, {
  Duration atLeast = Duration.zero,
}) async {
  final start = DateTime.now();
  while (DateTime.now().difference(start) < const Duration(seconds: 30)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (DateTime.now().difference(start) >= atLeast && done()) return;
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('fast typing shows only results of the last query', (
    tester,
  ) async {
    await tester.pumpWidget(RecipeApp(api: RecipeApi()));
    final tiles = find.byType(RecipeTile);
    final progress = find.byType(LinearProgressIndicator);

    // 1. wait for the first list
    await waitFor(tester, () => tiles.evaluate().isNotEmpty);
    expect(tiles, findsWidgets);

    // 2. random delay 0–3000 ms for every request
    await tester.tap(find.byKey(const Key('slowNetworkSwitch')));
    await tester.pump();

    // 3. type fast; 350 ms lets each query pass the 300 ms debounce
    // (in a live test pump(duration) really waits that long)
    final field = find.byKey(const Key('searchField'));
    for (final query in ['p', 'pa', 'pas', 'chick', 'chicken']) {
      await tester.enterText(field, query);
      await tester.pump(const Duration(milliseconds: 350));
    }

    // 4. give all answers time to come back (max delay 3 s + network);
    // the thin bar disappears only when the newest answer is shown
    await waitFor(
      tester,
      () => progress.evaluate().isEmpty,
      atLeast: const Duration(seconds: 4),
    );

    // 5. only "chicken" results – no "Chickpea" from "chick", no "Pasta" from "pas"
    final names = tester
        .widgetList<RecipeTile>(tiles)
        .map((tile) => tile.recipe.name)
        .toList();
    debugPrint('[SEARCH] zobrazené: ${names.join(', ')}');
    expect(names, isNotEmpty);
    for (final name in names) {
      expect(name.toLowerCase(), contains('chicken'));
    }

    // 6. nonsense query -> empty result text
    const emptyText = 'Pre „xyzqwe“ sa nenašiel žiadny recept.';
    await tester.enterText(field, 'xyzqwe');
    await waitFor(tester, () => find.text(emptyText).evaluate().isNotEmpty);
    expect(tiles, findsNothing);
    expect(find.text(emptyText), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/screens/recipe_list_page.dart';
import 'package:recipe_app/services/recipe_api.dart';

// answers after 1 s without going to the internet
class FakeRecipeApi extends RecipeApi {
  bool fail = false;
  int calls = 0;

  @override
  Future<List<Recipe>> fetchRecipes() async {
    calls++;
    await Future<void>.delayed(const Duration(seconds: 1));
    if (fail) throw const RecipeApiException('Server vrátil chybu 503.');
    return [
      Recipe(
        id: calls,
        name: 'Recept $calls',
        image: '',
        cuisine: 'Italian',
        prepTimeMinutes: 20,
        rating: 4.6,
      ),
    ];
  }
}

void main() {
  late FakeRecipeApi api;

  setUp(() => api = FakeRecipeApi());

  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(MaterialApp(home: RecipeListPage(api: api)));
  }

  testWidgets('shows a spinner, then the list', (tester) async {
    await pumpPage(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Recept 1'), findsOneWidget);
    expect(find.text('Italian • 20 min'), findsOneWidget);
    expect(find.text('4.6'), findsOneWidget);
  });

  testWidgets('first load error shows a message and retry', (tester) async {
    api.fail = true;
    await pumpPage(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Server vrátil chybu 503.'), findsOneWidget);

    api.fail = false;
    await tester.tap(find.text('Skúsiť znova'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Recept 2'), findsOneWidget);
  });

  testWidgets('refresh keeps old data until the new list arrives', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pump(const Duration(seconds: 1));

    await tester.fling(find.text('Recept 1'), const Offset(0, 300), 1000);
    // a few frames so the indicator snaps into place and calls onRefresh
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(api.calls, 2);
    expect(find.text('Recept 1'), findsOneWidget); // still on screen

    await tester.pumpAndSettle();
    expect(find.text('Recept 1'), findsNothing);
    expect(find.text('Recept 2'), findsOneWidget);
  });

  testWidgets('failed refresh keeps old data and shows a SnackBar', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pump(const Duration(seconds: 1));

    api.fail = true;
    await tester.fling(find.text('Recept 1'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(api.calls, 2);
    expect(find.text('Recept 1'), findsOneWidget);
    expect(
      find.text('Obnova zlyhala. Server vrátil chybu 503.'),
      findsOneWidget,
    );
  });
}

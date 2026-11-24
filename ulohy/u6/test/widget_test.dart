import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:recipe_app/models/recipe.dart';
import 'package:recipe_app/screens/recipe_list_page.dart';
import 'package:recipe_app/services/recipe_api.dart';

// answers without going to the internet; each query can have its own delay
class FakeRecipeApi extends RecipeApi {
  bool fail = false;
  int calls = 0;
  Map<String, Duration> delays = {};

  @override
  Future<List<Recipe>> fetchRecipes({
    String query = '',
    int requestId = 0,
  }) async {
    calls++;
    await Future<void>.delayed(delays[query] ?? const Duration(seconds: 1));
    if (fail) throw const RecipeApiException('Server vrátil chybu 503.');
    if (query == 'xyz') return [];
    return [
      Recipe(
        id: calls,
        name: query.isEmpty ? 'Recept $calls' : '$query $calls',
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

  final searchField = find.byKey(const Key('searchField'));

  // --- etapa 1 ---

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
      find.text('Načítanie zlyhalo. Server vrátil chybu 503.'),
      findsOneWidget,
    );
  });

  // --- etapa 2 ---

  testWidgets('older answer that arrives later is thrown away', (tester) async {
    api.delays = {
      'pas': const Duration(seconds: 2),
      'pasta': const Duration(milliseconds: 200),
    };
    await pumpPage(tester);
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(searchField, 'pas');
    await tester.pump(const Duration(milliseconds: 300)); // request #2
    // old results stay, thin bar instead of the big spinner
    expect(find.text('Recept 1'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.enterText(searchField, 'pasta');
    await tester.pump(const Duration(milliseconds: 300)); // request #3
    await tester.pump(const Duration(milliseconds: 200)); // #3 arrives
    expect(find.text('pasta 3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pump(const Duration(seconds: 2)); // #2 arrives late
    expect(find.text('pasta 3'), findsOneWidget);
    expect(find.text('pas 2'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('empty result has its own text and can be refreshed', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(searchField, '  xyz ');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    const emptyText = 'Pre „xyz“ sa nenašiel žiadny recept.';
    expect(find.text(emptyText), findsOneWidget);

    await tester.fling(find.text(emptyText), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(api.calls, 3);
    expect(find.text(emptyText), findsOneWidget);
  });

  testWidgets('clear button shows the first list again', (tester) async {
    await pumpPage(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byIcon(Icons.clear), findsNothing);

    await tester.enterText(searchField, 'pasta');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('pasta 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Recept 3'), findsOneWidget);
    expect(find.byIcon(Icons.clear), findsNothing);
  });
}

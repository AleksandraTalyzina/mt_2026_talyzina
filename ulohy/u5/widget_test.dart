import 'package:recipe_detail/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const MyApp());
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('initial screen', (tester) async {
    await pumpApp(tester);
    expect(find.text('4 servings'), findsOneWidget);
    expect(find.text('400 g'), findsOneWidget);
    expect(find.text('0 / 8'), findsOneWidget);
    expect(find.text('Start cooking'), findsOneWidget);
  });

  testWidgets('servings stepper rescales amounts', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Fewer servings'));
    await tester.pump();
    await tester.tap(find.byTooltip('Fewer servings'));
    await tester.pump();
    await tester.pump();
    expect(find.text('2 servings'), findsOneWidget);
    expect(find.text('200 g'), findsOneWidget);
    expect(find.text('2 pcs'), findsOneWidget);
    await tester.tap(find.byTooltip('More servings'));
    await tester.pump();
    await tester.pump();
    expect(find.text('3 servings'), findsOneWidget);
    expect(find.text('300 g'), findsOneWidget);
    expect(find.text('112.5 g', skipOffstage: false), findsOneWidget);
    // minimum 1
    await tester.tap(find.byTooltip('Fewer servings'));
    await tester.pump();
    await tester.tap(find.byTooltip('Fewer servings'));
    await tester.pump();
    await tester.tap(find.byTooltip('Fewer servings'));
    await tester.pump();
    await tester.pump();
    expect(find.text('1 serving'), findsOneWidget);
    expect(find.text('100 g'), findsOneWidget);
    // nutrition stays per serving
    await tapVisible(tester, find.text('Nutrition facts'));
    expect(find.text('620 kcal'), findsOneWidget);
  });

  testWidgets('favourite toggles', (tester) async {
    await pumpApp(tester);
    expect(find.byIcon(Icons.favorite), findsNothing);
    await tester.tap(find.byTooltip('Add to favourites'));
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from favourites'));
    await tester.pump();
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('ingredient check toggles', (tester) async {
    await pumpApp(tester);
    expect(find.byIcon(Icons.check_circle), findsNothing);
    await tester.tap(find.text('Spaghetti'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await tester.tap(find.text('Spaghetti'));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('step check updates progress and button', (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.textContaining('4. Cook the spaghetti'));
    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.text('Continue cooking (1 / 8)'), findsOneWidget);
  });

  testWidgets('cooking mode: finish marks all steps done', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Start cooking'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 8'), findsOneWidget);
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.text('Next'));
      await tester.pump();
    }
    expect(find.text('Step 8 of 8'), findsOneWidget);
    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.text('8 / 8'), findsOneWidget);
    expect(find.text('Cook again'), findsOneWidget);
    expect(find.textContaining('Bon appétit'), findsOneWidget);
  });

  testWidgets('cooking mode: starts at first undone, close returns progress',
      (tester) async {
    await pumpApp(tester);
    await tapVisible(tester, find.textContaining('1. Bring'));
    await tester.tap(find.text('Continue cooking (1 / 8)'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 8'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('2 / 8'), findsOneWidget);
    expect(find.text('Paused at step 3 of 8.'), findsOneWidget);
  });

  testWidgets('cooking mode: system back changes nothing', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Start cooking'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pump();
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();
    expect(find.text('0 / 8'), findsOneWidget);
    expect(find.text('Start cooking'), findsOneWidget);
  });
}

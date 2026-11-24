// Screenshots of the real app (real API), rendered in phone size.
// Used instead of `flutter screenshot`, which does not work on desktop:
//   flutter test integration_test/screenshots_test.dart -d windows
//     --dart-define=SHOT_DIR=<absolute path to screenshots>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:recipe_app/main.dart';
import 'package:recipe_app/screens/recipe_list_page.dart';
import 'package:recipe_app/services/recipe_api.dart';

const shotDir = String.fromEnvironment('SHOT_DIR', defaultValue: 'screenshots');
const phone = Size(400, 860);
final shotKey = GlobalKey();

Future<void> startApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(phone);
  await tester.pumpWidget(
    RepaintBoundary(
      key: shotKey,
      child: RecipeApp(api: RecipeApi()),
    ),
  );
}

// real-time wait: pumps until [done] is true (at most 30 s)
Future<void> waitFor(WidgetTester tester, bool Function() done) async {
  final start = DateTime.now();
  while (DateTime.now().difference(start) < const Duration(seconds: 30)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (done()) return;
  }
}

Future<void> waitSeconds(WidgetTester tester, int seconds) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> takeShot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(shotKey),
  );
  final image = await boundary.toImage(pixelRatio: 2.5);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('$shotDir/$name.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  debugPrint('[SHOT] ${file.path}');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final tiles = find.byType(RecipeTile);
  final progress = find.byType(LinearProgressIndicator);

  testWidgets('etapa2_hladanie', (tester) async {
    await startApp(tester);
    await waitFor(tester, () => tiles.evaluate().isNotEmpty);

    await tester.enterText(find.byKey(const Key('searchField')), 'chicken');
    await tester.pump(const Duration(milliseconds: 350));
    await waitFor(tester, () => progress.evaluate().isEmpty);
    await waitSeconds(tester, 3); // images
    expect(tiles, findsWidgets);
    await takeShot(tester, 'etapa2_hladanie');
  });
}

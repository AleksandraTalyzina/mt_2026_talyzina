# U6 – Etapa 1: Zoznam receptov

Aplikácia stiahne prvých 10 receptov z [DummyJSON](https://dummyjson.com/docs/recipes) (bez API kľúča)
a pri každom ukáže obrázok, názov, kuchyňu, čas prípravy a hodnotenie.

## Súbory

| Súbor | Obsah |
|---|---|
| `lib/main.dart` | `MaterialApp`, Material 3 téma, `RecipeListPage(api: RecipeApi())` |
| `lib/models/recipe.dart` | model `Recipe` s `factory Recipe.fromJson` |
| `lib/services/recipe_api.dart` | `RecipeApi` – jediné miesto s URL a parsovaním JSON |
| `lib/screens/recipe_list_page.dart` | obrazovka zoznamu (`RecipeListPage`), riadok `RecipeTile`, chybový stav `ErrorView` |
| `test/widget_test.dart` | 4 widget testy s falošným API (bez internetu) |
| `screenshots/etapa1_zoznam.png` | načítaný zoznam 10 receptov |
| `screenshots/etapa1_chyba.png` | chybový stav – *Server vrátil chybu 503* a tlačidlo *Skúsiť znova* |
| `android/app/src/main/AndroidManifest.xml` | povolenie `INTERNET` |
| `macos/Runner/*.entitlements` | `com.apple.security.network.client` v oboch súboroch |

## Splnené požiadavky

1. **Komunikácia v jednej triede** – `RecipeApi.fetchRecipes()` pošle požiadavku (timeout 10 s),
   pri statuse inom ako 200 vyhodí výnimku a JSON premení na `List<Recipe>`. UI nepozná URL ani JSON,
   volá len `widget.api.fetchRecipes()`.
2. **Načítavanie** – pri prvom načítaní `CircularProgressIndicator` v strede obrazovky.
3. **Chyba** – správa po slovensky a `FilledButton` *Skúsiť znova*, ktorý načítanie spustí znova.
4. **Obnova potiahnutím** – `RefreshIndicator` + `ListView` s `AlwaysScrollableScrollPhysics`.
   Počas obnovy ostáva starý zoznam, nový ho prepíše až po úspešnej odpovedi.
   Ak obnova zlyhá, staré dáta ostanú a chyba sa ukáže v `SnackBar`.

## Stav obrazovky

Stav je v `StatefulWidget` (žiadny state management balík):

| `_recipes` | `_loading` | Zobrazí sa |
|---|---|---|
| `null` | `true` | `CircularProgressIndicator` |
| `null` | `false` | `ErrorView` so správou z `_error` |
| zoznam | `true` / `false` | zoznam – počas obnovy staré dáta |

Prvé načítanie, *Skúsiť znova* aj obnova potiahnutím volajú tú istú metódu `_load()`:

```dart
try {
  final recipes = await widget.api.fetchRecipes();
  setState(() => _recipes = recipes); // starý zoznam sa prepíše až teraz
} catch (e) {
  if (_recipes == null) {
    setState(() => _error = '$e');      // nie je čo ukázať -> chybová obrazovka
  } else {
    ScaffoldMessenger.of(context).showSnackBar(...); // staré dáta ostanú
  }
} finally {
  setState(() => _loading = false);
}
```

## Chybové správy

`RecipeApi` premení technické chyby na zrozumiteľné slovenské správy (`RecipeApiException`):

| Chyba | Správa |
|---|---|
| `TimeoutException` (10 s) | Server neodpovedá. Skúste to o chvíľu znova. |
| `http.ClientException` (bez siete) | Nepodarilo sa pripojiť k serveru. Skontrolujte internetové pripojenie. |
| status ≠ 200 | Server vrátil chybu 503. Skúste to neskôr. |

## Riadok zoznamu

`ListTile` – vľavo obrázok 56 × 56 so zaoblenými rohmi (`ClipRRect`, `Image.network` s `errorBuilder`,
náhradná ikona `Icons.restaurant`), názov, podtitul *Italian • 20 min*, vpravo hviezdička s hodnotením.
Hodnotenie sa číta ako `(json['rating'] as num).toDouble()`, lebo môže prísť aj celé číslo.

## Kontrola

- `flutter analyze` – bez chýb.
- 4 widget testy (`flutter test`) s `FakeRecipeApi`, ktoré odpovedá po 1 s:
  spinner → zoznam; chyba → *Skúsiť znova* → zoznam; obnova nechá starý zoznam, kým nepríde nový;
  neúspešná obnova nechá starý zoznam a ukáže SnackBar.
- Screenshoty z Android emulátora (Pixel, API 36) cez `flutter screenshot`. Na chybový stav bola URL
  v `RecipeApi` dočasne prepnutá na `https://dummyjson.com/http/503` a potom vrátená späť
  (`grep "http/503" lib/` nič nenájde).

## Spustenie

```bash
flutter pub get
flutter run
```

Na test pomalej odpovede stačí do URL v `RecipeApi` dočasne pridať `&delay=2000`.

## Použitie LLM

Použitý nástroj: **Claude Code** (Anthropic, model Claude Opus 5.5) ako asistent priamo vo VS Code.

- **Kľúčový prompt** – podrobné zadanie etapy: povinné požiadavky, API a typy polí, technické obmedzenia
  (balík `http`, `StatefulWidget`, povolenia), postup snímania screenshotov a git. Ďalší prompt:
  presunúť projekt do tohto repozitára ako `ulohy/u6`.
- **Implementácia** – LLM vytvoril Flutter projekt, model, `RecipeApi`, obrazovku a nastavil povolenia
  pre Android a macOS.
- **Testy** – LLM nahradil predvolený test počítadla štyrmi testami stavov. Jeden test najprv padal,
  lebo `RefreshIndicator` volá `onRefresh` až po animácii – opravené pridaním niekoľkých snímok (`pump`).
- **Screenshoty** – LLM spustil aplikáciu na emulátore, nasnímal oba stavy, obrázky skontroloval
  a URL po snímke chyby vrátil späť.
- **Odovzdanie** – LLM pripravil tento popis a súbory v `ulohy/u6/`. Vygenerovaný `README.md` z Fluttera
  bol vynechaný, aby nekolidoval so zadaním, ktoré do `ulohy/u6/` pridá šablóna predmetu.

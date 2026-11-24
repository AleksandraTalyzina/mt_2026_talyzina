# U6 – Recepty z DummyJSON

**Etapa 1 – Zoznam receptov:** aplikácia stiahne prvých 10 receptov z [DummyJSON](https://dummyjson.com/docs/recipes)
(bez API kľúča) a pri každom ukáže obrázok, názov, kuchyňu, čas prípravy a hodnotenie.
**Etapa 2 – Hľadanie:** pole na hľadanie (hľadá server), prepínač *Pomalá sieť* a počítadlo požiadaviek,
vďaka ktorému sa pri rýchlom písaní nezobrazia výsledky staršieho dopytu – [popis nižšie](#etapa-2--hľadanie).

## Súbory

| Súbor | Obsah |
|---|---|
| `lib/main.dart` | `MaterialApp`, Material 3 téma; `RecipeApi` sa vytvorí raz v `main()` |
| `lib/models/recipe.dart` | model `Recipe` s `factory Recipe.fromJson` |
| `lib/services/recipe_api.dart` | `RecipeApi` – jediné miesto s URL a parsovaním JSON, hľadanie, `slowNetwork` |
| `lib/services/search_log.dart` | riadok logu `[SEARCH]` s časom `HH:mm:ss.SSS` |
| `lib/screens/recipe_list_page.dart` | obrazovka zoznamu s hľadaním (`RecipeListPage`), `RecipeTile`, `EmptyView`, `ErrorView` |
| `test/widget_test.dart` | 7 widget testov s falošným API (bez internetu) |
| `integration_test/search_race_test.dart` | integračný test rýchleho písania so skutočným API |
| `integration_test/screenshots_test.dart` | uloží screenshoty skutočnej aplikácie v rozmere telefónu (na desktope) |
| `proof/etapa2_log_full.txt`, `proof/etapa2_log.txt` | celý výstup integračného testu a vyfiltrované riadky `[SEARCH]` |
| `screenshots/etapa1_zoznam.png` | načítaný zoznam 10 receptov |
| `screenshots/etapa1_chyba.png` | chybový stav – *Server vrátil chybu 503* a tlačidlo *Skúsiť znova* |
| `screenshots/etapa2_hladanie.png` | výsledky hľadania „chicken“ |
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

## Etapa 2 – Hľadanie

### Hľadá server

Pole nad zoznamom (`TextField` s lupou a tlačidlom ✕ na vymazanie). Text sa ořeže (`trim`) a po 300 ms
bez písania (debounce) sa pošle na server. `RecipeApi` skladá URL cez `Uri.https` s `queryParameters`,
takže medzery aj diakritika sú správne zakódované:

| Dopyt | Požiadavka |
|---|---|
| prázdny | `/recipes?limit=10&select=name,image,cuisine,prepTimeMinutes,rating` |
| `chicken` | `/recipes/search?q=chicken&select=name,image,cuisine,prepTimeMinutes,rating` |

### Pomalá sieť

`RecipeApi` má vlastnosť `bool slowNetwork` (predvolene `false`). Keď je zapnutá, **každá** požiadavka
(zoznam aj hľadanie) dostane parameter `delay=Random().nextInt(3001)`. UI (`Switch` v AppBare,
`Key('slowNetworkSwitch')`) len prepína hodnotu.

### Počítadlo požiadaviek

Odpovede môžu prísť v inom poradí, ako odišli požiadavky. Každé volanie `_load()` (hľadanie, prvé
načítanie, *Skúsiť znova* aj obnova potiahnutím) dostane poradové číslo a po návrate sa porovná
s najnovším:

```dart
final id = ++_requestCounter;
final recipes = await widget.api.fetchRecipes(query: query, requestId: id);
if (id != _requestCounter) return; // medzitým odišla novšia požiadavka -> zahodiť
setState(() { _recipes = recipes; _loading = false; });
```

Rovnaká kontrola je aj v `catch` – stará chyba nezmení dáta, chybu ani `_loading`. Debounce len znižuje
počet požiadaviek; správnosť zabezpečuje počítadlo (overené widget testom, kde staršia odpoveď príde neskôr).

### Stavy obrazovky

| Stav | Zobrazí sa |
|---|---|
| načítava sa, ešte nie sú dáta | `CircularProgressIndicator` |
| hľadá sa, sú staré výsledky | staré výsledky + tenký `LinearProgressIndicator` pod poľom |
| chyba, nie sú dáta | `ErrorView` so správou a *Skúsiť znova* |
| chyba, sú dáta | staré dáta ostanú, `SnackBar` |
| prázdny výsledok | `EmptyView` – *Pre „xyz“ sa nenašiel žiadny recept.*, dá sa obnoviť potiahnutím |

### Dôkaz – integračný test a log

`integration_test/search_race_test.dart` pracuje so skutočným API: počká na zoznam, zapne *Pomalú sieť*,
rýchlo zadá `p`, `pa`, `pas`, `chick`, `chicken` (pauzy 350 ms), počká na odpovede a overí, že všetky
zobrazené názvy obsahujú „chicken“ (`chick` by vrátil aj *Moroccan Chickpea Tagine*). Nakoniec zadá
`xyzqwe` a overí text prázdneho výsledku.

Test bežal na **Windows desktope** (`-d windows`). Android emulátor na tomto počítači nemá GPU akceleráciu
a má len 2 GB RAM (swapuje), takže aplikácia pri štarte padala a požiadavky končili timeoutom.
Výstup: `proof/etapa2_log_full.txt`, vyfiltrované riadky `[SEARCH]`: `proof/etapa2_log.txt`:

```text
[SEARCH] 11:46:02.378  #2 →  q="p"          delay=1317 ms
[SEARCH] 11:46:02.863  #3 →  q="pa"         delay=552 ms
[SEARCH] 11:46:03.316  #4 →  q="pas"        delay=931 ms
[SEARCH] 11:46:03.748  #5 →  q="chick"      delay=235 ms
[SEARCH] 11:46:03.902  #2 ←  q="p"          23 výsledkov ZAHODENÉ (aktuálna je #5)
[SEARCH] 11:46:04.173  #5 ←  q="chick"      10 výsledkov ZOBRAZENÉ
[SEARCH] 11:46:04.178  #6 →  q="chicken"    delay=804 ms
[SEARCH] 11:46:04.456  #3 ←  q="pa"         8 výsledkov ZAHODENÉ (aktuálna je #6)
[SEARCH] 11:46:04.819  #4 ←  q="pas"        3 výsledky ZAHODENÉ (aktuálna je #6)
[SEARCH] 11:46:05.080  #6 ←  q="chicken"    8 výsledkov ZOBRAZENÉ
```

Odpovede #3 a #4 prišli až **po** novšej #5 – bez počítadla by výsledky „chick“ prepísali staršie
„pa“ a „pas“. Takto sa zahodili a zobrazila sa len posledná #6.

Screenshot `screenshots/etapa2_hladanie.png` uložil `integration_test/screenshots_test.dart`. Na desktope
`flutter screenshot` nefunguje, preto test vykreslí skutočnú aplikáciu (skutočné API) v rozmere
telefónu 400 × 860 a obrázok zapíše do `screenshots/`. Video sa pre preťažený emulátor nerobilo.

## Spustenie

```bash
flutter pub get
flutter run
flutter test                                                  # 7 widget testov
flutter test integration_test/search_race_test.dart -d <id>   # skutočné API, emulátor alebo desktop
```

Pomalú odpoveď sa dá vyskúšať prepínačom *Pomalá sieť* v AppBare.

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

**Etapa 2**

- **Kľúčový prompt** – zadanie hľadania: hľadá server (`Uri` s `queryParameters`, `trim`), prepínač
  *Pomalá sieť* s náhodným `delay` iba v `RecipeApi`, počítadlo požiadaviek, vlastný text prázdneho
  výsledku, logovanie `[SEARCH]`, integračný test so skutočným API, log a video ako dôkaz.
- **Implementácia** – LLM doplnil do `RecipeApi` hľadanie a `slowNetwork`, pridal `search_log.dart`,
  pole na hľadanie, prepínač, počítadlo `_requestCounter` v `_load()` a `EmptyView`. Testy z etapy 1
  ostali, pribudli 3 widget testy (neskorá staršia odpoveď sa zahodí, prázdny výsledok, vymazanie)
  a integračný test.
- **Dôkaz** – LLM najprv spúšťal integračný test na Android emulátore. Ten bol preťažený: zamŕzal
  štart aplikácie, padalo adb a požiadavky končili timeoutom. Pevné čakanie v teste preto nahradil
  čakaním na podmienku, nahrávanie videa vynechal a test spustil na Windows desktope. Tam v logu
  overil, že staršia odpoveď prišla až po novšej a bola zahodená. Na screenshot pridal
  `screenshots_test.dart`, lebo `flutter screenshot` na desktope nefunguje.

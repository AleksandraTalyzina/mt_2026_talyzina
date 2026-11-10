# U5 – Interaktívna obrazovka

**Skupina 1 – Detail receptu.** Obrazovka z U4 (Pasta Carbonara) je oživená: obľúbené, počet porcií
s prepočtom množstiev, odškrtávanie ingrediencií a krokov s priebehom a režim varenia krok po kroku.

## Súbory

| Súbor | Obsah |
|---|---|
| `main.dart` | celá implementácia (`lib/main.dart`), nepotrebuje obrázky ani ďalšie balíčky |
| `widget_test.dart` | 8 widget testov (`test/widget_test.dart`) |
| `01-detail.png` | úvodný stav – 4 porcie, priebeh 0 / 8 |
| `02-porcie-ingrediencie.png` | obľúbené zapnuté, 2 porcie (200 g, 2 pcs, 75 g), 2 odškrtnuté ingrediencie |
| `03-kroky-priebeh.png` | 3 odškrtnuté kroky – priebeh 3 / 8, tlačidlo *Continue cooking (3 / 8)* |
| `04-rezim-varenia.png` | režim varenia pokračuje prvým neodškrtnutým krokom (*Step 4 of 8*) |
| `05-vysledok-spat.png` | po *Finish* sú všetky kroky odškrtnuté (8 / 8), SnackBar, tlačidlo *Cook again* |
| `historia-promptov.txt` | história promptov – export relácie z Claude Code |

## Splnené časti

- **Obľúbené (srdiečko)** – `FavoriteButton` v `SliverAppBar.large`.
- **Počet porcií − 4 +** – `ServingsStepper` (1–12 porcií), množstvá ingrediencií sa prepočítajú.
  *Black pepper* a *Salt* (*to taste*) sa neprepočítavajú, nutričné hodnoty sú *per serving*, preto sa nemenia.
- **Odškrtávanie ingrediencií a krokov** – ťuknutie na kartu ingrediencie, `CheckboxListTile` pri krokoch,
  odškrtnuté položky sú prečiarknuté. Pri *Method* je priebeh `3 / 8` a `LinearProgressIndicator`.
- **Start cooking** – `CookingPage` ukazuje jeden krok, *Back* / *Next*, na poslednom kroku *Finish*.

## Stav čo najnižšie, spoločný stav u rodiča

| Stav | Kde | Prečo |
|---|---|---|
| obľúbené `_isFavorite` | `FavoriteButton` | nikto iný ho nepotrebuje |
| odškrtnuté ingrediencie `_checked` | `IngredientSection` | potrebuje ho len zoznam ingrediencií; nie je v karte, lebo `ListView` karty mimo obrazovky zahodí a stav by sa stratil |
| počet porcií `_servings` | `RecipeDetailPage` | spoločný – číta ho stepper aj zoznam ingrediencií |
| hotové kroky `_doneSteps` | `RecipeDetailPage` | spoločný – karty krokov, priebeh 3 / 8, text tlačidla aj výsledok z režimu varenia |
| aktuálny krok `_current` | `CookingPage` | pozná ho len režim varenia |

Deti stav nemenia priamo – dostanú hodnotu a **callback** (`onChanged`, `onToggle`) a zmenu urobí rodič cez `setState`.

## Kontrolovaný vstup

`ServingsStepper` je `StatelessWidget` bez vlastnej hodnoty: číslo dostane od rodiča (`value`) a ťuknutie
na − / + len ohlási cez `onChanged(value ± 1)`. Rovnako `Checkbox` pri krokoch – `value` je z `_doneSteps`,
zmena ide cez `onToggle`.

## Navigácia – dáta tam, výsledok späť

```dart
final done = await Navigator.push<int>(context, MaterialPageRoute(
  builder: (context) => CookingPage(title: ..., steps: ..., startStep: ...),
));
```

- **tam:** názov receptu, zoznam všetkých krokov a prvý neodškrtnutý krok (odtiaľ sa pokračuje),
- **späť:** počet hotových krokov – *Finish* vráti 8, zatvorenie (✕) vráti počet krokov pred aktuálnym,
  systémové tlačidlo späť vráti `null` a nič sa nezmení,
- rodič hotové kroky odškrtne a ukáže SnackBar (*Bon appétit!* alebo *Paused at step …*).

## Čo sa počíta, neukladá do stavu

- prepočítané množstvá – `ingredient.amountFor(_servings / recipe.baseServings)`,
- priebeh `3 / 8` a hodnota progress baru – z `_doneSteps.length` a `allSteps.length`,
- čísla krokov – prvý krok každej sekcie sa spočíta v cykle (v U4 boli natvrdo `1` a `4`),
- prvý neodškrtnutý krok a text tlačidla (*Start cooking* / *Continue cooking (3 / 8)* / *Cook again*).

## Spustenie

`main.dart` stačí vložiť do `lib/` ľubovoľného Flutter projektu. Testy patria do `test/` – v importe
`package:recipe_detail/main.dart` treba nahradiť názov balíčka názvom projektu.

## Použitie LLM

Použitý nástroj: **Claude Code** (Anthropic, model Claude Opus 5.5) ako asistent priamo vo VS Code.

- **Analýza zadania** – zo slajdu a z kódu U4 LLM navrhol postup krok za krokom, hlavne rozhodnutie,
  kde má byť ktorý stav a čo sa má počítať.
- **Implementácia** – na požiadanie LLM upravil kód z U4: model (`quantity` + `unit`, `baseServings`, `allSteps`),
  `StatefulWidget` pre stránku, stepper, odškrtávanie, `CookingPage` s návratovou hodnotou.
  Pri písaní popisu presunul stav odškrtnutých ingrediencií nižšie – z `RecipeDetailPage` do `IngredientSection`.
- **Kontrola** – `flutter analyze` bez chýb, 8 widget testov (prepočet porcií, srdiečko, odškrtávanie,
  režim varenia: *Finish*, zatvorenie, systémové späť).
- **Screenshoty** – vygenerované widget testom, ktorý vykreslí aplikáciu do PNG (veľkosť telefónu 390 × 844,
  písmo Roboto, bez pásky DEBUG).
- **Odovzdanie** – LLM pripravil tento popis a súbory v `ulohy/u5/`.

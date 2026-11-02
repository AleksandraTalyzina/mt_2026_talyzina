# U3 – Implementácia obrazovky podľa návodu

Obrazovka podľa tutoriálu *Build a Flutter layout* s úpravami z cvičenia 4.

## Súbory

| Súbor | Obsah |
|---|---|
| `main.dart` | celá implementácia (`lib/main.dart`) |
| `01-telefon-svetly.png` | telefón, svetlý režim |
| `02-telefon-tmavy.png` | telefón, tmavý režim |
| `03-na-sirku.png` | široká obrazovka – obrázok vľavo, text vpravo |
| `04-interakcia.png` | po ťuknutí na hviezdičku (41 → 40) a na SHARE (SnackBar) |

Obrázok je v projekte ako `images/lake.jpg` a je zaregistrovaný v `pubspec.yaml`.

## Splnené časti

- **Obrazovka z návodu** – `ImageSection`, `TitleSection`, `ButtonSection` + `ButtonWithText`, `TextSection`.
- **Material 3** – téma z `ColorScheme.fromSeed(seedColor: Colors.teal)`, `darkTheme` a `themeMode: ThemeMode.system`.
  Farby (`primary`, `onSurfaceVariant`) aj písmo (`titleMedium`, `bodyMedium`) sa berú z témy, medzi textami je `spacing: 8`.
- **FavoriteWidget** – `StatefulWidget` s `IconButton`, ťuknutie prepne hviezdičku a zmení počet.

## Rozšírenia (krok 9)

1. **Tlačidlá s akciou** – `ButtonWithText` je zabalený v `InkWell`, po ťuknutí sa zobrazí `SnackBar`.
2. **Model** – trieda `Place` (názov, lokalita, obrázok, popis) a widget `PlaceDetailPage(place: …)`.
3. **Na šírku** – `LayoutBuilder` v `PlaceDetailPage`: pri šírke ≥ 600 je obrázok vľavo a text vpravo v `Row`, inak pôvodný stĺpec.

## Použitie LLM

Použitý nástroj: **Claude Code** (Anthropic) ako asistent priamo vo VS Code.

- **Prostredie** – pomoc s opravou `flutter doctor`: doinštalovanie C++ komponentov Visual Studia, Android SDK a emulátora.
- **Kroky 1–5** – kód zo slajdov sa vkladal ručne. LLM opravoval chyby po vložení (zátvorky, formátovanie), doplnil chýbajúcu triedu `ButtonWithText`, stiahol `lake.jpg` a zaregistroval ho v `pubspec.yaml`.
- **Kroky 6, 7 a 9** – na požiadanie ich podľa slajdov implementoval LLM. Rozšírenia vybral tak, aby fungovali s jednou fotkou.
- **Kontrola** – `flutter analyze` bez chýb, 5 widget testov (obsah, hviezdička, SnackBar, úzke a široké rozloženie) a screenshoty z prehliadača.

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

const String appTitle = 'Flutter layout demo';

class Place {
  const Place({
    required this.name,
    required this.location,
    required this.image,
    required this.description,
  });

  final String name;
  final String location;
  final String image;
  final String description;
}

const Place oeschinenLake = Place(
  name: 'Oeschinen Lake Campground',
  location: 'Kandersteg, Switzerland',
  image: 'images/lake.jpg',
  description:
      'Lake Oeschinen lies at the foot of the Blüemlisalp in '
      'the Bernese Alps. Situated 1,578 meters above sea '
      'level, it is one of the larger Alpine Lakes. A gondola '
      'ride from Kandersteg, followed by a half-hour walk '
      'through pastures and pine forest, leads you to the '
      'lake, which warms to 20 degrees Celsius in the summer. '
      'Activities enjoyed here include rowing, and riding the '
      'summer toboggan run.',
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const PlaceDetailPage(place: oeschinenLake),
    );
  }
}

class PlaceDetailPage extends StatelessWidget {
  const PlaceDetailPage({super.key, required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    final details = [
      TitleSection(name: place.name, location: place.location),
      const ButtonSection(),
      TextSection(description: place.description),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text(appTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: ImageSection(image: place.image)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: details),
                  ),
                ),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                ImageSection(image: place.image),
                ...details,
              ],
            ),
          );
        },
      ),
    );
  }
}

class TitleSection extends StatelessWidget {
  const TitleSection({super.key, required this.name, required this.location});
  final String name;
  final String location;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Text(name, style: text.titleMedium),
                Text(
                  location,
                  style: text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const FavoriteWidget(),
        ],
      ),
    );
  }
}

class FavoriteWidget extends StatefulWidget {
  const FavoriteWidget({super.key});

  @override
  State<FavoriteWidget> createState() => _FavoriteWidgetState();
}

class _FavoriteWidgetState extends State<FavoriteWidget> {
  bool _isFavorited = true;
  int _count = 41;

  void _toggleFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
      _count += _isFavorited ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isFavorited ? Icons.star : Icons.star_border),
          color: Theme.of(context).colorScheme.primary,
          onPressed: _toggleFavorite,
        ),
        Text('$_count'),
      ],
    );
  }
}

class ButtonSection extends StatelessWidget {
  const ButtonSection({super.key});
  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ButtonWithText(color: color, icon: Icons.call, label: 'CALL'),
        ButtonWithText(color: color, icon: Icons.near_me, label: 'ROUTE'),
        ButtonWithText(color: color, icon: Icons.share, label: 'SHARE'),
      ],
    );
  }
}

class ButtonWithText extends StatelessWidget {
  const ButtonWithText({
    super.key,
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$label tapped'))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            Icon(icon, color: color),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TextSection extends StatelessWidget {
  const TextSection({super.key, required this.description});
  final String description;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Text(description, softWrap: true),
    );
  }
}

class ImageSection extends StatelessWidget {
  const ImageSection({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    return Image.asset(image, width: 600, height: 240, fit: BoxFit.cover);
  }
}

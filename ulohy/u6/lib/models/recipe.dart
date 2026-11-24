class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.image,
    required this.cuisine,
    required this.prepTimeMinutes,
    required this.rating,
  });

  final int id;
  final String name;
  final String image;
  final String cuisine;
  final int prepTimeMinutes;
  final double rating;

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as int,
      name: json['name'] as String,
      image: json['image'] as String,
      cuisine: json['cuisine'] as String,
      prepTimeMinutes: json['prepTimeMinutes'] as int,
      // can come as 5 instead of 5.0
      rating: (json['rating'] as num).toDouble(),
    );
  }
}

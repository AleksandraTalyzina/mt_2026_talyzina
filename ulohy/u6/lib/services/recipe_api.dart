import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/recipe.dart';

class RecipeApiException implements Exception {
  const RecipeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The only class that knows the URL and the JSON format.
class RecipeApi {
  static const _url =
      'https://dummyjson.com/recipes?limit=10&select=name,image,cuisine,prepTimeMinutes,rating';

  Future<List<Recipe>> fetchRecipes() async {
    final http.Response response;
    try {
      response = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const RecipeApiException(
        'Server neodpovedá. Skúste to o chvíľu znova.',
      );
    } on http.ClientException {
      throw const RecipeApiException(
        'Nepodarilo sa pripojiť k serveru. Skontrolujte internetové pripojenie.',
      );
    }

    if (response.statusCode != 200) {
      throw RecipeApiException(
        'Server vrátil chybu ${response.statusCode}. Skúste to neskôr.',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['recipes'] as List<dynamic>;
    return list
        .map((item) => Recipe.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

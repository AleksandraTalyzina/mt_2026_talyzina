import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/recipe.dart';
import 'search_log.dart';

class RecipeApiException implements Exception {
  const RecipeApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The only class that knows the URL and the JSON format.
class RecipeApi {
  static const _fields = 'name,image,cuisine,prepTimeMinutes,rating';

  /// When true, every request gets a random delay of 0–3000 ms.
  bool slowNetwork = false;

  final _random = Random();

  /// Empty [query] -> first 10 recipes, otherwise the server searches.
  /// [requestId] is only used in the log.
  Future<List<Recipe>> fetchRecipes({
    String query = '',
    int requestId = 0,
  }) async {
    final q = query.trim();
    final params = q.isEmpty
        ? {'limit': '10', 'select': _fields}
        : {'q': q, 'select': _fields};

    var delayText = 'delay=-';
    if (slowNetwork) {
      final delay = _random.nextInt(3001);
      params['delay'] = '$delay';
      delayText = 'delay=$delay ms';
    }

    // Uri encodes spaces and diacritics in the query
    final uri = Uri.https(
      'dummyjson.com',
      q.isEmpty ? '/recipes' : '/recipes/search',
      params,
    );
    logSearch(requestId, '→', q, delayText);

    final http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 10));
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

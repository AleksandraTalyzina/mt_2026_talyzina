import 'package:flutter/foundation.dart';

/// Prints one aligned log line, e.g.
/// `[SEARCH] 10:41:02.120  #3 →  q="pas"         delay=2140 ms`
void logSearch(int id, String arrow, String query, String rest) {
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  final time =
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}'
      '.${now.millisecond.toString().padLeft(3, '0')}';
  final q = 'q="$query"'.padRight(14);
  debugPrint('[SEARCH] $time  #$id $arrow  $q $rest');
}

/// 1 výsledok, 2–4 výsledky, 0 / 5+ výsledkov
String countResults(int n) {
  if (n == 1) return '1 výsledok';
  if (n >= 2 && n <= 4) return '$n výsledky';
  return '$n výsledkov';
}

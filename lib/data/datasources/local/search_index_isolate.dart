// Top-level functions for search index build and search - run in isolate to avoid ANR.
// All inputs/outputs must be sendable (primitive types, List, Map with sendable values).

String _normalizeTextIsolate(String text) {
  final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  if (hasArabic) return text;
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF\u0400-\u04FF]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

/// Input: list of maps with keys: arabicText, transliteration, ayatiText, alomuddin, pioneers, khojamirov, farsi, russianKuliev, surahId, verseNumber.
/// Output: list of maps with keys: arabic, translit, tajik, tj2, tj3, farsi, russian, surahId, verseNumber.
List<Map<String, dynamic>> buildSearchIndexInIsolate(List<Map<String, dynamic>> verseTexts) {
  final result = <Map<String, dynamic>>[];
  for (final v in verseTexts) {
    result.add({
      'arabic': v['arabicText'] as String? ?? '',
      'translit': _normalizeTextIsolate((v['transliteration'] as String?) ?? ''),
      'ayati': _normalizeTextIsolate((v['ayatiText'] as String?) ?? ''),
      'alomuddin': _normalizeTextIsolate((v['alomuddin'] as String?) ?? ''),
      'pioneers': _normalizeTextIsolate((v['pioneers'] as String?) ?? ''),
      'khojamirov': _normalizeTextIsolate((v['khojamirov'] as String?) ?? ''),
      'farsi': _normalizeTextIsolate((v['farsi'] as String?) ?? ''),
      'russianKuliev': _normalizeTextIsolate((v['russianKuliev'] as String?) ?? ''),
      'surahId': v['surahId'] as int,
      'verseNumber': v['verseNumber'] as int,
    });
  }
  return result;
}

double _relevanceIsolate(String text, String query, bool isExact, bool isStart) {
  if (isExact) return 100;
  if (isStart) return 80;
  if (text.toLowerCase().contains(query.toLowerCase())) return 60;
  return 40;
}

/// Params: indexRows (List<Map>), normalizedQuery (String), query (String), queryHasArabic (bool),
/// language (String), surahId (int?), maxResults (int).
/// Returns: List<Map> with keys index, relevance, matchedFields (List<String>).
List<Map<String, dynamic>> searchVersesWithFieldsInIsolate(Map<String, dynamic> params) {
  final indexRows = params['indexRows'] as List<Map<String, dynamic>>;
  final normalizedQuery = params['normalizedQuery'] as String;
  final query = params['query'] as String;
  final queryHasArabic = params['queryHasArabic'] as bool;
  final language = params['language'] as String;
  final surahId = params['surahId'] as int?;
  final maxResults = params['maxResults'] as int;
  final queryLower = query.toLowerCase();

  final results = <Map<String, dynamic>>[];
  for (var i = 0; i < indexRows.length; i++) {
    final row = indexRows[i];
    if (surahId != null && (row['surahId'] as int) != surahId) continue;

    double relevance = 0;
    final matchedFields = <String>[];
    bool matches = false;
    final lang = language.toLowerCase();

    void addMatch(String field, String text, {double scale = 1.0}) {
      if (text.contains(normalizedQuery)) {
        final isExact = text == normalizedQuery;
        final isStart = text.startsWith(normalizedQuery);
        relevance += _relevanceIsolate(text, query, isExact, isStart) * scale;
        matchedFields.add(field);
        matches = true;
      }
    }

    switch (lang) {
      case 'arabic':
        addMatch('arabicText', row['arabic'] as String);
        break;
      case 'transliteration':
        addMatch('transliteration', row['translit'] as String);
        break;
      case 'tajik_ayati':
        addMatch('ayatiText', row['ayati'] as String);
        break;
      case 'tajik_alomuddin':
        addMatch('alomuddin', row['alomuddin'] as String);
        break;
      case 'tajik_pioneers':
        addMatch('pioneers', row['pioneers'] as String);
        break;
      case 'tajik_khojamirov':
        addMatch('khojamirov', row['khojamirov'] as String);
        break;
      case 'farsi':
        addMatch('farsi', row['farsi'] as String);
        break;
      case 'russian_kuliev':
        addMatch('russianKulievText', row['russianKuliev'] as String);
        break;
      case 'both':
      default:
        if (queryHasArabic) {
          addMatch('arabicText', row['arabic'] as String);
          if (!matches) addMatch('transliteration', row['translit'] as String, scale: 0.8);
        } else {
          addMatch('arabicText', row['arabic'] as String);
          addMatch('transliteration', row['translit'] as String);
          addMatch('ayatiText', row['ayati'] as String);
          addMatch('alomuddin', row['alomuddin'] as String);
          addMatch('pioneers', row['pioneers'] as String);
          addMatch('khojamirov', row['khojamirov'] as String);
          addMatch('farsi', row['farsi'] as String);
          addMatch('russianKuliev', row['russianKuliev'] as String);
        }
        break;
    }

    if (matches && queryHasArabic) {
      final arabic = row['arabic'] as String;
      if (!arabic.contains(query)) {
        matches = false;
        relevance = 0;
        matchedFields.clear();
      }
    }

    if (matches && relevance > 0) {
      results.add({'index': i, 'relevance': relevance, 'matchedFields': matchedFields});
      if (results.length >= maxResults) break;
    }
  }

  results.sort((a, b) {
    final relA = a['relevance'] as double;
    final relB = b['relevance'] as double;
    if (relA != relB) return relB.compareTo(relA);
    final rowA = indexRows[a['index'] as int];
    final rowB = indexRows[b['index'] as int];
    final surahA = rowA['surahId'] as int;
    final surahB = rowB['surahId'] as int;
    if (surahA != surahB) return surahA.compareTo(surahB);
    return (rowA['verseNumber'] as int).compareTo(rowB['verseNumber'] as int);
  });

  return results;
}

/// Params: indexRows, normalizedQuery, query, queryHasArabic, language, surahId.
/// Returns: List<int> indices (max 200).
List<int> searchVersesInIsolate(Map<String, dynamic> params) {
  final indexRows = params['indexRows'] as List<Map<String, dynamic>>;
  final normalizedQuery = params['normalizedQuery'] as String;
  final query = params['query'] as String;
  final queryLower = query.toLowerCase();
  final queryHasArabic = params['queryHasArabic'] as bool;
  final language = params['language'] as String;
  final surahId = params['surahId'] as int?;
  const maxResults = 200;

  final indices = <int>[];
  for (var i = 0; i < indexRows.length; i++) {
    final row = indexRows[i];
    if (surahId != null && (row['surahId'] as int) != surahId) continue;

    bool matches = false;
    final lang = language.toLowerCase();
    bool contains(String key) => (row[key] as String).contains(normalizedQuery);

    switch (lang) {
      case 'arabic':
        matches = contains('arabic');
        break;
      case 'transliteration':
        matches = contains('translit');
        break;
      case 'tajik_ayati':
        matches = contains('ayati');
        break;
      case 'tajik_alomuddin':
        matches = contains('alomuddin');
        break;
      case 'tajik_pioneers':
        matches = contains('pioneers');
        break;
      case 'tajik_khojamirov':
        matches = contains('khojamirov');
        break;
      case 'farsi':
        matches = contains('farsi');
        break;
      case 'russian_kuliev':
        matches = contains('russianKuliev');
        break;
      case 'both':
      default:
        if (queryHasArabic) {
          matches = contains('arabic') || contains('translit');
        } else {
          matches = contains('arabic') || contains('translit') || contains('ayati') ||
              contains('alomuddin') || contains('pioneers') || contains('khojamirov') || contains('farsi') || contains('russianKuliev');
        }
        break;
    }

    if (matches && queryHasArabic && !(row['arabic'] as String).contains(query)) {
      matches = false;
    }
    if (matches) {
      indices.add(i);
      if (indices.length >= maxResults) break;
    }
  }
  // Sort by exact match first, then surah, then verse number
  indices.sort((a, b) {
    final rowA = indexRows[a];
    final rowB = indexRows[b];
    bool exactA = (rowA['arabic'] as String).toLowerCase().contains(queryLower) ||
        (rowA['translit'] as String).toLowerCase().contains(queryLower) ||
        (rowA['ayati'] as String).toLowerCase().contains(queryLower);
    bool exactB = (rowB['arabic'] as String).toLowerCase().contains(queryLower) ||
        (rowB['translit'] as String).toLowerCase().contains(queryLower) ||
        (rowB['ayati'] as String).toLowerCase().contains(queryLower);
    if (exactA && !exactB) return -1;
    if (!exactA && exactB) return 1;
    final surahA = rowA['surahId'] as int;
    final surahB = rowB['surahId'] as int;
    if (surahA != surahB) return surahA.compareTo(surahB);
    return (rowA['verseNumber'] as int).compareTo(rowB['verseNumber'] as int);
  });
  return indices;
}

/// Params: entries (List<Map> with translit, tajik, originalTranslit, originalTajik), qNorm (String).
/// Returns: List<String> suggestions (sorted).
List<String> getSearchSuggestionsInIsolate(Map<String, dynamic> params) {
  final entries = params['entries'] as List<Map<String, dynamic>>;
  final qNorm = params['qNorm'] as String;
  final suggestions = <String>{};

  void takeWords(String normalizedSource, String originalSource) {
    if (normalizedSource.isEmpty || originalSource.isEmpty) return;
    final words = originalSource.split(RegExp(r'\s+'));
    for (final word in words) {
      if (suggestions.length >= 20) break;
      final nw = _normalizeTextIsolate(word);
      if (nw.length >= 3 && nw.contains(qNorm)) {
        suggestions.add(word.trim());
      }
    }
  }

  for (final entry in entries) {
    if (suggestions.length >= 20) break;
    takeWords(
      entry['translit'] as String,
      entry['originalTranslit'] as String,
    );
    takeWords(
      entry['ayati'] as String,
      entry['originalAyati'] as String,
    );
  }

  final list = suggestions.toList()..sort();
  return list;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:drift/drift.dart';
import '../../models/verse_model.dart';
import '../../models/surah_model.dart';
import '../../models/search_result_model.dart';
import '../../providers/quran_database_provider.dart';
import 'drift/database.dart';
import 'drift_verse_datasource.dart';
import '../../../core/utils/search_query_parser.dart';

final driftSearchDataSourceProvider = Provider<DriftSearchDataSource>((ref) {
  final db = ref.watch(quranDatabaseProvider);
  final verseDS = ref.watch(driftVerseDataSourceProvider);
  return DriftSearchDataSource(db, verseDS);
});

class DriftSearchDataSource {
  final AppDatabase _db;
  final DriftVerseDataSource _verseDataSource;

  static const String _recentTermsKey = 'recent_search_terms';
  static const String _recentNavigationsKey = 'quran_recent_navigations';

  DriftSearchDataSource(this._db, this._verseDataSource);

  // Normalize text for search input
  String _normalizeQuery(String text) {
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    if (hasArabic) {
      return text;
    }
    // Remove non-alphanumeric, but keep space
    return text.replaceAll(RegExp(r'[^\w\s\u0400-\u04FF]'), '').trim();
  }

  // FTS5 MATCH query syntax requires wrapping in quotes or appending *
  String _buildFtsQuery(String query) {
    final parts = query.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '""';
    // Append * to each word for prefix matching
    return parts.map((p) => '"$p"*').join(' AND ');
  }

  // Fast lookups to avoid loading 6236 verses into memory for direct navigation
  Future<bool> isValidVerse(int surahId, int verseId) async {
    final query = _db.select(_db.verses)
      ..where((v) => v.surahId.equals(surahId) & v.verseId.equals(verseId))
      ..limit(1);
    final results = await query.get();
    return results.isNotEmpty;
  }

  Future<VerseModel?> getFirstVerseOfJuz(int juzNumber) async {
    final query = _db.select(_db.verses)
      ..where((v) => v.juz.equals(juzNumber))
      ..orderBy([(v) => OrderingTerm(expression: v.verseId)])
      ..limit(1);
    final results = await query.get();
    if (results.isEmpty) return null;

    final sId = results.first.surahId;
    final vId = results.first.verseId;
    return await _verseDataSource.getVerseByKey('$sId:$vId');
  }

  Future<VerseModel?> getFirstVerseOfPage(int pageNumber) async {
    final query = _db.select(_db.verses)
      ..where((v) => v.page.equals(pageNumber))
      ..orderBy([(v) => OrderingTerm(expression: v.verseId)])
      ..limit(1);
    final results = await query.get();
    if (results.isEmpty) return null;

    final sId = results.first.surahId;
    final vId = results.first.verseId;
    return await _verseDataSource.getVerseByKey('$sId:$vId');
  }

  Future<List<VerseModel>> getAllVerses() async {
    return await _verseDataSource.getAllVersesCached();
  }

  Future<List<VerseModel>> searchVerses(
    String query, {
    String language = 'both',
    int? surahId,
  }) async {
    final normQuery = _normalizeQuery(query);
    if (normQuery.isEmpty || normQuery.length < 2) return [];

    final matchQuery = _buildFtsQuery(normQuery);

    String sql = '''
      SELECT DISTINCT m.surah_id AS surah_id, m.verse_id AS verse_id
      FROM search_index s
      JOIN search_mapping m ON s.rowid = m.id
      WHERE s.search_index MATCH ?
    ''';

    final args = <dynamic>[matchQuery];

    if (surahId != null) {
      sql += ' AND m.surah_id = ?';
      args.add(surahId);
    }

    sql += ' ORDER BY m.surah_id, m.verse_id LIMIT 200';

    final results = await _db
        .customSelect(sql, variables: args.map((a) => Variable(a)).toList())
        .get();

    // Now load full VerseModels for the matched surah/verse pairs
    final List<VerseModel> matchedVerses = [];
    for (final row in results) {
      final sId = row.read<int>('surah_id');
      final vId = row.read<int>('verse_id');

      final verse = await _verseDataSource.getVerseByKey('$sId:$vId');
      if (verse != null) {
        matchedVerses.add(verse);
      }
    }

    return matchedVerses;
  }

  Future<Map<String, int>?> getFirstVerseLocationOfPage(int page) async {
    final sql =
        'SELECT surah_id, verse_id FROM verses WHERE page = ? ORDER BY surah_id, verse_id LIMIT 1';
    final results =
        await _db.customSelect(sql, variables: [Variable(page)]).get();
    if (results.isEmpty) return null;
    return {
      'surah_id': results.first.read<int>('surah_id'),
      'verse_id': results.first.read<int>('verse_id'),
    };
  }

  Future<Map<String, int>?> getFirstVerseLocationOfJuz(int juz) async {
    final sql =
        'SELECT surah_id, verse_id FROM verses WHERE juz = ? ORDER BY surah_id, verse_id LIMIT 1';
    final results =
        await _db.customSelect(sql, variables: [Variable(juz)]).get();
    if (results.isEmpty) return null;
    return {
      'surah_id': results.first.read<int>('surah_id'),
      'verse_id': results.first.read<int>('verse_id'),
    };
  }

  Future<int> countSearchVerses(
    String query, {
    String language = 'both',
    int? surahId,
  }) async {
    final normQuery = _normalizeQuery(query);
    if (normQuery.isEmpty || normQuery.length < 2) return 0;

    final matchQuery = _buildFtsQuery(normQuery);
    final resourceFilter = _mapLanguageToResourceId(language);

    String sql = '''
      SELECT COUNT(DISTINCT m.surah_id || '-' || m.verse_id) as count
      FROM search_index s
      JOIN search_mapping m ON s.rowid = m.id
      WHERE s.search_index MATCH ?
    ''';

    final args = <dynamic>[matchQuery];

    if (resourceFilter != null) {
      sql += ' AND m.resource_id = ?';
      args.add(resourceFilter);
    }

    if (surahId != null) {
      sql += ' AND m.surah_id = ?';
      args.add(surahId);
    }

    final results = await _db
        .customSelect(sql, variables: args.map((a) => Variable(a)).toList())
        .get();
    if (results.isEmpty) return 0;
    return results.first.read<int>('count');
  }

  Future<List<SearchResult>> searchVersesWithFields(
    String query, {
    String language = 'both',
    int? surahId,
    int limit = 30,
    int offset = 0,
  }) async {
    final normQuery = _normalizeQuery(query);
    if (normQuery.isEmpty || normQuery.length < 2) return [];

    final matchQuery = _buildFtsQuery(normQuery);

    final resourceFilter = _mapLanguageToResourceId(language);

    // FTS5 bm25 ranking with GROUP BY to guarantee unique verses per page
    // We use the hidden s.rank column provided by FTS5 to avoid "unable to use function bm25" errors
    // We select s.rank directly without MIN() because SQLite allows selecting non-grouped columns and it avoids aggregate issues
    String sql = '''
      SELECT m.surah_id AS surah_id, m.verse_id AS verse_id, group_concat(m.resource_id) AS resource_ids, s.rank as rank 
      FROM search_index s
      JOIN search_mapping m ON s.rowid = m.id
      WHERE s.search_index MATCH ?
    ''';

    final args = <dynamic>[matchQuery];

    if (resourceFilter != null) {
      sql += ' AND m.resource_id = ?';
      args.add(resourceFilter);
    }

    if (surahId != null) {
      sql += ' AND m.surah_id = ?';
      args.add(surahId);
    }

    sql += ' GROUP BY m.surah_id, m.verse_id ORDER BY rank LIMIT ? OFFSET ?';
    args.add(limit);
    args.add(offset);

    final results = await _db
        .customSelect(sql, variables: args.map((a) => Variable(a)).toList())
        .get();

    // Group by verse
    final Map<String, Map<String, dynamic>> verseMap = {};
    for (final row in results) {
      final sId = row.read<int>('surah_id');
      final vId = row.read<int>('verse_id');
      final resourceIds = row.read<String>('resource_ids').split(',');
      final rank = row.read<double>('rank');

      final key = '$sId:$vId';

      final uiFields = <String>{};
      for (final rId in resourceIds) {
        uiFields.add(_mapResourceIdToLanguage(rId));
      }

      verseMap[key] = {
        'surah_id': sId,
        'verse_id': vId,
        'rank': rank,
        'fields': uiFields.toList(),
      };
    }

    // Sort by surah and verse
    final sortedKeys = verseMap.keys.toList()
      ..sort((a, b) {
        final surahA = verseMap[a]!['surah_id'] as int;
        final surahB = verseMap[b]!['surah_id'] as int;
        if (surahA != surahB) return surahA.compareTo(surahB);

        final verseA = verseMap[a]!['verse_id'] as int;
        final verseB = verseMap[b]!['verse_id'] as int;
        return verseA.compareTo(verseB);
      });

    final searchResults = <SearchResult>[];

    // Bulk fetch all verses to eliminate sequential SQLite queries
    final verses = await _verseDataSource.getVersesBulk(sortedKeys);

    // Create a map for quick lookup
    final verseModelsMap = <String, VerseModel>{};
    for (final v in verses) {
      verseModelsMap[v.uniqueKey] = v;
    }

    for (final key in sortedKeys) {
      final data = verseMap[key]!;
      final verse = verseModelsMap[key];
      if (verse != null) {
        searchResults.add(SearchResult(
          type: SearchResultType.verse,
          data: verse,
          relevance: -(data['rank'] as double), // invert to positive
          matchedFields: data['fields'] as List<String>,
        ));
      }
    }

    return searchResults;
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];
    final matchQuery = _buildFtsQuery(_normalizeQuery(query));

    // We only fetch translit and ayati for suggestions
    final sql = '''
      SELECT t.text as content
      FROM search_index s
      JOIN search_mapping m ON s.rowid = m.id
      JOIN translations t ON m.surah_id = t.surah_id AND m.verse_id = t.verse_id AND m.resource_id = t.resource_id
      WHERE s.search_index MATCH ?
      AND m.resource_id IN ('transliteration', 'tj_ayati')
      LIMIT 10
    ''';

    final results =
        await _db.customSelect(sql, variables: [Variable(matchQuery)]).get();

    return results.map((r) => r.read<String>('content')).toList();
  }

  String? _mapLanguageToResourceId(String language) {
    switch (language) {
      case 'arabic':
        return 'quran_arabic';
      case 'transliteration':
        return 'transliteration';
      case 'tajik_ayati':
        return 'tj_ayati';
      case 'tajik_alomuddin':
        return 'tj_alomuddin';
      case 'tajik_pioneers':
        return 'tj_pioneers';
      case 'tajik_khojamirov':
        return 'tj_khojamirov';
      case 'farsi':
        return 'fa_translation';
      case 'russian_kuliev':
        return 'ru_kuliev';
      default:
        return null; // both or unknown
    }
  }

  String _mapResourceIdToLanguage(String resourceId) {
    switch (resourceId) {
      case 'quran_arabic':
      case 'arabicText':
        return 'arabicText';
      case 'transliteration':
        return 'transliteration';
      case 'tj_ayati':
        return 'tajik_ayati';
      case 'tj_alomuddin':
        return 'tajik_alomuddin';
      case 'tj_pioneers':
        return 'tajik_pioneers';
      case 'tj_khojamirov':
        return 'tajik_khojamirov';
      case 'fa_translation':
        return 'farsi';
      case 'ru_kuliev':
        return 'russian_kuliev';
      default:
        return resourceId;
    }
  }

  Future<void> saveSearchedTerm(String term, {int maxItems = 20}) async {
    final normalized = term.trim();
    if (normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing =
        prefs.getStringList(_recentTermsKey) ?? <String>[];
    existing.removeWhere((t) => t.toLowerCase() == normalized.toLowerCase());
    existing.insert(0, normalized);
    if (existing.length > maxItems) {
      existing.removeRange(maxItems, existing.length);
    }
    await prefs.setStringList(_recentTermsKey, existing);
  }

  Future<List<String>> getRecentSearchedTerms({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existing =
        prefs.getStringList(_recentTermsKey) ?? <String>[];
    if (existing.length <= limit) return existing;
    return existing.sublist(0, limit);
  }

  Future<void> saveRecentNavigation({
    required String label,
    required String href,
    required String type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentNavigationsKey) ?? [];

      saved.removeWhere((item) {
        try {
          final parts = item.split('|');
          return parts.length > 1 && parts[1] == href;
        } catch (e) {
          return false;
        }
      });

      saved.insert(0, '$label|$href|$type');
      if (saved.length > 10) saved.removeRange(10, saved.length);
      await prefs.setStringList(_recentNavigationsKey, saved);
    } catch (e) {}
  }

  Future<List<Map<String, String>>> getRecentNavigations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_recentNavigationsKey) ?? [];

      return saved.map((item) {
        final parts = item.split('|');
        return {
          'label': parts.isNotEmpty ? parts[0] : '',
          'href': parts.length > 1 ? parts[1] : '',
          'type': parts.length > 2 ? parts[2] : '',
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<SearchResult>> searchSurahs(
    List<SurahModel> surahs,
    String query, {
    String language = 'both',
  }) async {
    if (query.trim().isEmpty || query.trim().length < 2) return [];

    // Normalize the query using Tajik normalization
    final normQuery = SearchQueryParser.normalizeTajik(query);
    if (normQuery.isEmpty) return [];

    final results = <SearchResult>[];

    for (final surah in surahs) {
      double relevance = 0;
      final matchedFields = <String>{};

      // Tajik name matching using normalized names
      if (language == 'both' ||
          language.startsWith('tajik_') ||
          language == 'russian_kuliev') {
        final normSurahName = SearchQueryParser.normalizeTajik(surah.nameTajik);
        if (normSurahName == normQuery) {
          relevance = 100;
          matchedFields.add('nameTajik');
        } else if (normSurahName.startsWith(normQuery)) {
          relevance = 80;
          matchedFields.add('nameTajik');
        } else if (normSurahName.contains(normQuery)) {
          relevance = 60;
          matchedFields.add('nameTajik');
        }
      }

      // English name matching (e.g. "Al-Fatiha", "Fatiha")
      if (language == 'both' || language.startsWith('tajik_')) {
        final engLower = surah.nameEnglish.toLowerCase();
        if (engLower.isNotEmpty) {
          final engStripped =
              engLower.replaceFirst(RegExp(r'^al-?'), '').trim();
          if (engLower == normQuery || engStripped == normQuery) {
            if (relevance < 90) relevance = 90;
            matchedFields.add('nameEnglish');
          } else if (engLower.contains(normQuery) ||
              engStripped.contains(normQuery)) {
            if (relevance < 55) relevance = 55;
            matchedFields.add('nameEnglish');
          }
        }
      }

      // Arabic name matching
      if (language == 'both' || language == 'arabic') {
        if (surah.nameArabic.contains(query)) {
          final arabicScore = surah.nameArabic == query ? 100.0 : 60.0;
          if (relevance < arabicScore) relevance = arabicScore;
          matchedFields.add('nameArabic');
        }
      }

      // Surah number matching (exact only)
      if (language == 'both' && surah.number.toString() == query.trim()) {
        if (relevance < 70) relevance = 70;
        matchedFields.add('number');
      }

      if (relevance > 0) {
        results.add(SearchResult(
          type: SearchResultType.surah,
          data: surah,
          relevance: relevance,
          matchedFields: matchedFields.toList(),
        ));
      }
    }

    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results;
  }
}

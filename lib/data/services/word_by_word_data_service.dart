import 'package:flutter/foundation.dart';
import '../../../core/utils/compressed_json_loader.dart';

/// Word-by-word data service
/// Loads and caches quran_wbw.json.gz from assets
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../providers/quran_database_provider.dart';
import '../datasources/local/drift/database.dart';

final wordByWordDataServiceProvider = Provider<WordByWordDataService>((ref) {
  final db = ref.watch(quranDatabaseProvider);
  return WordByWordDataService(db);
});

/// Word-by-word data service
/// Loads from SQLite database instead of massive JSON file
class WordByWordDataService {
  final AppDatabase _db;

  WordByWordDataService(this._db);

  /// Keep this for backwards compatibility if needed, but it does nothing now
  Future<Map<String, dynamic>> loadWordByWordData() async {
    return {}; 
  }

  /// Get words for a specific verse
  Future<List<Map<String, dynamic>>> getWordsForVerse(
    int surahNumber,
    int verseNumber,
  ) async {
    final query = _db.select(_db.verses)
      ..where((v) => v.surahId.equals(surahNumber) & v.verseId.equals(verseNumber));
      
    final verse = await query.getSingleOrNull();
    if (verse == null || verse.wbwText == null) return [];
    
    try {
      final List<dynamic> wordsList = jsonDecode(verse.wbwText!);
      final words = wordsList.cast<Map<String, dynamic>>();
      
      // Sort by word number
      words.sort((a, b) {
        final wordA = int.tryParse(a['word']?.toString() ?? '0') ?? 0;
        final wordB = int.tryParse(b['word']?.toString() ?? '0') ?? 0;
        return wordA.compareTo(wordB);
      });
      
      return words;
    } catch (e) {
      return [];
    }
  }

  /// Get a specific word by surah, verse, and word number
  Future<Map<String, dynamic>?> getWord(
    int surahNumber,
    int verseNumber,
    int wordNumber,
  ) async {
    final words = await getWordsForVerse(surahNumber, verseNumber);
    for (final word in words) {
      if (int.tryParse(word['word']?.toString() ?? '0') == wordNumber) {
        return word;
      }
    }
    return null;
  }

  /// Clear cache (no-op now)
  void clearCache() {}
}

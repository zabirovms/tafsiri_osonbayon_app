import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import '../../models/verse_model.dart';
import '../../providers/quran_database_provider.dart';
import 'drift/database.dart';

final driftVerseDataSourceProvider = Provider<DriftVerseDataSource>((ref) {
  final db = ref.watch(quranDatabaseProvider);
  return DriftVerseDataSource(db);
});

class DriftVerseDataSource {
  final AppDatabase _db;

  DriftVerseDataSource(this._db);

  /// Load verses for a specific surah, joining with all available translations and tafsirs
  Future<List<VerseModel>> getVersesBySurah(int surahNumber) async {
    final versesQuery = _db.select(_db.verses)..where((v) => v.surahId.equals(surahNumber));
    final dbVerses = await versesQuery.get();

    final translationsQuery = _db.select(_db.translations)..where((t) => t.surahId.equals(surahNumber));
    final dbTranslations = await translationsQuery.get();

    final tafsirQuery = _db.select(_db.tafsir)..where((t) => t.surahId.equals(surahNumber));
    final dbTafsir = await tafsirQuery.get();

    // Group translations by verse_id then resource_id
    final Map<int, Map<String, String>> transMap = {};
    for (final t in dbTranslations) {
      transMap.putIfAbsent(t.verseId, () => {});
      transMap[t.verseId]![t.resourceId] = t.content ?? '';
    }

    // Group tafsirs by verse_id then resource_id
    final Map<int, Map<String, String>> tafsirMap = {};
    for (final t in dbTafsir) {
      tafsirMap.putIfAbsent(t.verseId, () => {});
      tafsirMap[t.verseId]![t.resourceId] = t.content ?? '';
    }

    final results = <VerseModel>[];
    for (final v in dbVerses) {
      final tMap = transMap[v.verseId] ?? {};
      final tfMap = tafsirMap[v.verseId] ?? {};

      results.add(VerseModel(
        id: v.absoluteId ?? 0,
        verseNumber: v.verseId,
        surahId: v.surahId,
        arabicText: v.arabicText ?? '',
        ayatiText: tMap['tj_ayati'] ?? '',
        transliteration: tMap['transliteration'] ?? '',
        tafsir: tfMap['tj_osonbayon'],
        russianKulievText: tMap['ru_kuliev'],
        alomuddinText: tMap['tj_alomuddin'],
        pioneersText: tMap['tj_pioneers'],
        khojamirovText: tMap['tj_khojamirov'],
        farsi: tMap['fa_translation'],
        tafsirRu: tfMap['ru_ibn_kathir'],
        page: v.page,
        juz: v.juz,
        uniqueKey: '${v.surahId}:${v.verseId}',
      ));
    }

    // Sort by verse number
    results.sort((a, b) => a.verseNumber.compareTo(b.verseNumber));
    return results;
  }

  /// Load verses for a specific page (1-604)
  Future<List<VerseModel>> getVersesByPage(int pageNumber) async {
    final versesQuery = _db.select(_db.verses)..where((v) => v.page.equals(pageNumber));
    final dbVerses = await versesQuery.get();
    if (dbVerses.isEmpty) return [];

    final surahIds = dbVerses.map((v) => v.surahId).toSet();
    final translationsQuery = _db.select(_db.translations)..where((t) => t.surahId.isIn(surahIds));
    final dbTranslations = await translationsQuery.get();

    final tafsirQuery = _db.select(_db.tafsir)..where((t) => t.surahId.isIn(surahIds));
    final dbTafsir = await tafsirQuery.get();

    final Map<int, Map<int, Map<String, String>>> transMap = {};
    for (final t in dbTranslations) {
      transMap.putIfAbsent(t.surahId, () => {});
      transMap[t.surahId]!.putIfAbsent(t.verseId, () => {});
      transMap[t.surahId]![t.verseId]![t.resourceId] = t.content ?? '';
    }

    final Map<int, Map<int, Map<String, String>>> tafsirMap = {};
    for (final t in dbTafsir) {
      tafsirMap.putIfAbsent(t.surahId, () => {});
      tafsirMap[t.surahId]!.putIfAbsent(t.verseId, () => {});
      tafsirMap[t.surahId]![t.verseId]![t.resourceId] = t.content ?? '';
    }

    final results = <VerseModel>[];
    for (final v in dbVerses) {
      final tMap = transMap[v.surahId]?[v.verseId] ?? {};
      final tfMap = tafsirMap[v.surahId]?[v.verseId] ?? {};

      results.add(VerseModel(
        id: v.absoluteId ?? 0,
        verseNumber: v.verseId,
        surahId: v.surahId,
        arabicText: v.arabicText ?? '',
        ayatiText: tMap['tj_ayati'] ?? '',
        transliteration: tMap['transliteration'] ?? '',
        tafsir: tfMap['tj_osonbayon'],
        russianKulievText: tMap['ru_kuliev'],
        alomuddinText: tMap['tj_alomuddin'],
        pioneersText: tMap['tj_pioneers'],
        khojamirovText: tMap['tj_khojamirov'],
        farsi: tMap['fa_translation'],
        tafsirRu: tfMap['ru_ibn_kathir'],
        page: v.page,
        juz: v.juz,
        uniqueKey: '${v.surahId}:${v.verseId}',
      ));
    }

    results.sort((a, b) {
      final s = a.surahId.compareTo(b.surahId);
      if (s != 0) return s;
      return a.verseNumber.compareTo(b.verseNumber);
    });
    return results;
  }

  Future<VerseModel?> getVerseByKey(String uniqueKey) async {
    try {
      final parts = uniqueKey.split(':');
      if (parts.length != 2) return null;
      
      final surahNumber = int.tryParse(parts[0]);
      final verseNumber = int.tryParse(parts[1]);
      
      if (surahNumber == null || verseNumber == null) return null;
      
      final verseQuery = _db.select(_db.verses)
        ..where((v) => v.surahId.equals(surahNumber) & v.verseId.equals(verseNumber))
        ..limit(1);
      final dbVerses = await verseQuery.get();
      if (dbVerses.isEmpty) return null;
      final v = dbVerses.first;

      final translationsQuery = _db.select(_db.translations)
        ..where((t) => t.surahId.equals(surahNumber) & t.verseId.equals(verseNumber));
      final dbTranslations = await translationsQuery.get();

      final tafsirQuery = _db.select(_db.tafsir)
        ..where((t) => t.surahId.equals(surahNumber) & t.verseId.equals(verseNumber));
      final dbTafsir = await tafsirQuery.get();

      final Map<String, String> tMap = {};
      for (final t in dbTranslations) {
        tMap[t.resourceId] = t.content ?? '';
      }

      final Map<String, String> tfMap = {};
      for (final t in dbTafsir) {
        tfMap[t.resourceId] = t.content ?? '';
      }

      return VerseModel(
        id: v.absoluteId ?? 0,
        verseNumber: v.verseId,
        surahId: v.surahId,
        arabicText: v.arabicText ?? '',
        ayatiText: tMap['tj_ayati'] ?? '',
        transliteration: tMap['transliteration'] ?? '',
        tafsir: tfMap['tj_osonbayon'],
        russianKulievText: tMap['ru_kuliev'],
        alomuddinText: tMap['tj_alomuddin'],
        pioneersText: tMap['tj_pioneers'],
        khojamirovText: tMap['tj_khojamirov'],
        farsi: tMap['fa_translation'],
        tafsirRu: tfMap['ru_ibn_kathir'],
        page: v.page,
        juz: v.juz,
        uniqueKey: '${v.surahId}:${v.verseId}',
      );
    } catch (e) {
      return null;
    }
  }
  Future<List<VerseModel>> getVersesBulk(List<String> uniqueKeys) async {
    if (uniqueKeys.isEmpty) return [];

    final results = <VerseModel>[];
    
    // Process in chunks of 50 to keep query complexity reasonable
    for (var i = 0; i < uniqueKeys.length; i += 50) {
      final end = (i + 50 < uniqueKeys.length) ? i + 50 : uniqueKeys.length;
      final chunk = uniqueKeys.sublist(i, end);
      
      Expression<bool> predicate = const CustomExpression<bool>('0'); // initial false
      
      for (final key in chunk) {
        final parts = key.split(':');
        final sId = int.parse(parts[0]);
        final vId = int.parse(parts[1]);
        final cond = _db.verses.surahId.equals(sId) & _db.verses.verseId.equals(vId);
        if (predicate == const CustomExpression<bool>('0')) {
          predicate = cond;
        } else {
          predicate = predicate | cond;
        }
      }

      final dbVerses = await (_db.select(_db.verses)..where((v) => predicate)).get();
      
      // Do the same for translations and tafsir
      Expression<bool> tPredicate = const CustomExpression<bool>('0');
      Expression<bool> tfPredicate = const CustomExpression<bool>('0');
      
      for (final key in chunk) {
        final parts = key.split(':');
        final sId = int.parse(parts[0]);
        final vId = int.parse(parts[1]);
        
        final tCond = _db.translations.surahId.equals(sId) & _db.translations.verseId.equals(vId);
        if (tPredicate == const CustomExpression<bool>('0')) {
          tPredicate = tCond;
        } else {
          tPredicate = tPredicate | tCond;
        }
        
        final tfCond = _db.tafsir.surahId.equals(sId) & _db.tafsir.verseId.equals(vId);
        if (tfPredicate == const CustomExpression<bool>('0')) {
          tfPredicate = tfCond;
        } else {
          tfPredicate = tfPredicate | tfCond;
        }
      }

      final dbTranslations = await (_db.select(_db.translations)..where((t) => tPredicate)).get();
      final dbTafsir = await (_db.select(_db.tafsir)..where((t) => tfPredicate)).get();

      // Group them
      final Map<int, Map<int, Map<String, String>>> transMap = {};
      for (final t in dbTranslations) {
        transMap.putIfAbsent(t.surahId, () => {});
        transMap[t.surahId]!.putIfAbsent(t.verseId, () => {});
        transMap[t.surahId]![t.verseId]![t.resourceId] = t.content ?? '';
      }

      final Map<int, Map<int, Map<String, String>>> tafsirMap = {};
      for (final t in dbTafsir) {
        tafsirMap.putIfAbsent(t.surahId, () => {});
        tafsirMap[t.surahId]!.putIfAbsent(t.verseId, () => {});
        tafsirMap[t.surahId]![t.verseId]![t.resourceId] = t.content ?? '';
      }

      for (final v in dbVerses) {
        final tMap = transMap[v.surahId]?[v.verseId] ?? {};
        final tfMap = tafsirMap[v.surahId]?[v.verseId] ?? {};

        results.add(VerseModel(
          id: v.absoluteId ?? 0,
          verseNumber: v.verseId,
          surahId: v.surahId,
          arabicText: v.arabicText ?? '',
          ayatiText: tMap['tj_ayati'] ?? '',
          transliteration: tMap['transliteration'] ?? '',
          tafsir: tfMap['tj_osonbayon'],
          russianKulievText: tMap['ru_kuliev'],
          alomuddinText: tMap['tj_alomuddin'],
          pioneersText: tMap['tj_pioneers'],
          khojamirovText: tMap['tj_khojamirov'],
          farsi: tMap['fa_translation'],
          tafsirRu: tfMap['ru_ibn_kathir'],
          page: v.page,
          juz: v.juz,
          uniqueKey: '${v.surahId}:${v.verseId}',
        ));
      }
    }
    
    return results;
  }

  /// Get all verses for the entire Quran
  Future<List<VerseModel>> getAllVersesCached() async {
    final versesQuery = _db.select(_db.verses);
    final dbVerses = await versesQuery.get();

    final translationsQuery = _db.select(_db.translations);
    final dbTranslations = await translationsQuery.get();

    final tafsirQuery = _db.select(_db.tafsir);
    final dbTafsir = await tafsirQuery.get();

    final Map<int, Map<int, Map<String, String>>> transMap = {};
    for (final t in dbTranslations) {
      transMap.putIfAbsent(t.surahId, () => {});
      transMap[t.surahId]!.putIfAbsent(t.verseId, () => {});
      transMap[t.surahId]![t.verseId]![t.resourceId] = t.content ?? '';
    }

    final Map<int, Map<int, Map<String, String>>> tafsirMap = {};
    for (final t in dbTafsir) {
      tafsirMap.putIfAbsent(t.surahId, () => {});
      tafsirMap[t.surahId]!.putIfAbsent(t.verseId, () => {});
      tafsirMap[t.surahId]![t.verseId]![t.resourceId] = t.content ?? '';
    }

    final results = <VerseModel>[];
    for (final v in dbVerses) {
      final tMap = transMap[v.surahId]?[v.verseId] ?? {};
      final tfMap = tafsirMap[v.surahId]?[v.verseId] ?? {};

      results.add(VerseModel(
        id: v.absoluteId ?? 0,
        verseNumber: v.verseId,
        surahId: v.surahId,
        arabicText: v.arabicText ?? '',
        ayatiText: tMap['tj_ayati'] ?? '',
        transliteration: tMap['transliteration'] ?? '',
        tafsir: tfMap['tj_osonbayon'],
        russianKulievText: tMap['ru_kuliev'],
        alomuddinText: tMap['tj_alomuddin'],
        pioneersText: tMap['tj_pioneers'],
        khojamirovText: tMap['tj_khojamirov'],
        farsi: tMap['fa_translation'],
        tafsirRu: tfMap['ru_ibn_kathir'],
        page: v.page,
        juz: v.juz,
        uniqueKey: '${v.surahId}:${v.verseId}',
      ));
    }

    return results;
  }
}

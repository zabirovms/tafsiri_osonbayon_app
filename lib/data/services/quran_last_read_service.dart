import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Max rows kept for «охирин хониш» (newest first), aligned with Bukhari last-read.
const int kQuranLastReadMaxCount = 7;

class QuranLastReadEntry {
  final int surahNumber;
  final int verseNumber;
  final String surahNameTajik;
  final int visitedAtMillis;
  /// Ayahs in this surah as loaded in the app (for progress %); null on legacy rows.
  final int? surahAyahCount;

  const QuranLastReadEntry({
    required this.surahNumber,
    required this.verseNumber,
    required this.surahNameTajik,
    this.visitedAtMillis = 0,
    this.surahAyahCount,
  });

  Map<String, dynamic> toJson() => {
        'surahNumber': surahNumber,
        'verseNumber': verseNumber,
        'surahNameTajik': surahNameTajik,
        'visitedAtMillis': visitedAtMillis,
        if (surahAyahCount != null) 'surahAyahCount': surahAyahCount,
      };

  factory QuranLastReadEntry.fromJson(Map<String, dynamic> json) {
    return QuranLastReadEntry(
      surahNumber: json['surahNumber'] as int? ?? 0,
      verseNumber: json['verseNumber'] as int? ?? 1,
      surahNameTajik: json['surahNameTajik'] as String? ?? '',
      visitedAtMillis: json['visitedAtMillis'] as int? ?? 0,
      surahAyahCount: (json['surahAyahCount'] as num?)?.toInt(),
    );
  }
}

class QuranLastReadService {
  static const String _key = 'quran_last_reads_v1';

  /// [items] newest first; keeps first row per surah (newest ayah for that surah).
  static List<QuranLastReadEntry> _dedupeBySurahKeepNewest(
    List<QuranLastReadEntry> items,
  ) {
    final seen = <int>{};
    final out = <QuranLastReadEntry>[];
    for (final e in items) {
      if (e.surahNumber < 1 || e.surahNumber > 114) continue;
      if (seen.contains(e.surahNumber)) continue;
      seen.add(e.surahNumber);
      out.add(e);
    }
    return out;
  }

  Future<void> _persist(List<QuranLastReadEntry> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<List<QuranLastReadEntry>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => QuranLastReadEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      var cleaned = _dedupeBySurahKeepNewest(list);
      if (cleaned.length > kQuranLastReadMaxCount) {
        cleaned = cleaned.sublist(0, kQuranLastReadMaxCount);
      }
      final needsWrite =
          cleaned.length != list.length || list.length > kQuranLastReadMaxCount;
      if (needsWrite) {
        await _persist(cleaned);
      }
      return cleaned;
    } catch (_) {
      return [];
    }
  }

  /// Newest first; **at most one row per surah** (scrolling only updates that surah’s verse).
  /// Skips a write if the newest row is already this surah and verse (avoids churn).
  Future<void> recordVisit(QuranLastReadEntry entry) async {
    if (entry.surahNumber < 1 ||
        entry.surahNumber > 114 ||
        entry.verseNumber < 1) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final newEntry = QuranLastReadEntry(
      surahNumber: entry.surahNumber,
      verseNumber: entry.verseNumber,
      surahNameTajik: entry.surahNameTajik,
      visitedAtMillis: now,
      surahAyahCount: entry.surahAyahCount,
    );
    final existing = await getAll();
    if (existing.isNotEmpty) {
      final f = existing.first;
      if (f.surahNumber == newEntry.surahNumber &&
          f.verseNumber == newEntry.verseNumber &&
          f.surahAyahCount == newEntry.surahAyahCount) {
        return;
      }
    }
    final rest =
        existing.where((e) => e.surahNumber != newEntry.surahNumber).toList();
    final next = [newEntry, ...rest];
    if (next.length > kQuranLastReadMaxCount) {
      next.removeRange(kQuranLastReadMaxCount, next.length);
    }
    await _persist(next);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

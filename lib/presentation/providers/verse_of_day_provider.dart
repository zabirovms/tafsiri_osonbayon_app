import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/verse_model.dart';
import '../../data/datasources/local/drift_verse_datasource.dart';

/// Get verse of the day based on the day of the year
/// Uses a deterministic algorithm to select the same verse for the same day
final verseOfDayProvider = FutureProvider<VerseOfDayResult>((ref) async {
  final dataSource = ref.watch(driftVerseDataSourceProvider);
  
  // Get day of year (1-365/366)
  final now = DateTime.now();
  final startOfYear = DateTime(now.year, 1, 1);
  final dayOfYear = now.difference(startOfYear).inDays + 1;
  
  // Use day of year to deterministically select a surah and verse
  // There are 114 surahs, so we cycle through them
  final surahNumber = ((dayOfYear - 1) % 114) + 1;
  
  // Get verses for the selected surah
  final verses = await dataSource.getVersesBySurah(surahNumber);
  
  if (verses.isEmpty) {
    // Fallback to Al-Fatiha, verse 1
    final fallbackVerses = await dataSource.getVersesBySurah(1);
    if (fallbackVerses.isNotEmpty) {
      return VerseOfDayResult(
        verse: fallbackVerses.first,
        surahNumber: 1,
      );
    }
    throw Exception('No verses available');
  }
  
  // Select verse based on day of year (cycle through verses)
  final verseIndex = (dayOfYear - 1) % verses.length;
  final selectedVerse = verses[verseIndex];
  
  return VerseOfDayResult(
    verse: selectedVerse,
    surahNumber: surahNumber,
  );
});

class VerseOfDayResult {
  final VerseModel verse;
  final int surahNumber;

  VerseOfDayResult({
    required this.verse,
    required this.surahNumber,
  });
}


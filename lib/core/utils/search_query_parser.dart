import '../../data/models/verse_model.dart';
import '../../data/models/surah_model.dart';

/// Parsed search query result
class ParsedSearchQuery {
  final SearchQueryType type;
  final int? surahNumber;
  final int? verseNumber;
  final int? juzNumber;
  final int? pageNumber;
  final String? textQuery;

  ParsedSearchQuery({
    required this.type,
    this.surahNumber,
    this.verseNumber,
    this.juzNumber,
    this.pageNumber,
    this.textQuery,
  });
}

enum SearchQueryType {
  verse,
  surah,
  juz,
  page,
  text,
}

/// Helper class to parse search queries and detect patterns
class SearchQueryParser {
  /// Normalize Tajik text for fuzzy/phonetic comparison
  static String normalizeTajik(String text) {
    String clean = text.toLowerCase().trim();
    if (clean.startsWith('сураи ')) {
      clean = clean.substring(6).trim();
    } else if (clean.startsWith('сура ')) {
      clean = clean.substring(5).trim();
    }
    return clean
        .replaceAll('қ', 'к')
        .replaceAll('ҷ', 'ч')
        .replaceAll('ӣ', 'и')
        .replaceAll('ҳ', 'х')
        .replaceAll('ғ', 'г')
        .replaceAll('ӯ', 'у')
        .replaceAll('ё', 'е')
        .replaceAll('э', 'е')
        .replaceAll('о', 'а') // handle о/а phonetic interchangeability
        .replaceAll(RegExp(r'\bа[лнрсштдз]-'), '') // strip al-, an-, ar-, etc.
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Fuzzy-find a Surah by matching normalized names
  static SurahModel? findSurahByName(
      String queryName, List<SurahModel> surahs) {
    final normQuery = normalizeTajik(queryName);
    if (normQuery.isEmpty) return null;

    // 1. Exact match
    for (final s in surahs) {
      if (normalizeTajik(s.nameTajik) == normQuery) return s;
    }
    // 2. Starts with match
    for (final s in surahs) {
      if (normalizeTajik(s.nameTajik).startsWith(normQuery)) return s;
    }
    // 3. Contains match
    for (final s in surahs) {
      if (normalizeTajik(s.nameTajik).contains(normQuery)) return s;
    }
    // 4. Fallback to Arabic name contains match
    for (final s in surahs) {
      if (s.nameArabic.toLowerCase().contains(normQuery)) return s;
    }
    return null;
  }

  /// Parse search query to detect special patterns
  static ParsedSearchQuery parseQuery(
    String query,
    List<SurahModel> surahs,
  ) {
    final trimmed = query.trim();

    // Verse reference patterns: "2:255", "2 255", "2.255", "сураи 2 оят 255"
    final versePatterns = [
      RegExp(r'^(\d+)[:.\s]+(\d+)$'), // "2:255", "2 255", "2.255"
      RegExp(r'^сураи\s+(\d+)\s+оят\s+(\d+)$',
          caseSensitive: false), // "сураи 2 оят 255"
      RegExp(r'^(\d+)\s+оят\s+(\d+)$', caseSensitive: false), // "2 оят 255"
    ];

    for (final pattern in versePatterns) {
      final match = pattern.firstMatch(trimmed);
      if (match != null) {
        final surahNum = int.tryParse(match.group(1) ?? '');
        final verseNum = int.tryParse(match.group(2) ?? '');
        if (surahNum != null && verseNum != null) {
          return ParsedSearchQuery(
            type: SearchQueryType.verse,
            surahNumber: surahNum,
            verseNumber: verseNum,
          );
        }
      }
    }

    // Juz pattern: "ҷузи 6", "juz 6", "ҷуз 6"
    final juzPattern = RegExp(r'^(?:ҷузи?|juz)\s+(\d+)$', caseSensitive: false);
    final juzMatch = juzPattern.firstMatch(trimmed);
    if (juzMatch != null) {
      final juzNum = int.tryParse(juzMatch.group(1) ?? '');
      if (juzNum != null && juzNum >= 1 && juzNum <= 30) {
        return ParsedSearchQuery(
          type: SearchQueryType.juz,
          juzNumber: juzNum,
        );
      }
    }

    // Page pattern: "саҳифаи 9", "page 9", "саҳифа 9"
    final pagePattern =
        RegExp(r'^(?:саҳифаи?|page)\s+(\d+)$', caseSensitive: false);
    final pageMatch = pagePattern.firstMatch(trimmed);
    if (pageMatch != null) {
      final pageNum = int.tryParse(pageMatch.group(1) ?? '');
      if (pageNum != null && pageNum >= 1 && pageNum <= 604) {
        return ParsedSearchQuery(
          type: SearchQueryType.page,
          pageNumber: pageNum,
        );
      }
    }

    // Surah Name + Verse pattern: e.g. "бакара 45", "сураи бакара ояти 45", "бакара:45"
    if (!RegExp(r'^\d+').hasMatch(trimmed)) {
      final nameAndVersePattern = RegExp(
        r'^(.+?)(?:\s+оят[иӣ]?)?\s*[:.\s-]+\s*(\d+)$',
        caseSensitive: false,
      );
      final nameAndVerseMatch = nameAndVersePattern.firstMatch(trimmed);
      if (nameAndVerseMatch != null) {
        final surahCandidate = nameAndVerseMatch.group(1)?.trim() ?? '';
        final verseNum = int.tryParse(nameAndVerseMatch.group(2) ?? '');
        if (surahCandidate.isNotEmpty && verseNum != null) {
          final matchedSurah = findSurahByName(surahCandidate, surahs);
          if (matchedSurah != null &&
              verseNum >= 1 &&
              verseNum <= matchedSurah.versesCount) {
            return ParsedSearchQuery(
              type: SearchQueryType.verse,
              surahNumber: matchedSurah.number,
              verseNumber: verseNum,
            );
          }
        }
      }
    }

    // Surah name pattern: "Сураи бакара", "Ёсин", "бакара"
    // Only match if it looks like a surah name (not numbers or special patterns)
    if (!RegExp(r'^\d+').hasMatch(trimmed)) {
      final matchedSurah = findSurahByName(trimmed, surahs);
      if (matchedSurah != null) {
        return ParsedSearchQuery(
          type: SearchQueryType.surah,
          surahNumber: matchedSurah.number,
        );
      }
    }

    // Default to text search
    return ParsedSearchQuery(
      type: SearchQueryType.text,
      textQuery: trimmed,
    );
  }

  /// Find verse by juz number
  static VerseModel? findVerseByJuz(List<VerseModel> allVerses, int juzNumber) {
    try {
      return allVerses.firstWhere(
        (v) => v.juz == juzNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Find verse by page number
  static VerseModel? findVerseByPage(
      List<VerseModel> allVerses, int pageNumber) {
    try {
      return allVerses.firstWhere(
        (v) => v.page == pageNumber,
      );
    } catch (e) {
      return null;
    }
  }

  /// Find verse by surah and verse number
  static VerseModel? findVerse(
    List<VerseModel> allVerses,
    int surahNumber,
    int verseNumber,
  ) {
    try {
      return allVerses.firstWhere(
        (v) => v.surahId == surahNumber && v.verseNumber == verseNumber,
      );
    } catch (e) {
      return null;
    }
  }
}

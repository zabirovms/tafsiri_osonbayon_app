import 'verse_model.dart';
import 'surah_model.dart';

/// Unified search result that can be either a surah or verse
class SearchResult {
  final SearchResultType type;
  final dynamic data; // SurahModel or VerseModel
  final double relevance;
  final List<String> matchedFields;

  SearchResult({
    required this.type,
    required this.data,
    required this.relevance,
    required this.matchedFields,
  });

  SurahModel? get surah => type == SearchResultType.surah ? data as SurahModel : null;
  VerseModel? get verse => type == SearchResultType.verse ? data as VerseModel : null;
}

enum SearchResultType {
  surah,
  verse,
}

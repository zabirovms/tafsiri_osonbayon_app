import '../datasources/local/drift_surah_datasource.dart';
import '../datasources/local/drift_verse_datasource.dart';
import '../datasources/local/drift_search_datasource.dart';
import '../datasources/local/bookmark_local_datasource.dart';
import '../models/surah_model.dart';
import '../models/verse_model.dart';
import '../models/bookmark_model.dart';
import '../../domain/repositories/quran_repository.dart';

class LocalQuranRepository implements QuranRepository {
  final DriftSurahDataSource _surahLocalDataSource;
  final DriftVerseDataSource _verseLocalDataSource;
  final DriftSearchDataSource _searchLocalDataSource;
  final BookmarkLocalDataSource _bookmarkLocalDataSource;

  LocalQuranRepository({
    required DriftSurahDataSource surahLocalDataSource,
    required DriftVerseDataSource verseLocalDataSource,
    required DriftSearchDataSource searchLocalDataSource,
    required BookmarkLocalDataSource bookmarkLocalDataSource,
  }) : _surahLocalDataSource = surahLocalDataSource,
       _verseLocalDataSource = verseLocalDataSource,
       _searchLocalDataSource = searchLocalDataSource,
       _bookmarkLocalDataSource = bookmarkLocalDataSource;

  // Surah operations - now using local data
  @override
  Future<List<SurahModel>> getAllSurahs() async {
    try {
      return await _surahLocalDataSource.getAllSurahs();
    } catch (e) {
      throw Exception('Failed to fetch surahs from local data: $e');
    }
  }

  @override
  Future<SurahModel?> getSurahByNumber(int number) async {
    try {
      return await _surahLocalDataSource.getSurahByNumber(number);
    } catch (e) {
      throw Exception('Failed to fetch surah from local data: $e');
    }
  }

  @override
  Future<SurahModel?> getSurahDetails(int number) async {
    try {
      return await _surahLocalDataSource.getSurahDetails(number);
    } catch (e) {
      throw Exception('Failed to fetch surah details from local data: $e');
    }
  }

  // Verse operations - now using local data
  @override
  Future<List<VerseModel>> getVersesBySurah(int surahNumber) async {
    try {
      return await _verseLocalDataSource.getVersesBySurah(surahNumber);
    } catch (e) {
      throw Exception('Failed to fetch verses from local data: $e');
    }
  }

  @override
  Future<VerseModel?> getVerseByKey(String uniqueKey) async {
    try {
      return await _verseLocalDataSource.getVerseByKey(uniqueKey);
    } catch (e) {
      throw Exception('Failed to fetch verse from local data: $e');
    }
  }

  @override
  Future<List<VerseModel>> searchVerses(String query, {String language = 'both', int? surahId}) async {
    try {
      return await _searchLocalDataSource.searchVerses(
        query,
        language: language,
        surahId: surahId,
      );
    } catch (e) {
      throw Exception('Failed to search verses from local data: $e');
    }
  }

  // Bookmark operations - now using local SQLite database
  @override
  Future<int> addBookmark(BookmarkModel bookmark) async {
    try {
      return await _bookmarkLocalDataSource.addBookmark(bookmark);
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  @override
  Future<List<BookmarkModel>> getBookmarksByUser(String userId) async {
    try {
      return await _bookmarkLocalDataSource.getBookmarksByUser(userId);
    } catch (e) {
      throw Exception('Failed to get bookmarks: $e');
    }
  }

  @override
  Future<bool> removeBookmark(int bookmarkId) async {
    try {
      return await _bookmarkLocalDataSource.removeBookmark(bookmarkId);
    } catch (e) {
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  @override
  Future<bool> removeBookmarkByVerseKey(String userId, String verseKey) async {
    try {
      return await _bookmarkLocalDataSource.removeBookmarkByVerseKey(userId, verseKey);
    } catch (e) {
      throw Exception('Failed to remove bookmark by verse key: $e');
    }
  }

  // Word analysis operations
  @override
  Future<List<Map<String, dynamic>>> getWordAnalysisByVerse(int verseId) async {
    throw UnimplementedError('Word analysis not available locally yet');
  }

  // Search history operations
  @override
  Future<int> addSearchHistory(String userId, String query) async {
    throw UnimplementedError('Search history not available locally yet');
  }

  @override
  Future<List<Map<String, dynamic>>> getSearchHistoryByUser(String userId) async {
    throw UnimplementedError('Search history not available locally yet');
  }

  // Utility operations
  @override
  Future<void> clearAllData() async {
    throw UnimplementedError('Data clearing not available locally yet');
  }

  @override
  Future<void> clearUserData(String userId) async {
    throw UnimplementedError('User data clearing not available locally yet');
  }

  @override
  Future<int> getDatabaseSize() async {
    throw UnimplementedError('Database size not available locally yet');
  }
}

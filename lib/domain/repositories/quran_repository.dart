import '../../data/models/surah_model.dart';
import '../../data/models/verse_model.dart';
import '../../data/models/bookmark_model.dart';

abstract class QuranRepository {
  // Surah operations
  Future<List<SurahModel>> getAllSurahs();
  Future<SurahModel?> getSurahByNumber(int number);
  Future<SurahModel?> getSurahDetails(int number);

  // Verse operations
  Future<List<VerseModel>> getVersesBySurah(int surahNumber);
  Future<VerseModel?> getVerseByKey(String uniqueKey);

  // Search operations
  Future<List<VerseModel>> searchVerses(
    String query, {
    String language = 'both',
    int? surahId,
  });

  // Bookmark operations
  Future<int> addBookmark(BookmarkModel bookmark);
  Future<List<BookmarkModel>> getBookmarksByUser(String userId);
  Future<bool> removeBookmark(int bookmarkId);
  Future<bool> removeBookmarkByVerseKey(String userId, String verseKey);

  // Word analysis operations
  Future<List<Map<String, dynamic>>> getWordAnalysisByVerse(int verseId);

  // Search history operations
  Future<int> addSearchHistory(String userId, String query);
  Future<List<Map<String, dynamic>>> getSearchHistoryByUser(String userId);

  // Utility operations
  Future<void> clearAllData();
  Future<void> clearUserData(String userId);
  Future<int> getDatabaseSize();
}

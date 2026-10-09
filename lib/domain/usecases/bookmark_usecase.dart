import '../repositories/quran_repository.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/models/verse_model.dart';

class BookmarkUseCase {
  final QuranRepository _repository;

  BookmarkUseCase(this._repository);

  // Add a bookmark from a verse
  Future<int> addBookmarkFromVerse(VerseModel verse, String userId, String surahName) async {
    final bookmark = BookmarkModel(
      id: 0, // Will be set by database
      userId: userId,
      verseId: verse.id,
      verseKey: verse.uniqueKey,
      surahNumber: verse.surahId,
      verseNumber: verse.verseNumber,
      arabicText: verse.arabicText,
      ayatiText: verse.ayatiText,
      surahName: surahName,
      createdAt: DateTime.now(),
    );
    
    return await _repository.addBookmark(bookmark);
  }

  // Add a bookmark (legacy method)
  Future<int> addBookmark(BookmarkModel bookmark) async {
    return await _repository.addBookmark(bookmark);
  }

  // Get all bookmarks for a user
  Future<List<BookmarkModel>> getBookmarksByUser(String userId) async {
    return await _repository.getBookmarksByUser(userId);
  }

  // Remove bookmark by ID
  Future<bool> removeBookmark(int bookmarkId) async {
    return await _repository.removeBookmark(bookmarkId);
  }

  // Remove bookmark by verse key
  Future<bool> removeBookmarkByVerseKey(String userId, String verseKey) async {
    return await _repository.removeBookmarkByVerseKey(userId, verseKey);
  }

  // Check if a verse is bookmarked
  Future<bool> isVerseBookmarked(String userId, String verseKey) async {
    final bookmarks = await getBookmarksByUser(userId);
    return bookmarks.any((bookmark) => bookmark.verseKey == verseKey);
  }

  // Get bookmark by verse key
  Future<BookmarkModel?> getBookmarkByVerseKey(String userId, String verseKey) async {
    final bookmarks = await getBookmarksByUser(userId);
    try {
      return bookmarks.firstWhere((bookmark) => bookmark.verseKey == verseKey);
    } catch (e) {
      return null;
    }
  }

  // Toggle bookmark (add if not exists, remove if exists)
  Future<bool> toggleBookmark(VerseModel verse, String userId, String surahName) async {
    final existingBookmark = await getBookmarkByVerseKey(userId, verse.uniqueKey);
    
    if (existingBookmark != null) {
      // Remove existing bookmark
      return await removeBookmark(existingBookmark.id);
    } else {
      // Add new bookmark
      try {
        await addBookmarkFromVerse(verse, userId, surahName);
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  // Get bookmarks count for a user
  Future<int> getBookmarkCount(String userId) async {
    final bookmarks = await getBookmarksByUser(userId);
    return bookmarks.length;
  }

  // Get bookmarks by surah
  Future<List<BookmarkModel>> getBookmarksBySurah(String userId, int surahNumber) async {
    final allBookmarks = await getBookmarksByUser(userId);
    return allBookmarks.where((bookmark) => bookmark.surahNumber == surahNumber).toList();
  }
}

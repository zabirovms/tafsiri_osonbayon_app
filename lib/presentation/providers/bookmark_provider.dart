import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bookmark_model.dart';
import '../../data/services/analytics_service.dart';
import '../../data/models/verse_model.dart';
import '../../domain/usecases/bookmark_usecase.dart';
import 'quran_provider.dart';

// Bookmark state
class BookmarkState {
  final List<BookmarkModel> bookmarks;
  final bool isLoading;
  final String? error;
  final Map<String, bool> bookmarkStatus; // verseKey -> isBookmarked

  BookmarkState({
    this.bookmarks = const [],
    this.isLoading = false,
    this.error,
    this.bookmarkStatus = const {},
  });

  BookmarkState copyWith({
    List<BookmarkModel>? bookmarks,
    bool? isLoading,
    String? error,
    Map<String, bool>? bookmarkStatus,
  }) {
    return BookmarkState(
      bookmarks: bookmarks ?? this.bookmarks,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      bookmarkStatus: bookmarkStatus ?? this.bookmarkStatus,
    );
  }
}

// Bookmark notifier
class BookmarkNotifier extends StateNotifier<BookmarkState> {
  final BookmarkUseCase _bookmarkUseCase;
  final String _userId;

  BookmarkNotifier(this._bookmarkUseCase, this._userId) : super(BookmarkState()) {
    _loadBookmarks();
  }

  // Load all bookmarks for the user
  Future<void> _loadBookmarks() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final bookmarks = await _bookmarkUseCase.getBookmarksByUser(_userId);
      
      // Filter out any bookmarks with invalid IDs (shouldn't happen, but safety check)
      final validBookmarks = bookmarks.where((b) => b.id > 0 && b.verseKey.isNotEmpty).toList();
      
      if (validBookmarks.length != bookmarks.length) {
        debugPrint('Warning: Filtered out ${bookmarks.length - validBookmarks.length} invalid bookmarks');
      }
      
      final bookmarkStatus = <String, bool>{};
      
      for (final bookmark in validBookmarks) {
        bookmarkStatus[bookmark.verseKey] = true;
      }
      
      state = state.copyWith(
        bookmarks: validBookmarks,
        isLoading: false,
        bookmarkStatus: bookmarkStatus,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Refresh bookmarks
  Future<void> refreshBookmarks() async {
    await _loadBookmarks();
  }

  // Add bookmark from verse
  Future<bool> addBookmark(VerseModel verse, String surahName) async {
    try {
      // Check if bookmark already exists
      final existingBookmark = await _bookmarkUseCase.getBookmarkByVerseKey(_userId, verse.uniqueKey);
      
      if (existingBookmark != null) {
        // Bookmark already exists, just update the status
        final updatedStatus = Map<String, bool>.from(state.bookmarkStatus);
        updatedStatus[verse.uniqueKey] = true;
        
        // Ensure bookmark is in the list
        final bookmarkExists = state.bookmarks.any((b) => b.verseKey == verse.uniqueKey);
        final updatedBookmarks = bookmarkExists 
            ? state.bookmarks 
            : [...state.bookmarks, existingBookmark];
        
        state = state.copyWith(
          bookmarks: updatedBookmarks,
          bookmarkStatus: updatedStatus,
        );
        
        return true;
      }
      
      final bookmarkId = await _bookmarkUseCase.addBookmarkFromVerse(verse, _userId, surahName);
      
      // Validate that we got a valid bookmark ID
      if (bookmarkId <= 0) {
        // If ID is invalid, try to fetch the existing bookmark
        final fetchedBookmark = await _bookmarkUseCase.getBookmarkByVerseKey(_userId, verse.uniqueKey);
        if (fetchedBookmark != null && fetchedBookmark.id > 0) {
          // Use the fetched bookmark with valid ID
          final bookmarkExists = state.bookmarks.any((b) => b.verseKey == verse.uniqueKey);
          final updatedBookmarks = bookmarkExists 
              ? state.bookmarks.map((b) => b.verseKey == verse.uniqueKey ? fetchedBookmark : b).toList()
              : [...state.bookmarks, fetchedBookmark];
          
          final updatedStatus = Map<String, bool>.from(state.bookmarkStatus);
          updatedStatus[verse.uniqueKey] = true;
          
          state = state.copyWith(
            bookmarks: updatedBookmarks,
            bookmarkStatus: updatedStatus,
          );
          return true;
        } else {
          // This shouldn't happen, but if it does, throw an error
          throw Exception('Failed to create bookmark: invalid ID returned ($bookmarkId)');
        }
      }
      
      // New bookmark was created with valid ID
      final newBookmark = BookmarkModel(
        id: bookmarkId,
        userId: _userId,
        verseId: verse.id,
        verseKey: verse.uniqueKey,
        surahNumber: verse.surahId,
        verseNumber: verse.verseNumber,
        arabicText: verse.arabicText,
        ayatiText: verse.ayatiText,
        surahName: surahName,
        createdAt: DateTime.now(),
      );
      
      // Check if bookmark already exists in state to avoid duplicates
      final bookmarkExists = state.bookmarks.any((b) => b.verseKey == verse.uniqueKey);
      final updatedBookmarks = bookmarkExists 
          ? state.bookmarks.map((b) => b.verseKey == verse.uniqueKey ? newBookmark : b).toList()
          : [...state.bookmarks, newBookmark];
      
      final updatedStatus = Map<String, bool>.from(state.bookmarkStatus);
      updatedStatus[verse.uniqueKey] = true;
      
      state = state.copyWith(
        bookmarks: updatedBookmarks,
        bookmarkStatus: updatedStatus,
      );
      AnalyticsService().logBookmarkAdd('verse', surahNumber: verse.surahId, verseNumber: verse.verseNumber);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Remove bookmark
  Future<bool> removeBookmark(int bookmarkId) async {
    try {
      // Validate bookmark ID
      if (bookmarkId <= 0) {
        throw Exception('Invalid bookmark ID: $bookmarkId');
      }
      
      // Find the bookmark to remove first (if it exists in state)
      final bookmarkToRemove = state.bookmarks.firstWhere(
        (b) => b.id == bookmarkId,
        orElse: () => BookmarkModel(
          id: bookmarkId,
          userId: _userId,
          verseId: 0,
          verseKey: '',
          surahNumber: 0,
          verseNumber: 0,
          arabicText: '',
          ayatiText: '',
          surahName: '',
          createdAt: DateTime.now(),
        ),
      );
      
      final success = await _bookmarkUseCase.removeBookmark(bookmarkId);
      
      if (success) {
        // Update local state - remove bookmark and update status
        final updatedBookmarks = state.bookmarks.where((b) => b.id != bookmarkId).toList();
        final updatedStatus = Map<String, bool>.from(state.bookmarkStatus);
        
        // Only update status if we found the bookmark in state
        if (bookmarkToRemove.verseKey.isNotEmpty) {
          updatedStatus[bookmarkToRemove.verseKey] = false;
        }
        
        state = state.copyWith(
          bookmarks: updatedBookmarks,
          bookmarkStatus: updatedStatus,
        );
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Remove bookmark by verse key (alternative method)
  Future<bool> removeBookmarkByVerseKey(String verseKey) async {
    try {
      debugPrint('Removing bookmark with verse key: $verseKey for user: $_userId');
      
      final success = await _bookmarkUseCase.removeBookmarkByVerseKey(_userId, verseKey);
      
      debugPrint('Remove bookmark result: $success');
      
      if (success) {
        // Update local state
        final updatedBookmarks = state.bookmarks.where((b) => b.verseKey != verseKey).toList();
        final updatedStatus = Map<String, bool>.from(state.bookmarkStatus);
        updatedStatus[verseKey] = false;
        
        debugPrint('Updated bookmarks count: ${updatedBookmarks.length}');
        
        state = state.copyWith(
          bookmarks: updatedBookmarks,
          bookmarkStatus: updatedStatus,
        );
      }
      
      return success;
    } catch (e) {
      debugPrint('Error removing bookmark: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Toggle bookmark (add if not exists, remove if exists)
  Future<bool> toggleBookmark(VerseModel verse, String surahName) async {
    try {
      final isCurrentlyBookmarked = state.bookmarkStatus[verse.uniqueKey] ?? false;
      
      if (isCurrentlyBookmarked) {
        // Remove bookmark by verse key
        final success = await _bookmarkUseCase.removeBookmarkByVerseKey(_userId, verse.uniqueKey);
        
        if (success) {
          // Update local state
          final updatedBookmarks = state.bookmarks.where((b) => b.verseKey != verse.uniqueKey).toList();
          final updatedStatus = Map<String, bool>.from(state.bookmarkStatus);
          updatedStatus[verse.uniqueKey] = false;
          
          state = state.copyWith(
            bookmarks: updatedBookmarks,
            bookmarkStatus: updatedStatus,
          );
        }
        
        return success;
      } else {
        // Add new bookmark
        final success = await addBookmark(verse, surahName);
        return success;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // Check if verse is bookmarked
  bool isVerseBookmarked(String verseKey) {
    return state.bookmarkStatus[verseKey] ?? false;
  }

  // Get bookmarks by surah
  List<BookmarkModel> getBookmarksBySurah(int surahNumber) {
    return state.bookmarks.where((b) => b.surahNumber == surahNumber).toList();
  }

  // Get bookmark count
  int get bookmarkCount => state.bookmarks.length;

  // Clear all bookmarks
  Future<bool> clearAllBookmarks() async {
    try {
      // Create a copy of bookmarks list to avoid modification during iteration
      final bookmarksToRemove = List<BookmarkModel>.from(state.bookmarks);
      int failCount = 0;
      
      for (final bookmark in bookmarksToRemove) {
        try {
          final success = await _bookmarkUseCase.removeBookmark(bookmark.id);
          if (!success) {
            failCount++;
          }
        } catch (e) {
          failCount++;
          debugPrint('Error removing bookmark ${bookmark.id}: $e');
        }
      }
      
      // Update state regardless of individual failures
      // If all succeeded, clear everything; otherwise, refresh from database
      if (failCount == 0) {
        state = state.copyWith(
          bookmarks: [],
          bookmarkStatus: {},
        );
      } else {
        // If some failed, refresh from database to get accurate state
        await _loadBookmarks();
      }
      
      return failCount == 0;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

// Provider for bookmark notifier
final bookmarkNotifierProvider = StateNotifierProvider.family<BookmarkNotifier, BookmarkState, String>((ref, userId) {
  final bookmarkUseCase = ref.watch(bookmarkUseCaseProvider);
  return BookmarkNotifier(bookmarkUseCase, userId);
});

// Provider for bookmark use case
final bookmarkUseCaseProvider = Provider<BookmarkUseCase>((ref) {
  return BookmarkUseCase(ref.watch(quranRepositoryProvider));
});

// Convenience providers
final bookmarksProvider = Provider.family<List<BookmarkModel>, String>((ref, userId) {
  return ref.watch(bookmarkNotifierProvider(userId)).bookmarks;
});

final bookmarkCountProvider = Provider.family<int, String>((ref, userId) {
  return ref.watch(bookmarkNotifierProvider(userId)).bookmarks.length;
});

final isVerseBookmarkedProvider = Provider.family<bool, (String, String)>((ref, params) {
  final (userId, verseKey) = params;
  return ref.watch(bookmarkNotifierProvider(userId)).bookmarkStatus[verseKey] ?? false;
});

// Provider for bookmarks by surah
final bookmarksBySurahProvider = Provider.family<List<BookmarkModel>, (String, int)>((ref, params) {
  final (userId, surahNumber) = params;
  return ref.watch(bookmarkNotifierProvider(userId)).bookmarks
      .where((b) => b.surahNumber == surahNumber)
      .toList();
});

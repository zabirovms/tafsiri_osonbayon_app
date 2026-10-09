import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/bookmark_model.dart';

class BookmarkLocalDataSource {
  static Database? _database;
  static const String _tableName = 'bookmarks';
  static const String _databaseName = 'quran_bookmarks.db';
  static const int _databaseVersion = 1;

  // Database initialization
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        verse_id INTEGER NOT NULL,
        verse_key TEXT NOT NULL,
        surah_number INTEGER NOT NULL,
        verse_number INTEGER NOT NULL,
        arabic_text TEXT NOT NULL,
        tajik_text TEXT NOT NULL,
        surah_name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        UNIQUE(user_id, verse_key)
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_bookmarks_user_id ON $_tableName(user_id)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_bookmarks_verse_key ON $_tableName(verse_key)
    ''');
    
    await db.execute('''
      CREATE INDEX idx_bookmarks_surah_number ON $_tableName(surah_number)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migration logic for database schema changes
    // This ensures existing bookmarks are preserved when schema changes
    
    try {
      // Version 1 to 2 migration
      if (oldVersion < 2) {
        // Example: If you need to add a new column in version 2:
        // await db.execute('ALTER TABLE $_tableName ADD COLUMN new_field TEXT');
        // For now, version 1 is current, so no migration needed
      }
      
      // Version 2 to 3 migration
      if (oldVersion < 3) {
        // Future migrations go here
      }
      
      // Always recreate indexes after schema changes
      // Note: SQLite doesn't support DROP INDEX IF EXISTS, so we'll skip if they exist
      // Indexes are automatically recreated if table is recreated
      
      debugPrint('[BookmarkLocalDataSource] Database migrated from version $oldVersion to $newVersion');
    } catch (e) {
      debugPrint('[BookmarkLocalDataSource] Migration error: $e');
      // Re-throw to prevent database corruption
      rethrow;
    }
  }

  // Add a bookmark
  Future<int> addBookmark(BookmarkModel bookmark) async {
    final db = await database;
    
    try {
      // First check if bookmark already exists
      final existing = await db.query(
        _tableName,
        where: 'user_id = ? AND verse_key = ?',
        whereArgs: [bookmark.userId, bookmark.verseKey],
        limit: 1,
      );
      
      if (existing.isNotEmpty) {
        // Bookmark already exists, return existing ID
        return existing.first['id'] as int;
      }
      
      // Insert new bookmark
      // Remove id from JSON since it's auto-increment
      final bookmarkJson = bookmark.toJson();
      bookmarkJson.remove('id'); // Let database assign the ID
      
      final id = await db.insert(
        _tableName,
        bookmarkJson,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      
      debugPrint('Insert result: id=$id');
      
      // If insert returns 0 (conflict or error), try to get the existing bookmark ID
      if (id == 0) {
        debugPrint('Insert returned 0, checking for existing bookmark...');
        // Try to get the existing bookmark ID
        final existing = await db.query(
          _tableName,
          where: 'user_id = ? AND verse_key = ?',
          whereArgs: [bookmark.userId, bookmark.verseKey],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          final existingId = existing.first['id'] as int;
          debugPrint('Found existing bookmark with ID: $existingId');
          return existingId;
        } else {
          // This shouldn't happen, but if it does, throw an error
          throw Exception('Failed to insert bookmark and no existing bookmark found');
        }
      }
      
      debugPrint('Successfully inserted bookmark with ID: $id');
      return id;
    } catch (e) {
      throw Exception('Failed to add bookmark: $e');
    }
  }

  // Get all bookmarks for a user
  Future<List<BookmarkModel>> getBookmarksByUser(String userId) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => BookmarkModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to get bookmarks: $e');
    }
  }

  // Remove a bookmark by ID
  Future<bool> removeBookmark(int bookmarkId) async {
    final db = await database;
    
    try {
      if (bookmarkId <= 0) {
        debugPrint('Invalid bookmark ID: $bookmarkId');
        return false;
      }
      
      // First check if the bookmark exists
      final existing = await db.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [bookmarkId],
        limit: 1,
      );
      
      if (existing.isEmpty) {
        debugPrint('No bookmark found with ID: $bookmarkId');
        return false;
      }
      
      debugPrint('Removing bookmark with ID: $bookmarkId');
      final result = await db.delete(
        _tableName,
        where: 'id = ?',
        whereArgs: [bookmarkId],
      );
      
      debugPrint('Delete result: $result rows affected');
      
      if (result > 0) {
        // Verify deletion
        final verify = await db.query(
          _tableName,
          where: 'id = ?',
          whereArgs: [bookmarkId],
          limit: 1,
        );
        return verify.isEmpty;
      }
      
      return false;
    } catch (e, stackTrace) {
      debugPrint('Error removing bookmark by ID: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to remove bookmark: $e');
    }
  }

  // Remove a bookmark by verse key and user ID
  Future<bool> removeBookmarkByVerseKey(String userId, String verseKey) async {
    final db = await database;
    
    try {
      debugPrint('Database: Removing bookmark with user_id: $userId, verse_key: $verseKey');
      
      // Validate inputs
      if (userId.isEmpty || verseKey.isEmpty) {
        debugPrint('Invalid input: userId or verseKey is empty');
        return false;
      }
      
      // First check if the bookmark exists
      final existing = await db.query(
        _tableName,
        where: 'user_id = ? AND verse_key = ?',
        whereArgs: [userId, verseKey],
        limit: 1,
      );
      
      debugPrint('Found ${existing.length} bookmarks to remove');
      
      if (existing.isEmpty) {
        debugPrint('No bookmark found to remove with user_id: $userId, verse_key: $verseKey');
        // Check if there are any bookmarks for this user at all
        final userBookmarks = await db.query(
          _tableName,
          where: 'user_id = ?',
          whereArgs: [userId],
          limit: 5,
        );
        debugPrint('Total bookmarks for user: ${userBookmarks.length}');
        if (userBookmarks.isNotEmpty) {
          debugPrint('Sample verse keys: ${userBookmarks.map((b) => b['verse_key']).join(', ')}');
        }
        return false;
      }
      
      // Get the bookmark ID for logging
      final bookmarkId = existing.first['id'];
      debugPrint('Removing bookmark with ID: $bookmarkId');
      
      final result = await db.delete(
        _tableName,
        where: 'user_id = ? AND verse_key = ?',
        whereArgs: [userId, verseKey],
      );
      
      debugPrint('Delete result: $result rows affected');
      
      if (result > 0) {
        // Verify deletion
        final verify = await db.query(
          _tableName,
          where: 'user_id = ? AND verse_key = ?',
          whereArgs: [userId, verseKey],
          limit: 1,
        );
        debugPrint('Verification: bookmark still exists: ${verify.isNotEmpty}');
        return verify.isEmpty;
      }
      
      return false;
    } catch (e, stackTrace) {
      debugPrint('Database error: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to remove bookmark by verse key: $e');
    }
  }

  // Check if a verse is bookmarked
  Future<bool> isBookmarked(String userId, String verseKey) async {
    final db = await database;
    
    try {
      final result = await db.query(
        _tableName,
        where: 'user_id = ? AND verse_key = ?',
        whereArgs: [userId, verseKey],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check bookmark status: $e');
    }
  }

  // Get bookmark by verse key and user ID
  Future<BookmarkModel?> getBookmarkByVerseKey(String userId, String verseKey) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ? AND verse_key = ?',
        whereArgs: [userId, verseKey],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return BookmarkModel.fromJson(maps.first);
    } catch (e) {
      throw Exception('Failed to get bookmark by verse key: $e');
    }
  }

  // Get bookmarks by surah
  Future<List<BookmarkModel>> getBookmarksBySurah(String userId, int surahNumber) async {
    final db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'user_id = ? AND surah_number = ?',
        whereArgs: [userId, surahNumber],
        orderBy: 'verse_number ASC',
      );

      return maps.map((map) => BookmarkModel.fromJson(map)).toList();
    } catch (e) {
      throw Exception('Failed to get bookmarks by surah: $e');
    }
  }

  // Clear all bookmarks for a user
  Future<bool> clearUserBookmarks(String userId) async {
    final db = await database;
    
    try {
      final result = await db.delete(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return result >= 0;
    } catch (e) {
      throw Exception('Failed to clear user bookmarks: $e');
    }
  }

  // Get total bookmark count for a user
  Future<int> getBookmarkCount(String userId) async {
    final db = await database;
    
    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM $_tableName WHERE user_id = ?',
        [userId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get bookmark count: $e');
    }
  }

  // Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

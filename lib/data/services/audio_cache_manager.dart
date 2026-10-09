import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Cache entry metadata for audio files
class AudioCacheEntry {
  final String reciterId;
  final int surahNumber;
  final String filePath;
  final int fileSizeBytes;
  final DateTime lastAccessed;
  final DateTime downloadedAt;

  AudioCacheEntry({
    required this.reciterId,
    required this.surahNumber,
    required this.filePath,
    required this.fileSizeBytes,
    required this.lastAccessed,
    required this.downloadedAt,
  });

  Map<String, dynamic> toJson() => {
        'reciterId': reciterId,
        'surahNumber': surahNumber,
        'filePath': filePath,
        'fileSizeBytes': fileSizeBytes,
        'lastAccessed': lastAccessed.toIso8601String(),
        'downloadedAt': downloadedAt.toIso8601String(),
      };

  factory AudioCacheEntry.fromJson(Map<String, dynamic> json) => AudioCacheEntry(
        reciterId: json['reciterId'] as String,
        surahNumber: json['surahNumber'] as int,
        filePath: json['filePath'] as String,
        lastAccessed: DateTime.parse(json['lastAccessed'] as String),
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
        fileSizeBytes: json['fileSizeBytes'] as int,
      );

  String get key => '$reciterId:$surahNumber';
}

/// Manages LRU cache for downloaded audio files
/// Implements least-recently-used policy to limit storage usage
class AudioCacheManager {
  static const String _cacheMetadataKey = 'audio_cache_metadata';
  static const int _maxCacheSizeMB = 40; // Maximum cache size in MB (lowered to keep app storage footprint tiny)
  static const int _maxCacheSizeBytes = _maxCacheSizeMB * 1024 * 1024;

  /// Automatically clean up old temporary audio caches and enforce 40MB cap
  Future<void> autoCleanOldCaches() async {
    if (kIsWeb) return;
    try {
      await _enforceCacheLimit();

      // Clean temporary audio files older than 3 days
      final tempDir = await getTemporaryDirectory();
      final cacheDir = Directory('${tempDir.path}/audio_cache');
      if (await cacheDir.exists()) {
        final now = DateTime.now();
        final files = await cacheDir.list(recursive: false).toList();
        for (final entity in files) {
          if (entity is File) {
            try {
              final stat = await entity.stat();
              if (now.difference(stat.modified).inDays >= 3) {
                await entity.delete();
                debugPrint('[AudioCache] Auto-cleaned old cache file: ${entity.path}');
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      debugPrint('[AudioCache] Error during autoCleanOldCaches: $e');
    }
  }

  /// Get cache directory path (in system temporary directory so OS classifies it as cache)
  Future<String> getCacheDirectory() async {
    if (kIsWeb) throw Exception('Cache not supported on web');
    final directory = await getTemporaryDirectory();
    return '${directory.path}/audio_cache';
  }

  /// Register a file in the cache
  Future<void> registerFile({
    required String reciterId,
    required int surahNumber,
    required String filePath,
  }) async {
    if (kIsWeb) return;

    try {
      final file = File(filePath);
      if (!await file.exists()) return;

      final fileSize = await file.length();
      final entries = await _loadCacheMetadata();
      
      // Remove existing entry if any
      entries.removeWhere((e) => e.key == '$reciterId:$surahNumber');
      
      // Add new entry
      entries.add(AudioCacheEntry(
        reciterId: reciterId,
        surahNumber: surahNumber,
        filePath: filePath,
        fileSizeBytes: fileSize,
        lastAccessed: DateTime.now(),
        downloadedAt: DateTime.now(),
      ));

      await _saveCacheMetadata(entries);
      
      // Check cache size and evict if needed
      await _enforceCacheLimit();
    } catch (e) {
      debugPrint('[AudioCache] Error registering file: $e');
    }
  }

  /// Update last accessed time
  Future<void> updateAccessTime(String reciterId, int surahNumber) async {
    if (kIsWeb) return;

    try {
      final entries = await _loadCacheMetadata();
      final key = '$reciterId:$surahNumber';
      final index = entries.indexWhere((e) => e.key == key);
      
      if (index != -1) {
        final entry = entries[index];
        entries[index] = AudioCacheEntry(
          reciterId: entry.reciterId,
          surahNumber: entry.surahNumber,
          filePath: entry.filePath,
          fileSizeBytes: entry.fileSizeBytes,
          lastAccessed: DateTime.now(),
          downloadedAt: entry.downloadedAt,
        );
        await _saveCacheMetadata(entries);
      }
    } catch (e) {
      debugPrint('[AudioCache] Error updating access time: $e');
    }
  }

  Future<String> _resolvePath(String storedPath) async {
    final tempDir = await getTemporaryDirectory();
    final docsDir = await getApplicationDocumentsDirectory();
    final uri = Uri.file(storedPath);
    final fileName = uri.pathSegments.last;
    if (storedPath.contains('/audio_cache/')) {
      final tempPath = '${tempDir.path}/audio_cache/$fileName';
      if (await File(tempPath).exists()) {
        return tempPath;
      }
      final legacyPath = '${docsDir.path}/audio_cache/$fileName';
      if (await File(legacyPath).exists()) {
        return legacyPath;
      }
      return tempPath;
    } else {
      return '${docsDir.path}/audio/$fileName';
    }
  }

  /// Get file path from cache
  Future<String?> getCachedFile(String reciterId, int surahNumber) async {
    if (kIsWeb) return null;

    try {
      final entries = await _loadCacheMetadata();
      final key = '$reciterId:$surahNumber';
      final entry = entries.firstWhere(
        (e) => e.key == key,
        orElse: () => throw StateError('Not found'),
      );

      final resolvedPath = await _resolvePath(entry.filePath);
      // Check if file still exists
      final file = File(resolvedPath);
      if (await file.exists()) {
        // Update access time
        await updateAccessTime(reciterId, surahNumber);
        return resolvedPath;
      } else {
        // File deleted, remove from cache
        entries.removeWhere((e) => e.key == key);
        await _saveCacheMetadata(entries);
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Enforce cache size limit using LRU policy
  Future<void> _enforceCacheLimit() async {
    if (kIsWeb) return;

    try {
      final entries = await _loadCacheMetadata();
      int totalSize = entries.fold(0, (sum, e) => sum + e.fileSizeBytes);

      if (totalSize <= _maxCacheSizeBytes) return;

      // Sort by last accessed (LRU)
      entries.sort((a, b) => a.lastAccessed.compareTo(b.lastAccessed));

      // Remove least recently used files until under limit
      while (totalSize > _maxCacheSizeBytes && entries.isNotEmpty) {
        final entry = entries.removeAt(0);
        totalSize -= entry.fileSizeBytes;

        try {
          final resolvedPath = await _resolvePath(entry.filePath);
          final file = File(resolvedPath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('[AudioCache] Evicted: ${entry.key} (${(entry.fileSizeBytes / 1024 / 1024).toStringAsFixed(2)} MB)');
          }
        } catch (e) {
          debugPrint('[AudioCache] Error deleting file: $e');
        }
      }

      await _saveCacheMetadata(entries);
      debugPrint('[AudioCache] Cache size after eviction: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
    } catch (e) {
      debugPrint('[AudioCache] Error enforcing cache limit: $e');
    }
  }

  /// Get current cache size
  Future<int> getCacheSize() async {
    if (kIsWeb) return 0;

    try {
      final entries = await _loadCacheMetadata();
      return entries.fold<int>(0, (int sum, AudioCacheEntry e) => sum + e.fileSizeBytes);
    } catch (e) {
      return 0;
    }
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    if (kIsWeb) return;

    try {
      final entries = await _loadCacheMetadata();
      final cacheDir = await getCacheDirectory();
      final dir = Directory(cacheDir);

      // Delete all files
      for (final entry in entries) {
        try {
          final resolvedPath = await _resolvePath(entry.filePath);
          final file = File(resolvedPath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('[AudioCache] Error deleting file: $e');
        }
      }

      // Clear directory if empty
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }

      await _saveCacheMetadata([]);
      debugPrint('[AudioCache] Cache cleared');
    } catch (e) {
      debugPrint('[AudioCache] Error clearing cache: $e');
    }
  }

  /// Load cache metadata
  Future<List<AudioCacheEntry>> _loadCacheMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheMetadataKey);
      if (jsonString == null) return [];

      final jsonList = json.decode(jsonString) as List<dynamic>;
      return jsonList
          .map((jsonItem) => AudioCacheEntry.fromJson(jsonItem as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[AudioCache] Error loading metadata: $e');
      return [];
    }
  }

  /// Save cache metadata
  Future<void> _saveCacheMetadata(List<AudioCacheEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_cacheMetadataKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('[AudioCache] Error saving metadata: $e');
    }
  }
}


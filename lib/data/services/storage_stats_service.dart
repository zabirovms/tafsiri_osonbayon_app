import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'audio_cache_manager.dart';

class StorageBreakdown {
  final int databaseSizeBytes;
  final int audioCacheSizeBytes;
  final int imageCacheSizeBytes;
  final int downloadedAudioSizeBytes;

  const StorageBreakdown({
    this.databaseSizeBytes = 0,
    this.audioCacheSizeBytes = 0,
    this.imageCacheSizeBytes = 0,
    this.downloadedAudioSizeBytes = 0,
  });

  int get totalCacheSizeBytes => audioCacheSizeBytes + imageCacheSizeBytes;
  int get totalAppSizeBytes => databaseSizeBytes + audioCacheSizeBytes + imageCacheSizeBytes + downloadedAudioSizeBytes;

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String get databaseSizeFormatted => formatBytes(databaseSizeBytes);
  String get audioCacheSizeFormatted => formatBytes(audioCacheSizeBytes);
  String get imageCacheSizeFormatted => formatBytes(imageCacheSizeBytes);
  String get downloadedAudioSizeFormatted => formatBytes(downloadedAudioSizeBytes);
  String get totalCacheSizeFormatted => formatBytes(totalCacheSizeBytes);
  String get totalAppSizeFormatted => formatBytes(totalAppSizeBytes);
}

class StorageStatsService {
  final AudioCacheManager _audioCacheManager = AudioCacheManager();

  /// Calculate size of a directory recursively
  Future<int> _calculateDirSize(Directory dir) async {
    if (!await dir.exists()) return 0;
    int totalSize = 0;
    try {
      final List<FileSystemEntity> entities = await dir.list(recursive: true, followLinks: false).toList();
      for (final entity in entities) {
        if (entity is File) {
          try {
            totalSize += await entity.length();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('[StorageStatsService] Error calculating dir size for ${dir.path}: $e');
    }
    return totalSize;
  }

  /// Get complete storage breakdown
  Future<StorageBreakdown> getStorageBreakdown() async {
    if (kIsWeb) {
      return const StorageBreakdown();
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final tempDir = await getTemporaryDirectory();

      // 1. Databases (quran_prebuilt.sqlite, bukhari_prebuilt.db, hive boxes)
      int dbSize = 0;
      final quranDb = File('${docsDir.path}/quran_prebuilt.sqlite');
      if (await quranDb.exists()) {
        dbSize += await quranDb.length();
      }
      final bukhariDb = File('${docsDir.path}/bukhari_prebuilt.db');
      if (await bukhariDb.exists()) {
        dbSize += await bukhariDb.length();
      }

      // Check WAL/SHM files
      final walFile = File('${docsDir.path}/quran_prebuilt.sqlite-wal');
      if (await walFile.exists()) dbSize += await walFile.length();
      final shmFile = File('${docsDir.path}/quran_prebuilt.sqlite-shm');
      if (await shmFile.exists()) dbSize += await shmFile.length();

      // 2. Audio Cache
      final audioCacheSize = await _audioCacheManager.getCacheSize();

      // Check both temp audio_cache and legacy docs audio_cache
      final tempAudioCacheDir = Directory('${tempDir.path}/audio_cache');
      final extraTempSize = await _calculateDirSize(tempAudioCacheDir);
      final legacyAudioCacheDir = Directory('${docsDir.path}/audio_cache');
      final extraLegacySize = await _calculateDirSize(legacyAudioCacheDir);

      final totalAudioCacheSize = audioCacheSize > (extraTempSize + extraLegacySize)
          ? audioCacheSize
          : (extraTempSize + extraLegacySize);

      // 3. Image Cache
      final libCacheDir = Directory('${tempDir.path}/libCachedImageData');
      final imageCacheSize = await _calculateDirSize(libCacheDir);

      // 4. Downloaded Audio
      final downloadedAudioDir = Directory('${docsDir.path}/audio');
      final downloadedAudioSize = await _calculateDirSize(downloadedAudioDir);

      return StorageBreakdown(
        databaseSizeBytes: dbSize,
        audioCacheSizeBytes: totalAudioCacheSize,
        imageCacheSizeBytes: imageCacheSize,
        downloadedAudioSizeBytes: downloadedAudioSize,
      );
    } catch (e) {
      debugPrint('[StorageStatsService] Error getting storage breakdown: $e');
      return const StorageBreakdown();
    }
  }

  /// Clear temporary audio cache
  Future<void> clearAudioCache() async {
    if (kIsWeb) return;
    try {
      await _audioCacheManager.clearCache();

      final tempDir = await getTemporaryDirectory();
      final docsDir = await getApplicationDocumentsDirectory();

      final tempAudioCacheDir = Directory('${tempDir.path}/audio_cache');
      if (await tempAudioCacheDir.exists()) {
        await tempAudioCacheDir.delete(recursive: true);
      }

      final legacyAudioCacheDir = Directory('${docsDir.path}/audio_cache');
      if (await legacyAudioCacheDir.exists()) {
        await legacyAudioCacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[StorageStatsService] Error clearing audio cache: $e');
    }
  }

  /// Clear network image cache
  Future<void> clearImageCache() async {
    if (kIsWeb) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final libCacheDir = Directory('${tempDir.path}/libCachedImageData');
      if (await libCacheDir.exists()) {
        await libCacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[StorageStatsService] Error clearing image cache: $e');
    }
  }

  /// Clear all clearable cache (audio + images)
  Future<void> clearAllCache() async {
    await clearAudioCache();
    await clearImageCache();
  }
}

final storageStatsServiceProvider = Provider<StorageStatsService>((ref) => StorageStatsService());

final storageBreakdownProvider = FutureProvider.autoDispose<StorageBreakdown>((ref) async {
  final service = ref.watch(storageStatsServiceProvider);
  return await service.getStorageBreakdown();
});

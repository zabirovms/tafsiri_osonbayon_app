import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode, debugPrint;
import 'package:http/http.dart' as http;
import '../../core/utils/reciter_id_mapper.dart';
import '../../core/utils/audio_url_builder.dart';
import '../../core/constants/audio_constants.dart';
import 'audio_manifest_service_v2.dart';
import 'audio_cache_manager.dart';

class AudioDownload {
  final String reciterId;
  final int surahNumber;
  final String fileName;
  final String url;
  final DateTime downloadedAt;
  final int fileSizeBytes;

  AudioDownload({
    required this.reciterId,
    required this.surahNumber,
    required this.fileName,
    required this.url,
    required this.downloadedAt,
    required this.fileSizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'reciterId': reciterId,
        'surahNumber': surahNumber,
        'fileName': fileName,
        'url': url,
        'downloadedAt': downloadedAt.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
      };

  factory AudioDownload.fromJson(Map<String, dynamic> json) => AudioDownload(
        reciterId: json['reciterId'] as String,
        surahNumber: json['surahNumber'] as int,
        fileName: json['fileName'] as String,
        url: json['url'] as String,
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
        fileSizeBytes: json['fileSizeBytes'] as int,
      );

  String get key => '$reciterId:$surahNumber';
}

class AudioDownloadsService {
  static const String _key = 'audio_downloads';
  // Removed manifest service dependency - using hardcoded URL construction
  final AudioCacheManager _cacheManager = AudioCacheManager();
  
  /// Get bitrate for full surah playback (uses centralized method from AudioManifestServiceV2)
  /// Returns default bitrate as fallback if bitrate is not confirmed (for backward compatibility)
  int _getSurahBitrate(String cdnId) {
    return AudioManifestServiceV2.getSurahBitrate(cdnId) ?? AudioConstants.defaultBitrate;
  }

  Future<List<AudioDownload>> getDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => AudioDownload.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> isDownloaded(String reciterId, int surahNumber) async {
    if (kIsWeb) return false;
    
    final downloads = await getDownloads();
    final key = '$reciterId:$surahNumber';
    final download = downloads.firstWhere(
      (d) => d.key == key,
      orElse: () => AudioDownload(
        reciterId: '',
        surahNumber: 0,
        fileName: '',
        url: '',
        downloadedAt: DateTime.now(),
        fileSizeBytes: 0,
      ),
    );
    
    if (download.reciterId.isEmpty) return false;
    
    // Check if file actually exists
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/audio/${download.fileName}');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  Future<String?> downloadSurah(
    String reciterId,
    int surahNumber, {
    Function(int current, int total)? onProgress,
  }) async {
    if (kIsWeb) {
      throw Exception('Downloads not supported on web');
    }

    try {
      // Use centralized URL construction (no manifest dependency)
      // Reciter ID is already a CDN ID, no conversion needed
      final cdnReciterId = reciterId;
      // Get appropriate bitrate (most use 128, but some use 192 or 64)
      final bitrate = _getSurahBitrate(cdnReciterId);
      final url = AudioUrlBuilder.buildSurahUrl(cdnReciterId, surahNumber, bitrate: bitrate);
      final fileName = '${reciterId}_$surahNumber${AudioConstants.audioFileExtension}'; // Keep app ID for filename

      final directory = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${directory.path}/audio');
      if (!await audioDir.exists()) {
        await audioDir.create(recursive: true);
      }

      final filePath = '${audioDir.path}/$fileName';
      final file = File(filePath);

      // Check if already downloaded
      if (await file.exists()) {
        await _addDownloadRecord(reciterId, surahNumber, fileName, url, await file.length());
        return filePath;
      }

      // Download the file with progress tracking
      final request = http.Request('GET', Uri.parse(url));
      final streamedResponse = await http.Client().send(request);
      
      if (streamedResponse.statusCode != 200) {
        throw Exception('Failed to download: HTTP ${streamedResponse.statusCode}');
      }

      final contentLength = streamedResponse.contentLength ?? 0;
      final bytes = <int>[];
      int downloadedBytes = 0;

      await for (final chunk in streamedResponse.stream) {
        bytes.addAll(chunk);
        downloadedBytes += chunk.length;
        
        // Report progress if callback provided
        if (onProgress != null && contentLength > 0) {
          onProgress(downloadedBytes, contentLength);
        }
      }

      await file.writeAsBytes(bytes);
      await _addDownloadRecord(reciterId, surahNumber, fileName, url, bytes.length);
      
      // Register in LRU cache
      await _cacheManager.registerFile(
        reciterId: reciterId,
        surahNumber: surahNumber,
        filePath: filePath,
      );

      return filePath;
    } catch (e) {
      throw Exception('Failed to download audio: $e');
    }
  }

  Future<bool> deleteDownload(String reciterId, int surahNumber) async {
    if (kIsWeb) return false;

    try {
      final downloads = await getDownloads();
      final key = '$reciterId:$surahNumber';
      final download = downloads.firstWhere(
        (d) => d.key == key,
        orElse: () => AudioDownload(
          reciterId: '',
          surahNumber: 0,
          fileName: '',
          url: '',
          downloadedAt: DateTime.now(),
          fileSizeBytes: 0,
        ),
      );

      if (download.reciterId.isEmpty) return false;

      // Delete file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/audio/${download.fileName}');
      if (await file.exists()) {
        await file.delete();
      }

      // Remove from records
      downloads.removeWhere((d) => d.key == key);
      await _saveDownloads(downloads);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<AudioDownload>> getDownloadsByReciter(String reciterId) async {
    final downloads = await getDownloads();
    return downloads.where((d) => d.reciterId == reciterId).toList();
  }

  Future<String?> getDownloadPath(String reciterId, int surahNumber) async {
    if (kIsWeb) return null;

    try {
      // First check LRU cache
      final cachedPath = await _cacheManager.getCachedFile(reciterId, surahNumber);
      if (cachedPath != null) {
        return cachedPath;
      }

      // Fallback to old download records
      final downloads = await getDownloads();
      final key = '$reciterId:$surahNumber';
      final download = downloads.firstWhere(
        (d) => d.key == key,
        orElse: () => AudioDownload(
          reciterId: '',
          surahNumber: 0,
          fileName: '',
          url: '',
          downloadedAt: DateTime.now(),
          fileSizeBytes: 0,
        ),
      );

      if (download.reciterId.isEmpty) return null;

      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/audio/${download.fileName}');
        if (await file.exists()) {
          // Register in cache for future LRU management
          await _cacheManager.registerFile(
            reciterId: reciterId,
            surahNumber: surahNumber,
            filePath: file.path,
          );
          return file.path;
        }
      } catch (e) {
        // Ignore
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _addDownloadRecord(
    String reciterId,
    int surahNumber,
    String fileName,
    String url,
    int fileSizeBytes,
  ) async {
    final downloads = await getDownloads();
    final key = '$reciterId:$surahNumber';
    
    // Remove existing if any
    downloads.removeWhere((d) => d.key == key);

    downloads.add(AudioDownload(
      reciterId: reciterId,
      surahNumber: surahNumber,
      fileName: fileName,
      url: url,
      downloadedAt: DateTime.now(),
      fileSizeBytes: fileSizeBytes,
    ));

    await _saveDownloads(downloads);
  }

  Future<void> _saveDownloads(List<AudioDownload> downloads) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = downloads.map((d) => d.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }

  /// Verify that all downloaded audio files still exist
  /// Removes orphaned metadata entries for files that no longer exist
  /// Should be called during app migrations or startup
  Future<void> verifyDownloadedFiles() async {
    if (kIsWeb) return;
    
    try {
      final downloads = await getDownloads();
      if (downloads.isEmpty) return;
      
      final validDownloads = <AudioDownload>[];
      int orphanedCount = 0;
      
      for (final download in downloads) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/audio/${download.fileName}');
          
          if (await file.exists()) {
            validDownloads.add(download);
          } else {
            // File missing - mark as orphaned
            orphanedCount++;
            if (kDebugMode) {
              debugPrint('[AudioDownloadsService] Orphaned download detected: ${download.key} (file: ${download.fileName})');
            }
          }
        } catch (e) {
          // Error checking file - skip this download
          if (kDebugMode) {
            debugPrint('[AudioDownloadsService] Error verifying file ${download.fileName}: $e');
          }
        }
      }
      
      // Update metadata to remove orphaned entries
      if (validDownloads.length != downloads.length) {
        await _saveDownloads(validDownloads);
        if (kDebugMode) {
          debugPrint('[AudioDownloadsService] Cleaned up $orphanedCount orphaned download entries');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AudioDownloadsService] Error verifying downloaded files: $e');
      }
      // Don't throw - allow app to continue
    }
  }
}


import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/utils/compressed_json_loader.dart';

/// Alignment segment: [word_start_index, word_end_index, start_msec, end_msec]
/// - word_start_index: 0-based index of the word start
/// - word_end_index: 0-based index of the word end (exclusive)
/// - start_msec: Start time in milliseconds
/// - end_msec: End time in milliseconds
typedef AlignmentSegment = List<dynamic>;

/// Alignment data for a single verse
class VerseAlignment {
  final int surah;
  final int ayah;
  final List<AlignmentSegment> segments;
  final Map<String, dynamic>? stats;

  VerseAlignment({
    required this.surah,
    required this.ayah,
    required this.segments,
    this.stats,
  });

  factory VerseAlignment.fromJson(Map<String, dynamic> json) {
    return VerseAlignment(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      segments: (json['segments'] as List<dynamic>)
          .map((s) => s as List<dynamic>)
          .toList(),
      stats: json['stats'] as Map<String, dynamic>?,
    );
  }
}

/// Map reciter IDs to alignment filenames (compressed .gz format)
/// Only includes reciters that actually support verse-by-verse audio playback
/// Bitrate in filename may differ from actual audio bitrate (timestamp files are aligned to specific recordings)
const Map<String, String> _reciterAlignmentMap = {
  // 128 kbps (default) - verse-by-verse supported
  'ar.alafasy': 'Alafasy_128kbps.json',
  'ar.shaatree': 'Abu_Bakr_Ash-Shaatree_128kbps.json',
  'ar.husarymujawwad': 'Husary_Muallim_128kbps.json',
  'ar.minshawi': 'Minshawy_Murattal_128kbps.json',
  
  // 192 kbps - verse-by-verse supported
  'ar.hanirifai': 'Hani_Rifai_192kbps.json',
  
  // 64 kbps - verse-by-verse supported (note: filenames may show different bitrates, but timestamps match the actual recordings)
  'ar.husary': 'Husary_64kbps.json', // Audio is 128kbps, but timestamp file is for 64kbps recording
  'ar.minshawimujawwad': 'Minshawy_Mujawwad_192kbps.json', // Audio is 64kbps, but timestamp file is for 192kbps recording
  'ar.saoodshuraym': 'Saood_ash-Shuraym_128kbps.json', // Audio is 64kbps, but timestamp file is for 128kbps recording
  'ar.abdulbasitmurattal': 'Abdul_Basit_Murattal_64kbps.json', // Audio is 192kbps, but timestamp file is for 64kbps recording
  
  // Note: ar.abdulbasitmujawwad and ar.mohammadaltablaway do NOT support verse-by-verse audio
  // They are only available for full surah playback, so no alignment data is needed
};

/// Service for loading and managing word-by-word timestamp alignment data
class AlignmentDataService {
  static final AlignmentDataService _instance = AlignmentDataService._internal();
  factory AlignmentDataService() => _instance;
  AlignmentDataService._internal();

  /// Cache for loaded alignment data
  final Map<String, List<VerseAlignment>> _cache = {};

  /// Check if a reciter has alignment data available
  bool hasAlignmentData(String reciterId) {
    return _reciterAlignmentMap.containsKey(reciterId.toLowerCase());
  }

  /// Get alignment filename for a reciter
  String? _getAlignmentFilename(String reciterId) {
    return _reciterAlignmentMap[reciterId.toLowerCase()];
  }

  /// Load alignment data for a reciter
  Future<List<VerseAlignment>> loadAlignmentData(String reciterId) async {
    final filename = _getAlignmentFilename(reciterId);
    if (filename == null) {
      throw Exception('No alignment data available for reciter: $reciterId');
    }

    // Check cache first
    final cacheKey = reciterId.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    try {
      // Load from assets/data/reciters/wbw-timestamps/ (compressed .gz format)
      final assetPath = 'assets/data/reciters/wbw-timestamps/$filename';
      final List<dynamic> jsonList = await CompressedJsonLoader.loadJsonAsList(assetPath);
      
      final alignments = jsonList
          .map((json) => VerseAlignment.fromJson(json as Map<String, dynamic>))
          .toList();

      // Cache the data
      _cache[cacheKey] = alignments;

      return alignments;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AlignmentDataService: Failed to load alignment data for $reciterId: $e');
      }
      rethrow;
    }
  }

  /// Get alignment data for a specific verse
  Future<VerseAlignment?> getAlignmentForVerse(
    String reciterId,
    int surahNumber,
    int verseNumber,
  ) async {
    try {
      final allAlignments = await loadAlignmentData(reciterId);
      final alignment = allAlignments.firstWhere(
        (a) => a.surah == surahNumber && a.ayah == verseNumber,
        orElse: () => throw StateError('Alignment not found'),
      );
      return alignment;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AlignmentDataService: Failed to get alignment for verse $surahNumber:$verseNumber: $e');
      }
      return null;
    }
  }

  /// Get the current word index based on playback position
  /// @param alignment Alignment data for the verse
  /// @param currentTimeMs Current playback time in milliseconds
  /// @returns Word index (0-based) or null if not found
  int? getCurrentWordIndex(
    VerseAlignment? alignment,
    int currentTimeMs,
  ) {
    if (alignment == null || alignment.segments.isEmpty) {
      return null;
    }

    // Find the segment that contains the current time
    for (final segment in alignment.segments) {
      final wordStartIndex = segment[0] as int;
      final startMsec = segment[2] as int;
      final endMsec = segment[3] as int;

      // Check if current time is within this segment
      if (currentTimeMs >= startMsec && currentTimeMs < endMsec) {
        return wordStartIndex;
      }
    }

    // If we're past the last segment, return the last word index
    final lastSegment = alignment.segments.last;
    if (lastSegment.isNotEmpty && currentTimeMs >= (lastSegment[3] as int)) {
      return lastSegment[0] as int;
    }

    // If we're before the first segment, return null
    final firstSegment = alignment.segments.first;
    if (firstSegment.isNotEmpty && currentTimeMs < (firstSegment[2] as int)) {
      return null;
    }

    return null;
  }

  /// Convert word index (0-based from alignment) to word number (1-based for qpc-hafs)
  int? wordIndexToWordNumber(int? wordIndex) {
    if (wordIndex == null) return null;
    return wordIndex + 1;
  }

  /// Convert word number (1-based for qpc-hafs) to word index (0-based from alignment)
  int wordNumberToWordIndex(int wordNumber) {
    return wordNumber - 1;
  }

  /// Get the start time (in seconds) for a specific word in a verse
  /// @param alignment Alignment data for the verse
  /// @param wordNumber Word number (1-based)
  /// @returns Start time in seconds, or null if not found
  double? getWordStartTime(
    VerseAlignment? alignment,
    int wordNumber,
  ) {
    if (alignment == null || alignment.segments.isEmpty) {
      return null;
    }

    final wordIndex = wordNumberToWordIndex(wordNumber);

    // Find the segment that starts with this word index
    for (final segment in alignment.segments) {
      final wordStartIndex = segment[0] as int;
      final startMsec = segment[2] as int;

      if (wordStartIndex == wordIndex) {
        // Convert milliseconds to seconds
        return startMsec / 1000.0;
      }
    }

    return null;
  }

  /// Clear cache (useful for testing or forcing reload)
  void clearCache() {
    _cache.clear();
  }
}

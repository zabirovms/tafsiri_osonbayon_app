import '../constants/audio_constants.dart';

/// Utility class for constructing audio URLs dynamically
/// Centralized URL construction - use this everywhere instead of hardcoded strings
class AudioUrlBuilder {
  /// Build surah audio URL
  /// 
  /// [cdnId] - CDN edition ID (e.g., 'ar.abdulbasitmurattal')
  /// [surahNumber] - Surah number (1-114)
  /// [bitrate] - Audio bitrate (128, 192, 64, etc.). If null, uses default from constants.
  static String buildSurahUrl(
    String cdnId,
    int surahNumber, {
    int? bitrate,
  }) {
    final br = bitrate ?? AudioConstants.defaultBitrate;
    return '${AudioConstants.cdnBaseUrl}/${AudioConstants.surahAudioPath}/$br/$cdnId/$surahNumber${AudioConstants.audioFileExtension}';
  }

  /// Build verse audio URL
  /// 
  /// [cdnId] - CDN edition ID
  /// [globalAyahNumber] - Global ayah number across entire Quran
  /// [bitrate] - Audio bitrate. If null, uses default from constants.
  static String buildVerseUrl(
    String cdnId,
    int globalAyahNumber, {
    int? bitrate,
  }) {
    final br = bitrate ?? AudioConstants.defaultBitrate;
    return '${AudioConstants.cdnBaseUrl}/${AudioConstants.verseAudioPath}/$br/$cdnId/$globalAyahNumber${AudioConstants.audioFileExtension}';
  }

  /// Select best available bitrate from a list
  /// Prefers 128, then 192, then highest available
  static int selectBestBitrate(List<int> availableBitrates) {
    if (availableBitrates.isEmpty) return AudioConstants.defaultBitrate;
    if (availableBitrates.contains(AudioConstants.defaultBitrate)) return AudioConstants.defaultBitrate;
    if (availableBitrates.contains(AudioConstants.highQualityBitrate)) return AudioConstants.highQualityBitrate;
    return availableBitrates.reduce((a, b) => a > b ? a : b);
  }
}


/// Audio system constants - centralized magic numbers and configuration
class AudioConstants {
  // Bitrates
  static const int defaultBitrate = 128;
  static const int highQualityBitrate = 192;
  static const int lowQualityBitrate = 64;
  static const int veryLowQualityBitrate = 32;
  static const int mediumQualityBitrate = 96;
  static const int persianBitrate = 40;
  static const int parhizgarBitrate = 48;

  // Quran structure
  static const int totalSurahs = 114;
  static const int firstSurah = 1;
  static const int lastSurah = 114;

  // Audio handler
  static const int positionUpdateIntervalMs = 200;

  // CDN URLs
  static const String cdnBaseUrl = 'https://cdn.islamic.network/quran';
  static const String surahAudioPath = 'audio-surah';
  static const String verseAudioPath = 'audio';

  // Default reciter
  static const String defaultReciter = 'ar.alafasy';

  // Playback speed limits
  static const double minPlaybackSpeed = 0.25;
  static const double maxPlaybackSpeed = 3.0;
  static const double defaultPlaybackSpeed = 1.0;

  // Volume limits
  static const double minVolume = 0.0;
  static const double maxVolume = 1.0;
  static const double defaultVolume = 1.0;

  // File extensions
  static const String audioFileExtension = '.mp3';

  // Error messages (Tajik)
  static const String errorReciterNotAvailable = 'Садои ин қорӣ дастрас нест. Лутфан қории дигарро интихоб кунед.';
  static const String errorNetworkConnection = 'Хатогии пайвастшавӣ. Лутфан пайвастшавии интернетро санҷед.';
  static const String errorPlaybackFailed = 'Хатогии пахши садо. Лутфан дубора кӯшиш кунед.';
  static const String errorVerseByVerseNotSupported = 'Қорӣ "%s" дархост кардани ояти ҷудогонаро дастгирӣ намекунад. Лутфан қории дигарро интихоб кунед ё сураи пурраро пахш кунед.';
}


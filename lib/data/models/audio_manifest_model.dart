import 'package:equatable/equatable.dart';

/// Represents an available audio reciter/translation with bitrate information
class AudioEdition extends Equatable {
  final String id; // CDN ID (e.g., 'ar.abdulbasitmurattal')
  final String? appId; // App ID if different (e.g., 'ar.abdul_basit_murattal')
  final String name; // Display name
  final String? nameTajik; // Tajik name
  final String? nameArabic; // Arabic name
  final String languageCode; // Language code (ar, fa, ru, en, etc.)
  final bool isTranslation; // True if translation, false if Arabic reciter
  final List<int> availableBitrates; // Available bitrates (e.g., [128, 192, 64])
  final String? flag; // Flag emoji for translations
  final bool hasVerseByVerse; // True if verse-by-verse audio is available

  const AudioEdition({
    required this.id,
    this.appId,
    required this.name,
    this.nameTajik,
    this.nameArabic,
    required this.languageCode,
    this.isTranslation = false,
    required this.availableBitrates,
    this.flag,
    this.hasVerseByVerse = false,
  });

  /// Get the best available bitrate (prefer default, then high quality, then highest)
  int get bestBitrate {
    // Import constants at top of file would be better, but avoiding circular imports
    const defaultBitrate = 128;
    const highQualityBitrate = 192;
    
    if (availableBitrates.contains(defaultBitrate)) return defaultBitrate;
    if (availableBitrates.contains(highQualityBitrate)) return highQualityBitrate;
    return availableBitrates.isNotEmpty ? availableBitrates.reduce((a, b) => a > b ? a : b) : defaultBitrate;
  }

  /// Get URL for surah audio
  /// Uses AudioUrlBuilder for consistency (imported where used)
  String getSurahUrl(int surahNumber, {int? bitrate}) {
    // Note: AudioUrlBuilder should be used directly instead of this method
    // Keeping for backward compatibility
    final br = bitrate ?? bestBitrate;
    return 'https://cdn.islamic.network/quran/audio-surah/$br/$id/$surahNumber.mp3';
  }

  /// Get URL for verse audio
  /// Uses AudioUrlBuilder for consistency (imported where used)
  String getVerseUrl(int globalAyahNumber, {int? bitrate}) {
    // Note: AudioUrlBuilder should be used directly instead of this method
    // Keeping for backward compatibility
    final br = bitrate ?? bestBitrate;
    return 'https://cdn.islamic.network/quran/audio/$br/$id/$globalAyahNumber.mp3';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'appId': appId,
        'name': name,
        'nameTajik': nameTajik,
        'nameArabic': nameArabic,
        'languageCode': languageCode,
        'isTranslation': isTranslation,
        'availableBitrates': availableBitrates,
        'flag': flag,
        'hasVerseByVerse': hasVerseByVerse,
      };

  factory AudioEdition.fromJson(Map<String, dynamic> json) => AudioEdition(
        id: json['id'] as String,
        appId: json['appId'] as String?,
        name: json['name'] as String,
        nameTajik: json['nameTajik'] as String?,
        nameArabic: json['nameArabic'] as String?,
        languageCode: json['languageCode'] as String,
        isTranslation: json['isTranslation'] as bool? ?? false,
        availableBitrates: (json['availableBitrates'] as List<dynamic>)
            .map((e) => e as int)
            .toList(),
        flag: json['flag'] as String?,
        hasVerseByVerse: json['hasVerseByVerse'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        appId,
        name,
        nameTajik,
        nameArabic,
        languageCode,
        isTranslation,
        availableBitrates,
        flag,
        hasVerseByVerse,
      ];
}

/// Complete manifest data containing all available audio editions
class AudioManifest extends Equatable {
  final List<AudioEdition> arabicReciters;
  final List<AudioEdition> translations;
  final DateTime lastUpdated;

  const AudioManifest({
    required this.arabicReciters,
    required this.translations,
    required this.lastUpdated,
  });

  /// Get all editions (reciters + translations)
  List<AudioEdition> get allEditions => [...arabicReciters, ...translations];

  /// Find edition by ID (CDN IDs only - no normalization)
  AudioEdition? findEdition(String id) {
    // Direct match only - all IDs are CDN IDs (no underscores)
    try {
      final edition = arabicReciters.firstWhere(
        (e) => e.id == id || e.appId == id,
        orElse: () => translations.firstWhere(
          (e) => e.id == id || e.appId == id,
          orElse: () => throw StateError('Not found'),
        ),
      );
      return edition;
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'arabicReciters': arabicReciters.map((e) => e.toJson()).toList(),
        'translations': translations.map((e) => e.toJson()).toList(),
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory AudioManifest.fromJson(Map<String, dynamic> json) => AudioManifest(
        arabicReciters: (json['arabicReciters'] as List<dynamic>)
            .map((e) => AudioEdition.fromJson(e as Map<String, dynamic>))
            .toList(),
        translations: (json['translations'] as List<dynamic>)
            .map((e) => AudioEdition.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );

  @override
  List<Object?> get props => [arabicReciters, translations, lastUpdated];
}


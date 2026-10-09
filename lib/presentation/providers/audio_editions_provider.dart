import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/reciter_model.dart';
import '../../data/models/audio_manifest_model.dart';
import '../../data/services/audio_manifest_service_v2.dart';
import '../../core/utils/reciter_id_mapper.dart';

// Translation audio edition model (moved here to avoid circular import)
class TranslationAudioEdition {
  final String id;
  final String name;
  final String flag;
  final String languageCode;

  const TranslationAudioEdition({
    required this.id,
    required this.name,
    required this.flag,
    required this.languageCode,
  });

  /// Create from AudioEdition
  factory TranslationAudioEdition.fromAudioEdition(AudioEdition edition) {
    return TranslationAudioEdition(
      id: edition.appId ?? edition.id,
      name: edition.name,
      flag: edition.flag ?? '',
      languageCode: edition.languageCode,
    );
  }
}

// Hardcoded list removed - now using ReciterDataService (loads from JSON)
// Reciter data in assets/data/reciters/full_surah_reciters.json

// Hardcoded list of translation audio editions
// Priority order: Tajik, Farsi, Russian, English, then others
const List<TranslationAudioEdition> _hardcodedTranslationEditions = [
  // Tajik (placeholder - will use separate API later)
  TranslationAudioEdition(
    id: 'tg.abuabdurrahman',
    name: 'Тоҷикӣ',
    flag: '🇹🇯',
    languageCode: 'tg',
  ),
  // Farsi
  TranslationAudioEdition(
    id: 'fa.ayati',
    name: 'Форсӣ',
    flag: '🇮🇷',
    languageCode: 'fa',
  ),
  // Russian
  TranslationAudioEdition(
    id: 'ru.kuliev-audio',
    name: 'Русский',
    flag: '🇷🇺',
    languageCode: 'ru',
  ),
  // English
  TranslationAudioEdition(
    id: 'en.ahmedali',
    name: 'Англисӣ',
    flag: '🇬🇧',
    languageCode: 'en',
  ),
  TranslationAudioEdition(
    id: 'en.ahmedraza',
    name: 'Англисӣ',
    flag: '🇬🇧',
    languageCode: 'en',
  ),
  // Urdu
  TranslationAudioEdition(
    id: 'ur.maududi',
    name: 'Урду',
    flag: '🇵🇰',
    languageCode: 'ur',
  ),
  // Turkish
  TranslationAudioEdition(
    id: 'tr.yuksel',
    name: 'Туркӣ',
    flag: '🇹🇷',
    languageCode: 'tr',
  ),
  // Indonesian
  TranslationAudioEdition(
    id: 'id.indonesian',
    name: 'Индонезӣ',
    flag: '🇮🇩',
    languageCode: 'id',
  ),
  // Malay
  TranslationAudioEdition(
    id: 'ms.basmeih',
    name: 'Малайӣ',
    flag: '🇲🇾',
    languageCode: 'ms',
  ),
  // Bengali
  TranslationAudioEdition(
    id: 'bn.bengali',
    name: 'Банголӣ',
    flag: '🇧🇩',
    languageCode: 'bn',
  ),
  // Hindi
  TranslationAudioEdition(
    id: 'hi.hindi',
    name: 'Ҳиндӣ',
    flag: '🇮🇳',
    languageCode: 'hi',
  ),
];

/// Convert AudioEdition to ReciterModel
/// The AudioEdition should already have proper names from _knownReciters in manifest parser
ReciterModel audioEditionToReciterModel(AudioEdition edition) {
  // The edition should already have proper names from _knownReciters
  // Just use the edition data directly
  return ReciterModel(
    id: edition.appId ?? edition.id,
    name: edition.name,
    nameTajik: edition.nameTajik ?? edition.name,
    nameArabic: edition.nameArabic ?? '',
  );
}

/// Convert AudioEdition to TranslationAudioEdition
TranslationAudioEdition audioEditionToTranslation(AudioEdition edition) {
  // Try to find matching hardcoded translation for metadata
  try {
    final hardcoded = _hardcodedTranslationEditions.firstWhere(
      (t) => t.id == edition.appId || t.id == edition.id,
    );
    
    // Use hardcoded metadata if found
    return TranslationAudioEdition(
      id: edition.appId ?? edition.id,
      name: hardcoded.name,
      flag: hardcoded.flag,
      languageCode: edition.languageCode,
    );
  } catch (e) {
    // No hardcoded match, use edition data
    return TranslationAudioEdition(
      id: edition.appId ?? edition.id,
      name: edition.name,
      flag: edition.flag ?? '',
      languageCode: edition.languageCode,
    );
  }
}

// Essential reciters for fallback (minimal list for first launch)
// These IDs are CDN IDs (no conversion needed)
const List<ReciterModel> _essentialReciters = [
  ReciterModel(
    id: 'ar.alafasy', // CDN ID: ar.alafasy (matches)
    name: 'Mishary Alafasy',
    nameTajik: 'Мишарӣ Ал-Афосӣ',
    nameArabic: 'مشاري العفاسي',
  ),
  ReciterModel(
    id: 'ar.husary', // CDN ID: ar.husary (matches)
    name: 'Mahmoud Khalil Al-Husary',
    nameTajik: 'Маҳмуд Халил Ал-Ҳусарӣ',
    nameArabic: 'محمود خليل الحصري',
  ),
  ReciterModel(
    id: 'ar.minshawi', // CDN ID: ar.minshawi (matches)
    name: 'Muhammad Siddiq Al-Minshawi',
    nameTajik: 'Муҳаммад Сиддиқ Ал-Миншавӣ',
    nameArabic: 'محمد صديق المنشاوي',
  ),
];

/// Verify essential reciter IDs are valid for CDN
/// Returns list with corrected IDs if needed
List<ReciterModel> _getVerifiedEssentialReciters() {
  // Essential reciters already use CDN IDs, no verification needed
  return _essentialReciters;
}

// Provider for Arabic reciters (loads from JSON via ReciterDataService)
// Returns ALL reciters (for verse-by-verse and other uses)
final apiRecitersProvider = FutureProvider<List<ReciterModel>>((ref) async {
  // Use ReciterDataService to load from JSON files
  final reciters = await AudioManifestServiceV2.getHardcodedReciters(forFullSurahOnly: false);
  debugPrint('[RecitersProvider] Loaded ${reciters.length} reciters from JSON (all bitrates)');
  return reciters;
});

// Provider for full surah reciters only (confirmed bitrates)
// Use this for full surah playback selection
final fullSurahRecitersProvider = FutureProvider<List<ReciterModel>>((ref) async {
  // Use ReciterDataService to load only confirmed reciters
  final reciters = await AudioManifestServiceV2.getHardcodedReciters(forFullSurahOnly: true);
  debugPrint('[FullSurahRecitersProvider] Loaded ${reciters.length} reciters with confirmed bitrates');
  return reciters;
});

// Essential translations for fallback
const List<TranslationAudioEdition> _essentialTranslations = [
  TranslationAudioEdition(
    id: 'fa.ayati',
    name: 'Форсӣ',
    flag: '🇮🇷',
    languageCode: 'fa',
  ),
  TranslationAudioEdition(
    id: 'ru.kuliev-audio',
    name: 'Русский',
    flag: '🇷🇺',
    languageCode: 'ru',
  ),
  TranslationAudioEdition(
    id: 'en.ahmedali',
    name: 'Англисӣ',
    flag: '🇬🇧',
    languageCode: 'en',
  ),
];

// Provider for translation audio editions (hardcoded, no network dependency)
// Excludes Tajik (handled separately via separate API)
// Returns ALL translations (for verse-by-verse and other uses)
final apiTranslationAudioEditionsProvider = Provider<List<TranslationAudioEdition>>((ref) {
  // Use hardcoded list directly (no manifest fetching)
  final translationsData = AudioManifestServiceV2.getHardcodedTranslationsData(forFullSurahOnly: false);
  final translations = translationsData.map((data) => TranslationAudioEdition(
    id: data['id']!,
    name: data['name']!,
    flag: data['flag']!,
    languageCode: data['languageCode']!,
  )).toList();
  debugPrint('[TranslationsProvider] Loaded ${translations.length} translations from hardcoded list (all)');
  return translations;
});

// Provider for full surah translations only (confirmed to have full surah support)
// Use this for full surah playback selection
final fullSurahTranslationsProvider = Provider<List<TranslationAudioEdition>>((ref) {
  // Filter to only translations with confirmed full surah support
  final translationsData = AudioManifestServiceV2.getHardcodedTranslationsData(forFullSurahOnly: true);
  final translations = translationsData.map((data) => TranslationAudioEdition(
    id: data['id']!,
    name: data['name']!,
    flag: data['flag']!,
    languageCode: data['languageCode']!,
  )).toList();
  debugPrint('[FullSurahTranslationsProvider] Loaded ${translations.length} translations with full surah support');
  return translations;
});



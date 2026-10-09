import 'dart:convert';
import 'package:flutter/foundation.dart' show compute, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/audio_manifest_model.dart';
import '../models/reciter_model.dart';
import '../../core/utils/manifest_parser.dart';
import '../../core/constants/audio_constants.dart';
import 'reciter_data_service.dart';

/// Service to fetch, parse, and cache audio manifests from CDN
/// Uses isolates for background parsing to prevent UI freeze
class AudioManifestServiceV2 {
  static const String _cacheKey = 'audio_manifest_cache_v6'; // Versioned cache (includes hasVerseByVerse field)
  static const String _cacheTimestampKey = 'audio_manifest_cache_timestamp';
  static const String _surahManifestUrl =
      'https://cdn.islamic.network/quran/info/by-surah/info.json';
  static const String _ayahManifestUrl =
      'https://cdn.islamic.network/quran/info/by-ayah/info.txt';
  static const Duration _cacheValidDuration = Duration(days: 1); // Reduced from 7 days for faster updates

  // REMOVED: _knownReciters map (1100+ lines) - all reciter data now loaded from JSON via ReciterDataService
  // Data in assets/data/reciters/full_surah_reciters.json
  static const Map<String, Map<String, String>> _knownReciters = {};

  static const Map<String, Map<String, String>> _knownTranslations = {
    // Confirmed full surah translations from CDN manifest
    'en.misharyrashidalafasyenglishtranslationsaheehibrahimwalk': {
      'name': 'Англисӣ (Мишарӣ Ал-Афосӣ)',
      'flag': '🇬🇧',
    },
    'en.muhammadayyubenglishtranslationmuhsinkhanmikaalwaters': {
      'name': 'Англисӣ (Муҳаммад Айюб)',
      'flag': '🇬🇧',
    },
    'en.sudaisandshuraymenglishtranslationpickthallaslamathar': {
      'name': 'Англисӣ (Судайс ва Шурайм)',
      'flag': '🇬🇧',
    },
    'ru.kuliev-audio': {
      'name': 'Русский',
      'flag': '🇷🇺',
    },
    'en.walk': {
      'name': 'Англисӣ',
      'flag': '🇬🇧',
    },
    'fa.hedayatfarfooladvand': {
      'name': 'Форсӣ',
      'flag': '🇮🇷',
    },
    'ur.khan': {
      'name': 'Урду',
      'flag': '🇵🇰',
    },
    'fr.leclerc': {
      'name': 'Французӣ',
      'flag': '🇫🇷',
    },
    'zh.chinese': {
      'name': 'Чинӣ',
      'flag': '🇨🇳',
    },
    // Other translations (may be verse-by-verse only)
    'fa.ayati': {
      'name': 'Форсӣ',
      'flag': '🇮🇷',
    },
    'en.ahmedali': {
      'name': 'Англисӣ',
      'flag': '🇬🇧',
    },
    'en.ahmedraza': {
      'name': 'Англисӣ',
      'flag': '🇬🇧',
    },
    'ur.maududi': {
      'name': 'Урду',
      'flag': '🇵🇰',
    },
    'tr.yuksel': {
      'name': 'Туркӣ',
      'flag': '🇹🇷',
    },
    'id.indonesian': {
      'name': 'Индонезӣ',
      'flag': '🇮🇩',
    },
    'ms.basmeih': {
      'name': 'Малайӣ',
      'flag': '🇲🇾',
    },
    'bn.bengali': {
      'name': 'Банголӣ',
      'flag': '🇧🇩',
    },
    'hi.hindi': {
      'name': 'Ҳиндӣ',
      'flag': '🇮🇳',
    },
  };

  /// Get hardcoded reciters list (no network dependency)
  /// Uses ReciterDataService to load from JSON files
  /// [forFullSurahOnly] - if true, only returns reciters with confirmed bitrates for full surah playback
  static Future<List<ReciterModel>> getHardcodedReciters({bool forFullSurahOnly = false}) async {
    final service = ReciterDataService.instance;
    return await service.getFullSurahReciters(confirmedOnly: forFullSurahOnly);
  }

  /// Whitelist of reciters CONFIRMED to have 128 kbps on CDN for full surah playback
  /// Generated from: https://cdn.islamic.network/quran/info/by-surah/info.json
  /// Only includes reciters that are CONFIRMED to exist in the CDN manifest
  /// Total: 158 reciters at 128 kbps (as of manifest parsing)
  static const Set<String> _confirmed128KbpsReciters = {
    'ar.abdulazizazzahrani',
    'ar.abdulbariaththubaity',
    'ar.abdulbarimohammed',
    'ar.abdulbasitmujawwad',
    'ar.abdulbasitmurattal',
    'ar.abdulkareemalhazmi',
    'ar.abdullahalmatrood',
    'ar.abdullahawadaljuhani',
    'ar.abdullahbasfar',
    'ar.abdullahkhayat',
    'ar.abdullahkhulaifi',
    'ar.abdulmohsenalharthy',
    'ar.abdulmuhsinalqasim',
    'ar.abdulmunimabdulmubdi',
    'ar.abdulwadoodhaneef',
    'ar.abdurrasheedsufiabialhaarithanalkasaaee',
    'ar.abdurrasheedsufiaddoorianabiamr',
    'ar.abdurrasheedsufishubahanasim',
    'ar.abdurrasheedsufisoosi',
    'ar.abdurrazaqbinabtanaldulaimi',
    'ar.abuabdullahmuniraltounsi',
    'ar.abubakraldhabi',
    'ar.adilkalbani',
    'ar.ahmadalhawashy',
    'ar.ahmadalnufais',
    'ar.ahmadkhaderaltarabulsi',
    'ar.ahmadsulaiman',
    'ar.ahmedalajmi',
    'ar.ahmedalhammad',
    'ar.ahmedalmisbahi',
    'ar.ahmedamir',
    'ar.ahmedmohamedsalama',
    'ar.ahmedsaber',
    'ar.alafasy',
    'ar.alashryomran',
    'ar.alfatehmuhammadzubair',
    'ar.alhusaynialazazi',
    'ar.alhusaynialazazichildren',
    'ar.aliabdurrahmanalhuthaify',
    'ar.aliabdurrahmanalhuthaifyqaloon',
    'ar.alihajjajsouissi',
    'ar.alzainmohamedahmed',
    'ar.aymanswed',
    'ar.azizalili',
    'ar.bandarbalila',
    'ar.basselabdulrahmanraoui',
    'ar.benkirane',
    'ar.darwishfarajdarwishalattar',
    'ar.eidhassanabuaachra',
    'ar.emadalmansary',
    'ar.ezzatsabri',
    'ar.faresabbad',
    'ar.fouadalkhamiri',
    'ar.hamadsinan',
    'ar.hamdyalsayedtolbasaad',
    'ar.haniarrifai',
    'ar.hasanhashem',
    'ar.hassansaleh',
    'ar.hatemfarid',
    'ar.ibrahimalakhdar',
    'ar.ibrahimaldossari',
    'ar.ibrahimaljormy',
    'ar.ilhantok',
    'ar.imadzuhairhafez',
    'ar.jaberabdulhameed',
    'ar.jamaanalosaimi',
    'ar.jamalshakerabdullah',
    'ar.jazzaalswaileh',
    'ar.kamel',
    'ar.karimmansouri',
    'ar.khaledalqahtani',
    'ar.khaledbarakat',
    'ar.khalidabdulkafi',
    'ar.khalidaljalil',
    'ar.khalidalmohanna',
    'ar.khalifaaltunaiji',
    'ar.laayounelkouchi',
    'ar.lesaintcorantraduitenfrancais',
    'ar.mahershakhashiro',
    'ar.mahmoodalrifai',
    'ar.mahmoudalialbanna',
    'ar.mahmoudelsheimy',
    'ar.mahmoudsaaddarouich',
    'ar.mahmoudsayedeltayeb',
    'ar.moeedhalharthi',
    'ar.mohamedabdelaziz',
    'ar.mohamedabdelhakimsaadalabdullah',
    'ar.mohamedaljaberyalheyani',
    'ar.mohamedalmohisni',
    'ar.mohamedelkantaoui',
    'ar.mohamedhassan',
    'ar.mohamedmaabad',
    'ar.mohamedosmankhan',
    'ar.mohamedshaabanabuqarn',
    'ar.mohamedtablawi',
    'ar.mohammadismaeelalmuqaddim',
    'ar.mohammadrachadalshareef',
    'ar.mohammedbinsalehabuzaid',
    'ar.muftahalsaltany',
    'ar.muhammadabdulkareem',
    'ar.muhammadalaalimaldokali',
    'ar.muhammadalluhaidan',
    'ar.muhammadalmehysni',
    'ar.muhammadalsubayyil',
    'ar.muhammadanwarshahat',
    'ar.muhammadayyub',
    'ar.muhammadsalehalimshah',
    'ar.muhammadsiddiqalminshawimujawwad',
    'ar.muhammadsulaimanpatel',
    'ar.musabilal',
    'ar.mustafaallahouni',
    'ar.mustafaismail',
    'ar.mustafaraadalazzawi',
    'ar.mustaphagharbi',
    'ar.nabilarrifai',
    'ar.nasseralqatami',
    'ar.neamahalhassan',
    'ar.obeikan',
    'ar.oimaoqataris',
    'ar.omaralkazabri',
    'ar.osamabinalialghanim',
    'ar.rachidbelalia',
    'ar.saberabdulhakam',
    'ar.sadaqatali',
    'ar.sahlyasin',
    'ar.saidalshaalan',
    'ar.salahalbudair',
    'ar.salahalhashem',
    'ar.salahbaothman',
    'ar.samirbelaachya',
    'ar.saudalshuraim',
    'ar.sayedramadan',
    'ar.shahriarparhizgar',
    'ar.sudaisshuraymnaeemsultan',
    'ar.tamerislam',
    'ar.tareqabdulganidaawob',
    'ar.tawfeeqassayegh',
    'ar.turkiebeidalmarri',
    'ar.waeldesouky',
    'ar.waelradwanqureshi',
    'ar.waleedidreesalmaneese',
    'ar.waleednaehi',
    'ar.waleedsamiraliabdulmajidsorour',
    'ar.walidalshatti',
    'ar.walidfathibashta',
    'ar.yahyahawwa',
    'ar.yassenaljazairi',
    'ar.yasseraldossari',
    'ar.yasseralmazroyee',
    'ar.yasserqureshi',
    'ar.yassersalama',
    'ar.yassersarhaneldeeb',
    'ar.yousufalshoaey',
    'ar.yousufbinnoahahmad',
    'en.misharyrashidalafasyenglishtranslationsaheehibrahimwalk',
    'en.muhammadayyubenglishtranslationmuhsinkhanmikaalwaters',
    'en.sudaisandshuraymenglishtranslationpickthallaslamathar',
  };

  /// Get bitrate for full surah playback for a given CDN reciter ID
  /// Returns the bitrate (128, 192, 64, 32, etc.) or null if not confirmed
  /// This is hardcoded to avoid network dependency
  /// Returns null for reciters not in the bitrate map (don't assume 128)
  static int? getSurahBitrate(String cdnId) {
    // Hardcoded bitrate map for full surah playback
    // Only includes reciters with CONFIRMED non-default bitrates from CDN manifest
    // Generated from: https://cdn.islamic.network/quran/info/by-surah/info.json
    final bitrateMap = <String, int>{
      // 96 kbps
      'my.hashimtinmyint': AudioConstants.mediumQualityBitrate,
      // Note: Translations are NOT in the full surah manifest - they are verse-by-verse only
      // Translation bitrates (en.walk, ur.khan, etc.) are only for verse-by-verse playback
      // Most reciters are at default bitrate (128) and are in _confirmed128KbpsReciters
    };
    
    // Check if in bitrate map first
    if (bitrateMap.containsKey(cdnId)) {
      return bitrateMap[cdnId];
    }
    
    // Check if translation is confirmed to have full surah support (default to 128 kbps)
    if (_confirmedFullSurahTranslations.contains(cdnId)) {
      return AudioConstants.defaultBitrate;
    }
    
    // Only return default bitrate if confirmed in whitelist (Arabic reciters)
    if (_confirmed128KbpsReciters.contains(cdnId)) {
      return AudioConstants.defaultBitrate;
    }
    
    // Return null for unconfirmed reciters (don't assume 128)
    return null;
  }
  
  /// Check if a reciter has a CONFIRMED bitrate (any bitrate: 128, 192, 64, 32)
  /// Returns true if the reciter is in the bitrateMap OR in the 128 kbps whitelist
  static bool hasConfirmedBitrate(String cdnId) {
    return getSurahBitrate(cdnId) != null;
  }
  
  /// Check if a reciter is confirmed to have default bitrate (128 kbps) for full surah playback
  /// (Kept for backward compatibility, but use hasConfirmedBitrate for filtering)
  static bool hasConfirmed128Kbps(String cdnId) {
    return getSurahBitrate(cdnId) == AudioConstants.defaultBitrate;
  }

  // ============================================================================
  // VERSE-BY-VERSE AUDIO (Centralized hardcoded lists)
  // ============================================================================
  
  /// Hardcoded list of reciter IDs that support verse-by-verse audio
  /// Based on verified URLs from https://cdn.islamic.network/quran/info/by-ayah/info.txt
  /// These are CDN IDs (without underscores)
  static const Set<String> verseByVerseReciterIds = {
    // 128 kbps
    'ar.ahmedajamy',
    'ar.alafasy',
    'ar.hudhaify',
    'ar.husary',
    'ar.husarymujawwad',
    'ar.mahermuaiqly',
    'ar.minshawi',
    'ar.muhammadayyoub',
    'ar.muhammadjibreel',
    'ar.shaatree',
    // 192 kbps
    'ar.abdulbasitmurattal',
    'ar.abdullahbasfar',
    'ar.abdurrahmaansudais',
    'ar.hanirifai',
    // 32 kbps
    'ar.ibrahimakhbar',
    // 64 kbps
    'ar.abdulsamad',
    'ar.aymanswoaid',
    'ar.minshawimujawwad',
    'ar.saoodshuraym',
    // Translations with verse-by-verse
    'fr.leclerc',
    'ru.kuliev-audio',
    'zh.chinese',
    'en.walk',
    'fa.hedayatfarfooladvand',
    'ur.khan',
  };

  /// Get the appropriate bitrate for verse-by-verse audio for a given CDN reciter ID
  /// Uses hardcoded map (can be migrated to ReciterDataService when JSON is fully populated)
  static int getVerseByVerseBitrate(String cdnId) {
    final bitrateMap = {
      // 192 kbps
      'ar.abdulbasitmurattal': AudioConstants.highQualityBitrate,
      'ar.abdullahbasfar': AudioConstants.highQualityBitrate,
      'ar.abdurrahmaansudais': AudioConstants.highQualityBitrate,
      'ar.hanirifai': AudioConstants.highQualityBitrate,
      'en.walk': AudioConstants.highQualityBitrate,
      // 64 kbps
      'ar.abdulsamad': AudioConstants.lowQualityBitrate,
      'ar.aymanswoaid': AudioConstants.lowQualityBitrate,
      'ar.minshawimujawwad': AudioConstants.lowQualityBitrate,
      'ar.saoodshuraym': AudioConstants.lowQualityBitrate,
      'ur.khan': AudioConstants.lowQualityBitrate,
      // 32 kbps
      'ar.ibrahimakhbar': AudioConstants.veryLowQualityBitrate,
      // 40 kbps
      'fa.hedayatfarfooladvand': AudioConstants.persianBitrate,
    };
    
    return bitrateMap[cdnId] ?? AudioConstants.defaultBitrate;
  }

  /// Check if an edition supports verse-by-verse audio
  /// Uses hardcoded list (can be migrated to ReciterDataService when JSON is fully populated)
  static bool supportsVerseByVerse(String cdnId) {
    // Direct match - all IDs are CDN IDs (no underscores)
    return verseByVerseReciterIds.any((verseId) => verseId.toLowerCase() == cdnId.toLowerCase());
  }

  /// Whitelist of translations CONFIRMED to have full surah support
  /// Based on actual CDN manifest check: https://cdn.islamic.network/quran/info/by-surah/info.json
  /// These translations were found in the full surah manifest directory structure
  static const Set<String> _confirmedFullSurahTranslations = {
    'en.misharyrashidalafasyenglishtranslationsaheehibrahimwalk', // English - Mishary Alafasy translation
    'en.muhammadayyubenglishtranslationmuhsinkhanmikaalwaters', // English - Muhammad Ayyub translation
    'en.sudaisandshuraymenglishtranslationpickthallaslamathar', // English - Sudais & Shuraym translation
  };

  /// Get hardcoded translations data (no network dependency)
  /// [forFullSurahOnly] - if true, only returns translations with confirmed full surah support
  /// Returns map of translation data that can be converted to TranslationAudioEdition
  static List<Map<String, String>> getHardcodedTranslationsData({bool forFullSurahOnly = false}) {
    final translations = <Map<String, String>>[];
    for (final entry in _knownTranslations.entries) {
      final cdnId = entry.key;
      final metadata = entry.value;
      
      // If filtering for full surah only, check if translation is confirmed
      if (forFullSurahOnly) {
        if (!_confirmedFullSurahTranslations.contains(cdnId)) {
          continue; // Skip translations not confirmed to have full surah support
        }
      }
      
      final languageCode = cdnId.split('.').first;
      translations.add({
        'id': cdnId, // Use CDN ID directly
        'name': metadata['name'] ?? cdnId,
        'flag': metadata['flag'] ?? '',
        'languageCode': languageCode,
      });
    }
    translations.sort((a, b) => a['name']!.compareTo(b['name']!));
    return translations;
  }

  /// Fetch and parse manifests, return cached if available and valid
  /// Uses background parsing to prevent UI freeze
  /// Supports background refresh for stale cache
  Future<AudioManifest> getManifest({
    bool forceRefresh = false,
    Function(String)? onProgress,
    bool backgroundRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = await _getCachedManifest();
      if (cached != null) {
        final age = DateTime.now().difference(cached.lastUpdated);
        if (age < _cacheValidDuration) {
          debugPrint('[Manifest] Using cached manifest (age: ${age.inHours}h)');
          
          // Background refresh if cache is older than 12 hours but still valid
          if (backgroundRefresh && age > const Duration(hours: 12)) {
            debugPrint('[Manifest] Cache is stale (${age.inHours}h), refreshing in background...');
            // Refresh in background without blocking
            _refreshManifestInBackground();
          }
          
          return cached;
        }
        debugPrint('[Manifest] Cache expired (age: ${age.inHours}h), fetching fresh data');
      }
    }

    // Fetch fresh data
    onProgress?.call('Fetching manifests...');
    debugPrint('[Manifest] Fetching fresh manifest data...');
    
    try {
      final manifest = await _fetchAndParseManifests(onProgress: onProgress);
      await _cacheManifest(manifest);
      debugPrint('[Manifest] Successfully loaded ${manifest.arabicReciters.length} reciters and ${manifest.translations.length} translations');
      return manifest;
    } catch (e) {
      debugPrint('[Manifest] Error fetching manifest: $e');
      // Return expired cache if available
      final cached = await _getCachedManifest();
      if (cached != null) {
        debugPrint('[Manifest] Returning expired cache due to error');
        return cached;
      }
      rethrow;
    }
  }

  /// Fetch and parse both manifests using background isolates
  Future<AudioManifest> _fetchAndParseManifests({
    Function(String)? onProgress,
  }) async {
    try {
      // Fetch both manifests in parallel
      onProgress?.call('Downloading manifests...');
      final responses = await Future.wait([
        http.get(Uri.parse(_surahManifestUrl)),
        http.get(Uri.parse(_ayahManifestUrl)),
      ]);

      if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
        final surahStatus = responses[0].statusCode;
        final ayahStatus = responses[1].statusCode;
        throw Exception(
            'Failed to fetch manifests: surah=$surahStatus, ayah=$ayahStatus');
      }

      // Parse in background isolate to prevent UI freeze
      onProgress?.call('Parsing manifests...');
      // The JSON response is a List, not a Map
      final surahDataRaw = json.decode(responses[0].body);
      final ayahText = responses[1].body;

      // Parse in isolate (pass as serializable data)
      final parsedData = await compute(_parseManifestsInIsolate, {
        'surahData': surahDataRaw, // Pass raw data, let parser handle it
        'ayahText': ayahText,
        'knownReciters': Map<String, Map<String, String>>.from(_knownReciters),
        'knownTranslations': Map<String, Map<String, String>>.from(_knownTranslations),
      });

      final (arabicReciters, translations) = parsedData;

      debugPrint(
          '[Manifest] Parsed ${arabicReciters.length} reciters, ${translations.length} translations');
      
      // Debug: List all reciter IDs
      if (arabicReciters.isNotEmpty) {
        debugPrint('[Manifest] Reciter IDs: ${arabicReciters.map((e) => e.id).join(", ")}');
      }
      
      // Debug: List all translation IDs
      if (translations.isNotEmpty) {
        debugPrint('[Manifest] Translation IDs: ${translations.map((e) => e.id).join(", ")}');
      }

      return AudioManifest(
        arabicReciters: arabicReciters,
        translations: translations,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('[Manifest] Error parsing manifests: $e');
      debugPrint('[Manifest] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get cached manifest
  Future<AudioManifest?> _getCachedManifest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return AudioManifest.fromJson(jsonData);
    } catch (e) {
      debugPrint('[Manifest] Error reading cache: $e');
      return null;
    }
  }

  /// Cache manifest with size management
  Future<void> _cacheManifest(AudioManifest manifest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(manifest.toJson());
      
      // Check cache size (SharedPreferences has ~1MB limit per key)
      final sizeInBytes = jsonString.length;
      final sizeInKB = sizeInBytes / 1024;
      
      if (sizeInKB > 900) { // Warn if approaching limit
        debugPrint('[Manifest] Warning: Cache size is ${sizeInKB.toStringAsFixed(2)}KB (approaching 1MB limit)');
      }
      
      // Clean up old cache versions before saving new one
      await _cleanupOldCacheVersions(prefs);
      
      await prefs.setString(_cacheKey, jsonString);
      await prefs.setString(_cacheTimestampKey, DateTime.now().toIso8601String());
      debugPrint('[Manifest] Cached manifest successfully (${sizeInKB.toStringAsFixed(2)}KB)');
    } catch (e) {
      debugPrint('[Manifest] Error caching manifest: $e');
    }
  }

  /// Clean up old cache versions to prevent storage bloat
  Future<void> _cleanupOldCacheVersions(SharedPreferences prefs) async {
    try {
      // Remove old cache versions (v1, v2, v3, v4, v5)
      final oldKeys = [
        'audio_manifest_cache_v1',
        'audio_manifest_cache_v2',
        'audio_manifest_cache_v3',
        'audio_manifest_cache_v4',
        'audio_manifest_cache_v5',
      ];
      for (final key in oldKeys) {
        if (prefs.containsKey(key)) {
          await prefs.remove(key);
          final timestampKey = key.contains('_v') 
              ? '${key.split('_v')[0]}_cache_${key.split('_v')[1]}_timestamp'
              : '${key}_timestamp';
          if (prefs.containsKey(timestampKey)) {
            await prefs.remove(timestampKey);
          }
          debugPrint('[Manifest] Cleaned up old cache version: $key');
        }
      }
    } catch (e) {
      debugPrint('[Manifest] Error cleaning up old cache: $e');
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
    debugPrint('[Manifest] Cache cleared');
  }

  /// Check if cache exists and is valid
  Future<bool> hasValidCache() async {
    final cached = await _getCachedManifest();
    if (cached == null) return false;
    final age = DateTime.now().difference(cached.lastUpdated);
    return age < _cacheValidDuration;
  }

  /// Refresh manifest in background without blocking
  /// Includes retry logic with exponential backoff
  Future<void> _refreshManifestInBackground() async {
    const maxRetries = 3;
    const initialDelay = Duration(seconds: 2);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final manifest = await _fetchAndParseManifests()
            .timeout(const Duration(seconds: 30));
        await _cacheManifest(manifest);
        debugPrint('[Manifest] Background refresh completed successfully (attempt ${attempt + 1})');
        return; // Success, exit retry loop
      } catch (e) {
        final isLastAttempt = attempt == maxRetries - 1;
        if (isLastAttempt) {
          debugPrint('[Manifest] Background refresh failed after $maxRetries attempts: $e (using existing cache)');
          return; // Give up after max retries
        }
        
        // Exponential backoff: 2s, 4s, 8s
        final delay = Duration(milliseconds: initialDelay.inMilliseconds * (1 << attempt));
        debugPrint('[Manifest] Background refresh attempt ${attempt + 1} failed: $e, retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }
  }
}

/// Parse manifests in isolate (top-level function for compute)
(List<AudioEdition>, List<AudioEdition>) _parseManifestsInIsolate(
  Map<String, dynamic> data,
) {
  final surahData = data['surahData']; // Can be List or Map
  final ayahText = data['ayahText'] as String;
  final knownReciters = data['knownReciters'] as Map<String, Map<String, String>>;
  final knownTranslations = data['knownTranslations'] as Map<String, Map<String, String>>;

  // Parse both manifests separately
  final surahEditions = ManifestParser.parseSurahManifest(surahData);
  final ayahEditions = ManifestParser.parseAyahManifest(ayahText);
  
  // Build AudioEdition objects (pass both separately to track verse-by-verse availability)
  return ManifestParser.buildEditions(
    surahEditions,
    ayahEditions,
    knownReciters,
    knownTranslations,
  );
}


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/audio_manifest_model.dart';

/// Service to fetch, parse, and cache audio manifests from CDN
/// 
/// @deprecated Use AudioManifestServiceV2 instead for background parsing support.
/// This service is kept for backward compatibility but does not use isolates.
class AudioManifestService {
  static const String _cacheKey = 'audio_manifest_cache';
  static const String _surahManifestUrl =
      'https://cdn.islamic.network/quran/info/by-surah/info.json';
  static const String _ayahManifestUrl =
      'https://cdn.islamic.network/quran/info/by-ayah/info.txt';
  static const Duration _cacheValidDuration = Duration(days: 7);

  /// Known app IDs with their display names
  static const Map<String, Map<String, String>> _knownReciters = {
    'ar.alafasy': {
      'name': 'Mishary Alafasy',
      'nameTajik': 'Мишарӣ Ал-Афосӣ',
      'nameArabic': 'مشاري العفاسي',
    },
    'ar.husary': {
      'name': 'Mahmoud Khalil Al-Husary',
      'nameTajik': 'Маҳмуд Халил Ал-Ҳусарӣ',
      'nameArabic': 'محمود خليل الحصري',
    },
    'ar.minshawi': {
      'name': 'Muhammad Siddiq Al-Minshawi',
      'nameTajik': 'Муҳаммад Сиддиқ Ал-Миншавӣ',
      'nameArabic': 'محمد صديق المنشاوي',
    },
    'ar.abdulbasitmurattal': {
      'appId': 'ar.abdul_basit_murattal',
      'name': 'Abdul Basit Murattal',
      'nameTajik': 'Абдул Босити Мураттал',
      'nameArabic': 'عبد الباسط مرتل',
    },
    'ar.abdulbasitmujawwad': {
      'appId': 'ar.abdul_basit_mujawwad',
      'name': 'Abdul Basit Mujawwad',
      'nameTajik': 'Абдул Босити Муҷаввад',
      'nameArabic': 'عبد الباسط مجود',
    },
    'ar.abdullahbasfar': {
      'appId': 'ar.abdullah_basfar',
      'name': 'Abdullah Basfar',
      'nameTajik': 'Абдуллоҳ Басфар',
      'nameArabic': 'عبد الله بصفر',
    },
    'ar.abdurrahmaansudais': {
      'appId': 'ar.abdurrahmaan_as_sudais',
      'name': 'Abdur-Rahman As-Sudais',
      'nameTajik': 'Абдур Раҳмон Ас-Судайс',
      'nameArabic': 'عبد الرحمن السديس',
    },
    'ar.ahmedalajmi': {
      'appId': 'ar.ahmed_ajamy',
      'name': 'Ahmed Al-Ajamy',
      'nameTajik': 'Аҳмад Ал-Аҷамӣ',
      'nameArabic': 'أحمد العجمي',
    },
    'ar.mahermuaiqly': {
      'appId': 'ar.maher_al_muaiqly',
      'name': 'Maher Al Muaiqly',
      'nameTajik': 'Маҳер Ал-Муайқлӣ',
      'nameArabic': 'ماهر المعيقلي',
    },
    'ar.saadghamdi': {
      'appId': 'ar.saad_al_ghamdi',
      'name': 'Saad Al-Ghamdi',
      'nameTajik': 'Саъд Ал-Ғамдӣ',
      'nameArabic': 'سعد الغامدي',
    },
    'ar.shaatree': {
      'appId': 'ar.abu_bakr_ash_shaatree',
      'name': 'Abu Bakr Ash-Shatri',
      'nameTajik': 'Абӯ Бакр Аш-Шатри',
      'nameArabic': 'أبو بكر الشاطري',
    },
    'ar.abdulwadoodhaneef': {
      'appId': 'ar.abdul_wadood_haneef',
      'name': 'Abdul Wadood Haneef',
      'nameTajik': 'Абдул Вадуд Ҳаниф',
      'nameArabic': 'عبد الودود حنيف',
    },
    'ar.abdurrasheedsufisoosi': {
      'appId': 'ar.abdurrashid_sufi',
      'name': 'Abdur-Rashid Sufi',
      'nameTajik': 'Абдур Рашид Суфӣ',
      'nameArabic': 'عبد الرشيد صوفي',
    },
    'ar.abdulsamad': {
      'appId': 'ar.abdul_samad',
      'name': 'Abdul Samad',
      'nameTajik': 'Абдул Самад',
      'nameArabic': 'عبد الصمد',
    },
  };

  static const Map<String, Map<String, String>> _knownTranslations = {
    'fa.ayati': {
      'name': 'Форсӣ',
      'flag': '🇮🇷',
    },
    'ru.kuliev-audio': {
      'appId': 'ru.kuliev',
      'name': 'Русский',
      'flag': '🇷🇺',
    },
    'en.ahmedali': {
      'name': 'English',
      'flag': '🇬🇧',
    },
    'en.ahmedraza': {
      'name': 'English',
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

  /// Fetch and parse manifests, return cached if available and valid
  Future<AudioManifest> getManifest({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = await _getCachedManifest();
      if (cached != null) {
        final age = DateTime.now().difference(cached.lastUpdated);
        if (age < _cacheValidDuration) {
          debugPrint('[Manifest] Using cached manifest (age: ${age.inHours}h)');
          return cached;
        }
      }
    }

    // Fetch fresh data
    debugPrint('[Manifest] Fetching fresh manifest data...');
    final manifest = await _fetchAndParseManifests();
    await _cacheManifest(manifest);
    return manifest;
  }

  /// Check if edition ID is valid (starts with known language prefix)
  bool _isValidEditionId(String editionId) {
    return editionId.startsWith('ar.') ||
        editionId.startsWith('fa.') ||
        editionId.startsWith('ru.') ||
        editionId.startsWith('en.') ||
        editionId.startsWith('ur.') ||
        editionId.startsWith('tr.') ||
        editionId.startsWith('id.') ||
        editionId.startsWith('ms.') ||
        editionId.startsWith('bn.') ||
        editionId.startsWith('hi.');
  }

  /// Build AudioEdition objects from parsed data
  (List<AudioEdition>, List<AudioEdition>) _buildEditions(Map<String, Set<int>> editions) {
    final arabicReciters = <AudioEdition>[];
    final translations = <AudioEdition>[];

    for (final entry in editions.entries) {
      final editionId = entry.key;
      final bitrates = entry.value.toList()..sort();

      final isArabic = editionId.startsWith('ar.');
      final languageCode = editionId.split('.').first;

      // Get known metadata
      final metadata = isArabic
          ? _knownReciters[editionId]
          : _knownTranslations[editionId];

      final edition = AudioEdition(
        id: editionId,
        appId: metadata?['appId'],
        name: metadata?['name'] ?? _formatEditionName(editionId),
        nameTajik: metadata?['nameTajik'],
        nameArabic: metadata?['nameArabic'],
        languageCode: languageCode,
        isTranslation: !isArabic,
        availableBitrates: bitrates,
        flag: metadata?['flag'],
      );

      if (isArabic) {
        arabicReciters.add(edition);
      } else {
        translations.add(edition);
      }
    }

    // Sort reciters by name
    arabicReciters.sort((a, b) => a.name.compareTo(b.name));
    translations.sort((a, b) => a.name.compareTo(b.name));

    return (arabicReciters, translations);
  }

  /// Fetch and parse both manifests
  Future<AudioManifest> _fetchAndParseManifests() async {
    try {
      // Fetch both manifests in parallel
      final responses = await Future.wait([
        http.get(Uri.parse(_surahManifestUrl)),
        http.get(Uri.parse(_ayahManifestUrl)),
      ]);

      if (responses[0].statusCode != 200 || responses[1].statusCode != 200) {
        throw Exception(
            'Failed to fetch manifests: ${responses[0].statusCode}, ${responses[1].statusCode}');
      }

      // Parse JSON manifest (by-surah)
      final surahData = json.decode(responses[0].body) as List<dynamic>;
      final surahManifest = surahData.firstWhere(
        (item) => item['type'] == 'directory' &&
            item['name'] == '/mnt/cdn/islamic-network-cdn/quran/audio-surah',
      );

      // Parse text manifest (by-ayah)
      final ayahText = responses[1].body;

      // Extract editions from both manifests
      // Map: editionId -> Set of available bitrates
      final editions = <String, Set<int>>{};

      // Parse surah manifest (JSON)
      final surahContents = surahManifest['contents'] as List<dynamic>;
      for (final bitrateDir in surahContents) {
        if (bitrateDir['type'] != 'directory') continue;
        final bitrateStr = bitrateDir['name'] as String;
        final bitrate = int.tryParse(bitrateStr);
        if (bitrate == null) continue;

        final editionDirs = bitrateDir['contents'] as List<dynamic>?;
        if (editionDirs == null) continue;

        for (final editionDir in editionDirs) {
          if (editionDir['type'] != 'directory') continue;
          final editionId = editionDir['name'] as String;
          
          // Only process known language prefixes
          if (!_isValidEditionId(editionId)) continue;

          editions.putIfAbsent(editionId, () => <int>{});
          editions[editionId]!.add(bitrate);
        }
      }

      // Parse ayah manifest (text) to get additional bitrates
      final ayahLines = ayahText.split('\n');
      int? currentBitrate;
      for (final line in ayahLines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        // Check if line starts with a number (bitrate)
        final bitrateMatch = RegExp(r'^\s*(\d+)\s+').firstMatch(trimmed);
        if (bitrateMatch != null) {
          currentBitrate = int.tryParse(bitrateMatch.group(1)!);
          continue;
        }

        // Look for edition IDs in the line
        final editionMatch = RegExp(r'\b([a-z]{2}\.[a-z0-9_-]+)\b').firstMatch(trimmed);
        if (editionMatch != null && currentBitrate != null) {
          final editionId = editionMatch.group(1)!;
          if (_isValidEditionId(editionId)) {
            editions.putIfAbsent(editionId, () => <int>{});
            editions[editionId]!.add(currentBitrate);
          }
        }
      }

      // Build AudioEdition objects
      final (arabicReciters, translations) = _buildEditions(editions);

      debugPrint(
          '[Manifest] Parsed ${arabicReciters.length} reciters, ${translations.length} translations');

      return AudioManifest(
        arabicReciters: arabicReciters,
        translations: translations,
        lastUpdated: DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('[Manifest] Error parsing manifests: $e');
      debugPrint('[Manifest] Stack trace: $stackTrace');
      // Return cached if available, even if expired
      final cached = await _getCachedManifest();
      if (cached != null) {
        debugPrint('[Manifest] Returning expired cache due to error');
        return cached;
      }
      rethrow;
    }
  }

  /// Format edition ID into display name
  String _formatEditionName(String editionId) {
    final parts = editionId.split('.');
    if (parts.length < 2) return editionId;
    final name = parts[1];
    // Convert camelCase or lowercase to Title Case
    return name
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .split(' ')
        .map((w) => w.isEmpty
            ? ''
            : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }

  /// Get cached manifest
  Future<AudioManifest?> _getCachedManifest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
      return AudioManifest.fromJson(jsonMap);
    } catch (e) {
      debugPrint('[Manifest] Error reading cache: $e');
      return null;
    }
  }

  /// Cache manifest
  Future<void> _cacheManifest(AudioManifest manifest) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(manifest.toJson());
      await prefs.setString(_cacheKey, jsonString);
      debugPrint('[Manifest] Cached manifest successfully');
    } catch (e) {
      debugPrint('[Manifest] Error caching manifest: $e');
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    debugPrint('[Manifest] Cache cleared');
  }
}

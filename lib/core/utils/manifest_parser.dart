import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../data/models/audio_manifest_model.dart';

/// Utility class for parsing manifest data
/// Designed to be used in isolates for background parsing
class ManifestParser {
  /// Parse surah manifest (JSON format)
  /// Accepts either a List or Map structure
  static Map<String, Set<int>> parseSurahManifest(dynamic surahData) {
    final editions = <String, Set<int>>{};
    final translationIds = <String>[];

    try {
      // Handle both List and Map structures
      List<dynamic> surahList;
      if (surahData is List) {
        surahList = surahData;
      } else if (surahData is Map && surahData.containsKey('value')) {
        surahList = surahData['value'] as List<dynamic>;
      } else {
        // Try to find the directory in the data structure
        surahList = surahData is List ? surahData : [surahData];
      }
      
      final surahManifest = surahList.firstWhere(
        (item) => item is Map &&
            item['type'] == 'directory' &&
            item['name'] == '/mnt/cdn/islamic-network-cdn/quran/audio-surah',
      ) as Map<String, dynamic>;

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
          
          if (!_isValidEditionId(editionId)) continue;

          editions.putIfAbsent(editionId, () => <int>{});
          editions[editionId]!.add(bitrate);
          
          // Track translations found in surah manifest
          if (!editionId.startsWith('ar.')) {
            translationIds.add(editionId);
          }
        }
      }
      
      // Use debugPrint for better logging control
      if (kDebugMode) {
        debugPrint('[ManifestParser] Surah manifest: Found ${translationIds.length} translations: ${translationIds.join(", ")}');
      }
    } catch (e) {
      // Log error but continue
      if (kDebugMode) {
        debugPrint('[ManifestParser] Error parsing surah manifest: $e');
      }
    }

    return editions;
  }

  /// Parse ayah manifest (text format)
  /// Format is a tree structure like:
  /// /mnt/cdn/islamic-network-cdn/quran/audio
  /// ├── 128
  /// │   ├── ar.ahmedajamy
  /// │   ├── ar.alafasy
  static Map<String, Set<int>> parseAyahManifest(String ayahText) {
    final editions = <String, Set<int>>{};
    final translationIds = <String>[];
    final ayahLines = ayahText.split('\n');
    int? currentBitrate;
    int linesProcessed = 0;

    if (kDebugMode) {
      debugPrint('[ManifestParser] parseAyahManifest: Processing ${ayahLines.length} lines');
    }

    for (final line in ayahLines) {
      linesProcessed++;
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Check if line contains a number that could be a bitrate
      // Handle both "128" and "├── 128" formats
      final bitrateMatch = RegExp(r'(\d+)').firstMatch(trimmed);
      if (bitrateMatch != null) {
        final potentialBitrate = int.tryParse(bitrateMatch.group(1)!);
        // Check if this looks like a bitrate directory (standalone number or after tree markers)
        // Bitrates are typically 32, 40, 48, 64, 128, 192, 320
        if (potentialBitrate != null && 
            (potentialBitrate == 32 || potentialBitrate == 40 || potentialBitrate == 48 || 
             potentialBitrate == 64 || potentialBitrate == 128 || potentialBitrate == 192 || 
             potentialBitrate == 320)) {
          // Check if line is mostly just the number (not an edition ID)
          final lineWithoutNumber = trimmed.replaceAll(RegExp(r'\d+'), '').trim();
          // If after removing the number, line is mostly empty or just tree markers, it's a bitrate
          if (lineWithoutNumber.isEmpty || 
              lineWithoutNumber == '├──' || 
              lineWithoutNumber == '│' ||
              lineWithoutNumber.startsWith('├') ||
              lineWithoutNumber.startsWith('│')) {
            currentBitrate = potentialBitrate;
            if (kDebugMode) {
              debugPrint('[ManifestParser] Found bitrate: $currentBitrate (line: $trimmed)');
            }
            continue;
          }
        }
      }

      // Look for edition IDs in the line (format: ar.ahmedajamy or ├── ar.ahmedajamy)
      if (currentBitrate != null) {
        // Extract edition ID - look for pattern like "ar.xxx" or "├── ar.xxx"
        final editionMatch = RegExp(r'\b([a-z]{2}\.[a-z0-9_-]+(?:\.[a-z0-9_-]+)*)\b')
            .firstMatch(trimmed);
        if (editionMatch != null) {
          final editionId = editionMatch.group(1)!;
          // Remove -2, -3 suffixes (alternative versions)
          final cleanId = editionId.replaceAll(RegExp(r'-\d+$'), '');
          if (_isValidEditionId(cleanId)) {
            editions.putIfAbsent(cleanId, () => <int>{});
            editions[cleanId]!.add(currentBitrate);
            
            if (kDebugMode && cleanId.startsWith('ar.')) {
              debugPrint('[ManifestParser] Found Arabic reciter in ayah manifest: $cleanId (bitrate: $currentBitrate)');
            }
            
            // Track translations found in ayah manifest
            if (!cleanId.startsWith('ar.')) {
              if (!translationIds.contains(cleanId)) {
                translationIds.add(cleanId);
              }
            }
          } else {
            // Debug: log rejected IDs
            if (kDebugMode) {
              debugPrint('[ManifestParser] Rejected edition ID from ayah manifest: $cleanId (from: $trimmed)');
            }
          }
        } else if (kDebugMode && currentBitrate != null && trimmed.contains('ar.')) {
          // Debug: log lines that look like they might have an edition ID but didn't match
          debugPrint('[ManifestParser] Line looks like it might have edition ID but didn\'t match: $trimmed');
        }
      } else if (kDebugMode && linesProcessed < 50 && trimmed.contains('ar.')) {
        // Debug: log if we see edition-like content before finding a bitrate
        debugPrint('[ManifestParser] Found edition-like content before bitrate: $trimmed');
      }
    }
    
    if (kDebugMode) {
      if (currentBitrate == null) {
        debugPrint('[ManifestParser] WARNING: No bitrate found in ayah manifest!');
      }
    }
    
    if (kDebugMode) {
      debugPrint('[ManifestParser] Ayah manifest: Found ${editions.length} total editions');
      debugPrint('[ManifestParser] Ayah manifest: Found ${translationIds.length} translations: ${translationIds.join(", ")}');
      final arabicCount = editions.keys.where((id) => id.startsWith('ar.')).length;
      debugPrint('[ManifestParser] Ayah manifest: Found $arabicCount Arabic reciters with verse-by-verse');
      if (arabicCount > 0) {
        final arabicIds = editions.keys.where((id) => id.startsWith('ar.')).take(10).toList();
        debugPrint('[ManifestParser] Ayah manifest: Sample Arabic IDs: ${arabicIds.join(", ")}');
      }
    }

    return editions;
  }

  /// Merge two edition maps (combines bitrates)
  /// Direct matching only - all IDs are CDN IDs (no normalization)
  static Map<String, Set<int>> mergeEditions(
    Map<String, Set<int>> map1,
    Map<String, Set<int>> map2,
  ) {
    final merged = <String, Set<int>>{};
    
    // Add all from map1
    for (final entry in map1.entries) {
      merged[entry.key] = Set<int>.from(entry.value);
    }
    
    // Merge with map2 (direct key matching)
    for (final entry in map2.entries) {
      merged.putIfAbsent(entry.key, () => <int>{});
      merged[entry.key]!.addAll(entry.value);
    }
    
    return merged;
  }

  /// Build AudioEdition objects from parsed data
  /// surahEditions: editions available for full surah playback
  /// ayahEditions: editions available for verse-by-verse playback
  static (List<AudioEdition>, List<AudioEdition>) buildEditions(
    Map<String, Set<int>> surahEditions,
    Map<String, Set<int>> ayahEditions,
    Map<String, Map<String, String>> knownReciters,
    Map<String, Map<String, String>> knownTranslations,
  ) {
    final arabicReciters = <AudioEdition>[];
    final translations = <AudioEdition>[];

    // Merge bitrates from both manifests, but track verse-by-verse availability
    final mergedEditions = mergeEditions(surahEditions, ayahEditions);
    
    // Get set of editions that have verse-by-verse audio (direct matching)
    final verseByVerseIds = ayahEditions.keys.toSet();
    
    if (kDebugMode) {
      debugPrint('[ManifestParser] buildEditions: ayahEditions has ${ayahEditions.length} editions');
      debugPrint('[ManifestParser] buildEditions: verseByVerseIds has ${verseByVerseIds.length} IDs');
      debugPrint('[ManifestParser] buildEditions: mergedEditions has ${mergedEditions.length} editions');
      if (ayahEditions.isNotEmpty) {
        debugPrint('[ManifestParser] buildEditions: Sample ayah edition IDs: ${ayahEditions.keys.take(5).join(", ")}');
      }
      if (surahEditions.isNotEmpty) {
        debugPrint('[ManifestParser] buildEditions: Sample surah edition IDs: ${surahEditions.keys.take(5).join(", ")}');
      }
      if (verseByVerseIds.isNotEmpty) {
        debugPrint('[ManifestParser] buildEditions: Sample verse-by-verse IDs: ${verseByVerseIds.take(5).join(", ")}');
      }
    }

    for (final entry in mergedEditions.entries) {
      final editionId = entry.key;
      final bitrates = entry.value.toList()..sort();
      // Direct matching - all IDs are CDN IDs
      final hasVerseByVerse = verseByVerseIds.contains(editionId);
      
      if (kDebugMode && editionId.startsWith('ar.') && hasVerseByVerse) {
        debugPrint('[ManifestParser] buildEditions: Found verse-by-verse reciter: $editionId');
      }

      final isArabic = editionId.startsWith('ar.');
      final languageCode = editionId.split('.').first;

      // Get known metadata
      final metadata = isArabic
          ? knownReciters[editionId]
          : knownTranslations[editionId];

      // Auto-generate flag if not provided
      String? flag = metadata?['flag'];
      if (flag == null && !isArabic) {
        flag = _getDefaultFlagForLanguage(languageCode);
      }

      // REQUIRE manual names from _knownReciters - no script formatting
      // If not found, use edition ID as-is (user must add to _knownReciters)
      final displayName = metadata?['name'] ?? editionId;
      final displayNameTajik = metadata?['nameTajik'] ?? displayName;
      
      final edition = AudioEdition(
        id: editionId,
        appId: metadata?['appId'],
        name: displayName,
        nameTajik: displayNameTajik,
        nameArabic: metadata?['nameArabic'],
        languageCode: languageCode,
        isTranslation: !isArabic,
        availableBitrates: bitrates,
        flag: flag,
        hasVerseByVerse: hasVerseByVerse,
      );

      if (isArabic) {
        arabicReciters.add(edition);
      } else {
        translations.add(edition);
        // Debug: print all translation IDs found
        if (kDebugMode) {
          debugPrint('[ManifestParser] Found translation: ${edition.id} (lang: ${edition.languageCode})');
        }
      }
    }

    // Sort by name
    arabicReciters.sort((a, b) => a.name.compareTo(b.name));
    translations.sort((a, b) => a.name.compareTo(b.name));

    if (kDebugMode) {
      debugPrint('[ManifestParser] Total translations found: ${translations.length}');
      debugPrint('[ManifestParser] Translation IDs: ${translations.map((e) => e.id).join(", ")}');
      final verseByVerseCount = arabicReciters.where((e) => e.hasVerseByVerse).length;
      debugPrint('[ManifestParser] Reciters with verse-by-verse: $verseByVerseCount out of ${arabicReciters.length}');
      if (verseByVerseCount > 0) {
        final verseByVerseReciterIds = arabicReciters.where((e) => e.hasVerseByVerse).map((e) => e.id).take(5).toList();
        debugPrint('[ManifestParser] Sample verse-by-verse reciter IDs: ${verseByVerseReciterIds.join(", ")}');
      } else {
        debugPrint('[ManifestParser] WARNING: No reciters found with verse-by-verse support!');
        debugPrint('[ManifestParser] This might indicate an issue with ayah manifest parsing.');
      }
    }

    return (arabicReciters, translations);
  }

  // Script formatter REMOVED - all names must be manually added to _knownReciters in AudioManifestServiceV2
  // If a reciter is not in _knownReciters, the edition ID will be displayed as-is

  /// Check if edition ID is valid
  /// Accepts any 2-letter language code followed by a dot (e.g., ar., en., fa., etc.)
  static bool _isValidEditionId(String editionId) {
    // Match pattern: 2 lowercase letters, dot, then alphanumeric/underscore/hyphen
    final pattern = RegExp(r'^[a-z]{2}\.[a-z0-9_-]+');
    return pattern.hasMatch(editionId);
  }

  /// Get default flag emoji for language code
  static String? _getDefaultFlagForLanguage(String languageCode) {
    const flagMap = {
      'ar': '🇸🇦', // Arabic
      'fa': '🇮🇷', // Persian/Farsi
      'ru': '🇷🇺', // Russian
      'en': '🇬🇧', // English
      'ur': '🇵🇰', // Urdu
      'tr': '🇹🇷', // Turkish
      'id': '🇮🇩', // Indonesian
      'ms': '🇲🇾', // Malay
      'bn': '🇧🇩', // Bengali
      'hi': '🇮🇳', // Hindi
      'es': '🇪🇸', // Spanish
      'fr': '🇫🇷', // French
      'de': '🇩🇪', // German
      'it': '🇮🇹', // Italian
      'pt': '🇵🇹', // Portuguese
      'zh': '🇨🇳', // Chinese
      'ja': '🇯🇵', // Japanese
      'ko': '🇰🇷', // Korean
    };
    return flagMap[languageCode];
  }
}


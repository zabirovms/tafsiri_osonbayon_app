import 'package:flutter/foundation.dart' show debugPrint;
import '../models/reciter_model.dart';
import '../../core/constants/audio_constants.dart';
import '../../core/utils/compressed_json_loader.dart';

/// Service to load reciter data from JSON files
/// Keeps full surah and verse-by-verse data separate as requested
class ReciterDataService {
  static ReciterDataService? _instance;
  static ReciterDataService get instance => _instance ??= ReciterDataService._();
  
  ReciterDataService._();

  // Cache for loaded data
  List<FullSurahReciterData>? _fullSurahReciters;
  List<VerseByVerseReciterData>? _verseByVerseReciters;
  Map<String, int>? _fullSurahBitrateMap;
  Map<String, int>? _verseByVerseBitrateMap;

  /// Load full surah reciter data from JSON
  Future<List<FullSurahReciterData>> loadFullSurahReciters() async {
    if (_fullSurahReciters != null) {
      return _fullSurahReciters!;
    }

    try {
      final List<dynamic> jsonList = await CompressedJsonLoader.loadJsonAsList(
          'assets/data/reciters/full_surah_reciters.json');
      
      _fullSurahReciters = jsonList
          .map((json) => FullSurahReciterData.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Build bitrate map
      _fullSurahBitrateMap = {};
      for (final reciter in _fullSurahReciters!) {
        if (reciter.bitrate != null) {
          _fullSurahBitrateMap![reciter.id] = reciter.bitrate!;
        }
      }
      
      debugPrint('[ReciterDataService] Loaded ${_fullSurahReciters!.length} full surah reciters');
      return _fullSurahReciters!;
    } catch (e) {
      debugPrint('[ReciterDataService] Error loading full surah reciters: $e');
      // Return empty list on error
      return [];
    }
  }

  /// Load verse-by-verse reciter data from JSON
  Future<List<VerseByVerseReciterData>> loadVerseByVerseReciters() async {
    if (_verseByVerseReciters != null) {
      return _verseByVerseReciters!;
    }

    try {
      final List<dynamic> jsonList = await CompressedJsonLoader.loadJsonAsList(
          'assets/data/reciters/verse_by_verse_reciters.json');
      
      _verseByVerseReciters = jsonList
          .map((json) => VerseByVerseReciterData.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Build bitrate map
      _verseByVerseBitrateMap = {};
      for (final reciter in _verseByVerseReciters!) {
        _verseByVerseBitrateMap![reciter.id] = reciter.bitrate;
      }
      
      debugPrint('[ReciterDataService] Loaded ${_verseByVerseReciters!.length} verse-by-verse reciters');
      return _verseByVerseReciters!;
    } catch (e) {
      debugPrint('[ReciterDataService] Error loading verse-by-verse reciters: $e');
      // Return empty list on error
      return [];
    }
  }

  /// Get full surah reciters as ReciterModel list
  Future<List<ReciterModel>> getFullSurahReciters({bool confirmedOnly = false}) async {
    final reciters = await loadFullSurahReciters();
    
    final result = reciters
        .where((r) => !confirmedOnly || r.isConfirmed)
        .map((r) => ReciterModel(
              id: r.id,
              name: r.name,
              nameTajik: r.nameTajik,
              nameArabic: r.nameArabic,
            ))
        .toList();
    
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Get verse-by-verse reciters as ReciterModel list
  /// Excludes Chinese, French, and Urdu translations
  Future<List<ReciterModel>> getVerseByVerseReciters() async {
    final reciters = await loadVerseByVerseReciters();
    
    // IDs to exclude: Chinese, French, and Urdu
    const excludedIds = {
      'zh.chinese',  // Chinese
      'fr.leclerc',  // French
      'ur.khan',     // Urdu
    };
    
    final result = reciters
        .where((r) => !excludedIds.contains(r.id))
        .map((r) => ReciterModel(
              id: r.id,
              name: r.name,
              nameTajik: r.nameTajik,
              nameArabic: r.nameArabic,
            ))
        .toList();
    
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  /// Get bitrate for full surah playback
  /// Returns null if reciter not found or not confirmed
  Future<int?> getFullSurahBitrate(String cdnId) async {
    await loadFullSurahReciters();
    
    // Check explicit bitrate map first
    if (_fullSurahBitrateMap?.containsKey(cdnId) ?? false) {
      return _fullSurahBitrateMap![cdnId];
    }
    
    // Check if confirmed (has default bitrate)
    if (_fullSurahReciters != null) {
      final reciter = _fullSurahReciters!.firstWhere(
        (r) => r.id == cdnId && r.isConfirmed,
        orElse: () => FullSurahReciterData.empty(),
      );
      
      if (reciter.id.isNotEmpty && reciter.isConfirmed) {
        return AudioConstants.defaultBitrate;
      }
    }
    
    return null;
  }

  /// Get bitrate for verse-by-verse playback
  Future<int> getVerseByVerseBitrate(String cdnId) async {
    await loadVerseByVerseReciters();
    return _verseByVerseBitrateMap?[cdnId] ?? AudioConstants.defaultBitrate;
  }

  /// Check if reciter supports verse-by-verse
  Future<bool> supportsVerseByVerse(String cdnId) async {
    final reciters = await loadVerseByVerseReciters();
    // Direct match - JSON uses CDN IDs (no underscores)
    return reciters.any((r) => r.id.toLowerCase() == cdnId.toLowerCase());
  }

  /// Get set of verse-by-verse reciter IDs
  Future<Set<String>> getVerseByVerseReciterIds() async {
    final reciters = await loadVerseByVerseReciters();
    return reciters.map((r) => r.id).toSet();
  }

  /// Clear cache (useful for testing or reloading)
  void clearCache() {
    _fullSurahReciters = null;
    _verseByVerseReciters = null;
    _fullSurahBitrateMap = null;
    _verseByVerseBitrateMap = null;
  }
}

/// Data model for full surah reciter
class FullSurahReciterData {
  final String id;
  final String name;
  final String nameTajik;
  final String nameArabic;
  final int? bitrate; // null means default (128), explicit values for non-default
  final bool isConfirmed; // true if confirmed to exist on CDN

  const FullSurahReciterData({
    required this.id,
    required this.name,
    required this.nameTajik,
    required this.nameArabic,
    this.bitrate,
    required this.isConfirmed,
  });

  factory FullSurahReciterData.fromJson(Map<String, dynamic> json) {
    return FullSurahReciterData(
      id: json['id'] as String,
      name: json['name'] as String,
      nameTajik: json['nameTajik'] as String? ?? '',
      nameArabic: json['nameArabic'] as String? ?? '',
      bitrate: json['bitrate'] as int?,
      isConfirmed: json['isConfirmed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameTajik': nameTajik,
        'nameArabic': nameArabic,
        if (bitrate != null) 'bitrate': bitrate,
        'isConfirmed': isConfirmed,
      };

  static FullSurahReciterData empty() {
    return const FullSurahReciterData(
      id: '',
      name: '',
      nameTajik: '',
      nameArabic: '',
      isConfirmed: false,
    );
  }
}

/// Data model for verse-by-verse reciter
class VerseByVerseReciterData {
  final String id;
  final String name;
  final String nameTajik;
  final String nameArabic;
  final int bitrate; // Always has a bitrate

  const VerseByVerseReciterData({
    required this.id,
    required this.name,
    required this.nameTajik,
    required this.nameArabic,
    required this.bitrate,
  });

  factory VerseByVerseReciterData.fromJson(Map<String, dynamic> json) {
    return VerseByVerseReciterData(
      id: json['id'] as String,
      name: json['name'] as String,
      nameTajik: json['nameTajik'] as String? ?? '',
      nameArabic: json['nameArabic'] as String? ?? '',
      bitrate: json['bitrate'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'nameTajik': nameTajik,
        'nameArabic': nameArabic,
        'bitrate': bitrate,
      };
}


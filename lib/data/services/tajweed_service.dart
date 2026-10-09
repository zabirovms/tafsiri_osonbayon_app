import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../core/utils/tajweed_rules.dart';

class TajweedService extends ChangeNotifier {
  static final TajweedService _instance = TajweedService._internal();
  factory TajweedService() => _instance;
  TajweedService._internal();

  Map<String, List<String>>? _tajweedCache;
  bool _isLoading = false;

  bool get isLoaded => _tajweedCache != null && _tajweedCache!.isNotEmpty;

  /// Ensure the Tajweed dataset is loaded and cached in memory
  Future<void> init() async {
    if (_tajweedCache != null || _isLoading) return;
    _isLoading = true;
    try {
      final jsonString = await rootBundle.loadString('assets/data/quran/QPC_Hafs_Tajweed_Compress.json');
      _tajweedCache = await compute(_parseAndExpandTajweedInIsolate, jsonString);
      notifyListeners();
    } catch (e) {
      _tajweedCache = {};
    } finally {
      _isLoading = false;
    }
  }

  /// Get Tajweed word list for a specific verse (e.g. surah 1, verse 1 -> "1:1")
  Future<List<String>?> getTajweedWords(int surahId, int verseNumber) async {
    if (_tajweedCache == null) {
      await init();
    }
    return _tajweedCache?['$surahId:$verseNumber'];
  }

  /// Synchronous getter if already loaded
  List<String>? getTajweedWordsSync(int surahId, int verseNumber) {
    return _tajweedCache?['$surahId:$verseNumber'];
  }
}

/// Top-level function for compute isolate to parse and expand Tajweed rules
Map<String, List<String>> _parseAndExpandTajweedInIsolate(String jsonString) {
  final Map<String, dynamic> rawMap = jsonDecode(jsonString);
  final cache = <String, List<String>>{};

  for (final surahKey in rawMap.keys) {
    final surahData = rawMap[surahKey] as Map<String, dynamic>;
    for (final ayahKey in surahData.keys) {
      final compressedList = List<String>.from(surahData[ayahKey] as List);
      final expandedList = <String>[];

      for (String word in compressedList) {
        for (int j = tajweedRulesExpansionList.length - 1; j >= 0; j--) {
          word = word.replaceAll('r$j', tajweedRulesExpansionList[j]);
        }
        expandedList.add(word);
      }

      cache['$surahKey:$ayahKey'] = expandedList;
    }
  }

  return cache;
}

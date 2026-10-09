import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../datasources/remote/alquran_cloud_api.dart';
import '../datasources/remote/api_service.dart';
import '../models/alquran_cloud_models.dart';
import '../models/word_by_word_model.dart';

/// Repository that merges Supabase (translations, tafsir, wbw) with
/// AlQuran Cloud (Arabic text, audio, markers) for the Surah page.
class IntegratedQuranRepository {
  IntegratedQuranRepository({required ApiService apiService, required AlQuranCloudApi aqc})
      : _apiService = apiService,
        _aqc = aqc;

  final ApiService _apiService;
  final AlQuranCloudApi _aqc;

  // Get word-by-word data using local verse keys (optimized - no Supabase verse loading)
  Future<Map<String, List<WordByWordModel>>> getWordByWordByKeys(List<String> keys) async {
    try {
      if (keys.isEmpty) {
        return <String, List<WordByWordModel>>{};
      }

      // Fetch in batches to avoid URL length limits and 414/empty responses
      const int batchSize = 50;
      final items = <WordByWordModel>[];
      bool hasNetworkError = false;
      
      for (var i = 0; i < keys.length; i += batchSize) {
        final batch = keys.sublist(i, i + batchSize > keys.length ? keys.length : i + batchSize);
        try {
          final res = await _apiService.getWordByWordByKeys(batch);
          final list = (res.data as List?) ?? const [];
          items.addAll(list.map((e) => WordByWordModel.fromJson(e)));
        } on DioException catch (e) {
          // Check if it's a network error
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.connectionError ||
              e.type == DioExceptionType.receiveTimeout) {
            hasNetworkError = true;
            debugPrint('Network error in WBW batch, aborting subsequent batches: ${e.message}');
            break;
          }
          // Continue with other batches; optionally log
          debugPrint('Error fetching WBW batch: ${e.message}');
        } catch (e) {
          // Continue with other batches; optionally log
          debugPrint('Error fetching WBW batch: $e');
        }
      }
      
      // If we have network errors and no data, throw a specific exception
      if (hasNetworkError && items.isEmpty) {
        throw Exception('NETWORK_ERROR: Word-by-word data unavailable. Please check your internet connection.');
      }
      
      final grouped = <String, List<WordByWordModel>>{};
      for (final item in items) {
        grouped.putIfAbsent(item.uniqueKey, () => []).add(item);
      }
      for (final key in grouped.keys) {
        grouped[key]!.sort((a, b) => a.wordNumber.compareTo(b.wordNumber));
      }
      return grouped;
    } catch (e) {
      // Re-throw network errors to be handled by the controller
      if (e.toString().contains('NETWORK_ERROR')) {
        rethrow;
      }
      // For other errors, return empty map
      return <String, List<WordByWordModel>>{};
    }
  }


  Future<(List<AqcAyah>, List<AqcAyah>)> getArabicAndAudio(int surahNumber, String audioEdition) async {
    try {
      final combined = await _aqc.getSurahCombined(surahNumber: surahNumber, audioEdition: audioEdition);
      final body = combined.data as Map<String, dynamic>;
      final data = body['data'];
      // combined returns a List of two editions (text + audio)
      final editions = (data as List).cast<Map<String, dynamic>>().map(SurahEdition.fromJson).toList();
      editions.sort((a, b) => a.editionIdentifier.compareTo(b.editionIdentifier));
      final textEdition = editions.firstWhere((e) => e.editionIdentifier.contains('quran-uthmani'), orElse: () => editions.first);
      final audioEd = editions.firstWhere((e) => e.editionIdentifier == audioEdition, orElse: () => editions.last);
      return (textEdition.ayahs, audioEd.ayahs);
    } on DioException {
      // Fallback: fetch separately
      final arabicRes = await _aqc.getSurahArabic(surahNumber: surahNumber);
      final audioRes = await _aqc.getSurahAudio(surahNumber: surahNumber, audioEdition: audioEdition);
      final arabicData = (arabicRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final audioData = (audioRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final textEdition = SurahEdition.fromJson(arabicData);
      final audioEditionParsed = SurahEdition.fromJson(audioData);
      return (textEdition.ayahs, audioEditionParsed.ayahs);
    }
  }

  Future<List<AqcAyah>> getAudioOnly(int surahNumber, String audioEdition) async {
    try {
      final audioRes = await _aqc.getSurahAudio(surahNumber: surahNumber, audioEdition: audioEdition);
      final audioData = (audioRes.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
      final audioEditionParsed = SurahEdition.fromJson(audioData);
      return audioEditionParsed.ayahs;
    } catch (e) {
      throw Exception('Failed to load audio for surah $surahNumber: $e');
    }
  }
}



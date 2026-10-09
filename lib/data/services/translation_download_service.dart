import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../datasources/remote/api_service.dart';

class TranslationDownloadService {
  final ApiService _apiService;
  
  TranslationDownloadService({required ApiService apiService})
      : _apiService = apiService;

  // Get translations box
  Box get _translationsBox => Hive.box(AppConstants.downloadedTranslationsBox);

  // Check if a translation exists locally for a surah
  Future<bool> hasTranslationLocally(String translationCode, int surahNumber) async {
    try {
      final key = '${translationCode}_surah_$surahNumber';
      return _translationsBox.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  // Check if a specific verse has the translation locally
  Future<bool> hasVerseTranslation(String translationCode, String verseKey) async {
    try {
      final key = '${translationCode}_verse_$verseKey';
      return _translationsBox.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  // Get translation for a verse from local storage
  String? getVerseTranslation(String translationCode, String verseKey) {
    try {
      final key = '${translationCode}_verse_$verseKey';
      return _translationsBox.get(key) as String?;
    } catch (e) {
      return null;
    }
  }

  // Download translation for a surah from Supabase
  Future<void> downloadSurahTranslation(
    String translationCode,
    int surahNumber, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Check internet connectivity
      final isConnected = await _apiService.isConnected();
      if (!isConnected) {
        throw Exception('No internet connection');
      }

      // Get verses from Supabase
      final response = await _apiService.getSurahVerses(surahNumber);
      final versesData = response.data as List;

      if (versesData.isEmpty) {
        throw Exception('No verses found for surah $surahNumber');
      }

      int downloaded = 0;
      final total = versesData.length;

      // Store each verse translation
      for (final verseData in versesData) {
        final verseNumber = verseData['verse_number'] as int;
        final verseKey = '$surahNumber:$verseNumber';
        
        // Get the translation field based on code
        String? translation;
        switch (translationCode) {
          case 'tajik_alomuddin':
            translation = verseData['tj_2'] as String?;
            break;
          case 'tajik_pioneers':
            translation = verseData['tj_3'] as String?;
            break;
          case 'tajik_khojamirov':
            translation = verseData['tj_4'] as String?;
            break;
          default:
            throw Exception('Unsupported translation code: $translationCode');
        }

        if (translation != null && translation.isNotEmpty) {
          final key = '${translationCode}_verse_$verseKey';
          await _translationsBox.put(key, translation);
          downloaded++;
        }

        // Report progress
        if (onProgress != null) {
          onProgress(downloaded, total);
        }
      }

      // Mark surah as downloaded
      final surahKey = '${translationCode}_surah_$surahNumber';
      await _translationsBox.put(surahKey, true);
    } catch (e) {
      throw Exception('Failed to download translation: $e');
    }
  }

  // Download all translations for a translation code (all surahs)
  Future<void> downloadAllTranslations(
    String translationCode, {
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Check internet connectivity
      final isConnected = await _apiService.isConnected();
      if (!isConnected) {
        throw Exception('No internet connection');
      }

      // Download all 114 surahs
      int downloadedSurahs = 0;
      const totalSurahs = 114;

      for (int surahNumber = 1; surahNumber <= 114; surahNumber++) {
        await downloadSurahTranslation(
          translationCode,
          surahNumber,
          onProgress: (current, total) {
            // Calculate overall progress
            final overallCurrent = (surahNumber - 1) * 100 + current;
            final overallTotal = totalSurahs * 100;
            if (onProgress != null) {
              onProgress(overallCurrent, overallTotal);
            }
          },
        );
        downloadedSurahs++;
        
        // Report surah progress
        if (onProgress != null) {
          onProgress(downloadedSurahs * 100, totalSurahs * 100);
        }
      }
    } catch (e) {
      throw Exception('Failed to download all translations: $e');
    }
  }

  // Clear downloaded translations for a specific translation code
  Future<void> clearTranslation(String translationCode) async {
    try {
      final keysToDelete = <String>[];
      
      for (final key in _translationsBox.keys) {
        if (key.toString().startsWith('${translationCode}_')) {
          keysToDelete.add(key.toString());
        }
      }
      
      for (final key in keysToDelete) {
        await _translationsBox.delete(key);
      }
    } catch (e) {
      throw Exception('Failed to clear translation: $e');
    }
  }

  // Get download size estimate (in bytes, approximate)
  int getDownloadedSize(String translationCode) {
    try {
      int totalSize = 0;
      
      for (final key in _translationsBox.keys) {
        if (key.toString().startsWith('${translationCode}_')) {
          final value = _translationsBox.get(key);
          if (value is String) {
            totalSize += value.length * 2; // Approximate UTF-8 size
          }
        }
      }
      
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
}


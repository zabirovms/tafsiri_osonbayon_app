import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tajik_audio_file_model.dart';

class TajikAudioService {
  static const String _apiBaseUrl = 'https://orange-salad-3850.zabirovms.workers.dev';
  static const String _listEndpoint = '/list';
  
  // Cache for the audio files list
  static List<TajikAudioFileModel>? _cachedFiles;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(hours: 1);

  /// Fetch the list of available Tajik audio files from the API
  Future<List<TajikAudioFileModel>> fetchAudioFiles() async {
    // Return cached data if available and not expired
    if (_cachedFiles != null && _cacheTimestamp != null) {
      final age = DateTime.now().difference(_cacheTimestamp!);
      if (age < _cacheDuration) {
        return _cachedFiles!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl$_listEndpoint'),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final files = jsonList
            .map((json) => TajikAudioFileModel.fromJson(json as Map<String, dynamic>))
            .where((file) => file.surahNumber >= 1 && file.surahNumber <= 114)
            .toList();
        
        // Cache the results
        _cachedFiles = files;
        _cacheTimestamp = DateTime.now();
        
        return files;
      } else {
        throw Exception('Failed to fetch audio files: ${response.statusCode}');
      }
    } catch (e) {
      // If we have cached data, return it even if expired
      if (_cachedFiles != null) {
        return _cachedFiles!;
      }
      rethrow;
    }
  }

  /// Get the audio URL for a specific surah number
  Future<String?> getAudioUrlForSurah(int surahNumber) async {
    try {
      final files = await fetchAudioFiles();
      
      // Find file matching the surah number
      // Format: "003.mp3" for surah 3
      final surahNumberStr = surahNumber.toString().padLeft(3, '0');
      final fileName = '$surahNumberStr.mp3';
      
      final file = files.firstWhere(
        (f) => f.name == fileName,
        orElse: () => files.firstWhere(
          (f) => f.surahNumber == surahNumber,
          orElse: () => throw Exception('Surah $surahNumber not found'),
        ),
      );
      
      return file.url;
    } catch (e) {
      return null;
    }
  }

  /// Clear the cache (useful for testing or forced refresh)
  static void clearCache() {
    _cachedFiles = null;
    _cacheTimestamp = null;
  }
}


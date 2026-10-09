import 'package:dio/dio.dart';

/// Lightweight client for AlQuran Cloud API
/// Docs: https://alquran.cloud/api
class AlQuranCloudApi {
  AlQuranCloudApi({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://api.alquran.cloud/v1'));

  final Dio _dio;

  /// Fetch combined editions for a surah (Arabic Uthmani + audio)
  /// Example editions: quran-uthmani, ar.alafasy
  Future<Response<dynamic>> getSurahCombined({required int surahNumber, required String audioEdition}) {
    final path = '/surah/$surahNumber/editions/quran-uthmani,$audioEdition';
    return _dio.get(path);
  }

  /// Fetch Arabic Uthmani text only
  Future<Response<dynamic>> getSurahArabic({required int surahNumber}) {
    return _dio.get('/surah/$surahNumber/quran-uthmani');
  }

  /// Fetch audio edition only
  Future<Response<dynamic>> getSurahAudio({required int surahNumber, required String audioEdition}) {
    return _dio.get('/surah/$surahNumber/$audioEdition');
  }

  /// List available audio editions (for reciter selector)
  Future<Response<dynamic>> listAudioEditions() {
    return _dio.get('/edition', queryParameters: {'format': 'audio'});
  }
}



import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/config/api_config.dart';
import '../../../core/error/exceptions.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _apiDio; // For web API endpoints
  late Dio _supabaseDio; // For direct Supabase calls (if needed)
  late Dio _alquranDio;

  // Supabase REST API configuration
  static String get _apiBaseUrl => '${ApiConfig.supabaseUrl}/rest/v1';
  static String get _supabaseUrl => ApiConfig.supabaseUrl;
  static String get _supabaseAnonKey => ApiConfig.supabaseAnonKey;
  
  // AlQuran Cloud API for audio
  static String get _alquranBaseUrl => ApiConfig.alquranCloudUrl;

  ApiService._internal() {
    final anonKey = _supabaseAnonKey;
    final apiBase = _apiBaseUrl;
    final supabaseBase = _supabaseUrl;
    final alquranBase = _alquranBaseUrl;
    
    // Supabase REST API client (primary)
    _apiDio = Dio(BaseOptions(
      baseUrl: apiBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Supabase client (for direct calls if needed)
    _supabaseDio = Dio(BaseOptions(
      baseUrl: supabaseBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'apikey': anonKey,
        'Authorization': 'Bearer $anonKey',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // AlQuran Cloud client
    _alquranDio = Dio(BaseOptions(
      baseUrl: alquranBase,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors for all clients
    _addInterceptors(_apiDio);
    _addInterceptors(_supabaseDio);
    _addInterceptors(_alquranDio);
  }

  factory ApiService() => _instance;

  /// Dio instance pre-configured for Supabase REST API (library_books, etc.)
  Dio get libraryDio => _apiDio;

  // Add interceptors helper method
  void _addInterceptors(Dio dio) {
    // Only add logging interceptor in debug mode, and disable verbose body logging
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: false, // Disable request body logging
        responseBody: false, // Disable response body logging (this is what's causing the mess)
        requestHeader: false, // Disable request headers
        responseHeader: false, // Disable response headers
        logPrint: (object) => debugPrint(object.toString()),
      ));
    }

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.next(options);
      },
      onResponse: (response, handler) {
        handler.next(response);
      },
      onError: (error, handler) {
        handler.next(error);
      },
    ));
  }

  // Check internet connectivity
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  /// Public alias used by providers to gate network operations.
  Future<bool> checkOnline() => isConnected();


  // Get verses for a specific surah from Supabase
  Future<Response> getSurahVerses(int surahNumber) async {
    try {
      // First get the surah to get its ID
      final surahResponse = await _apiDio.get('/surahs?number=eq.$surahNumber&select=id');
      final surahs = surahResponse.data as List;
      
      if (surahs.isEmpty) {
        return Response(requestOptions: RequestOptions(), data: []);
      }
      
      final surahId = surahs.first['id'];
      final response = await _apiDio.get('/verses?surah_id=eq.$surahId&select=*&order=verse_number');
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  // Batch fetch word-by-word by unique keys
  Future<Response> getWordByWordByKeys(List<String> uniqueKeys) async {
    try {
      if (uniqueKeys.isEmpty) {
        return Response(requestOptions: RequestOptions(), data: []);
      }
      final keys = uniqueKeys.map((k) => '"$k"').join(',');
      final url = '/word_by_word?unique_key=in.($keys)&order=unique_key,word_number';
      final response = await _apiDio.get(url);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  // Get audio URL for surah from AlQuran Cloud API
  Future<String> getSurahAudioUrl(int surahNumber, {String reciter = 'Abdul_Basit_Murattal'}) async {
    try {
      // Use the correct AlQuran Cloud API endpoint for audio
      final response = await _alquranDio.get('/surah/$surahNumber/$reciter');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200 && data['data'] != null) {
          // Construct the audio URL
          final audioUrl = 'https://cdn.islamic.network/quran/audio-surah/128/$reciter/$surahNumber.mp3';
          return audioUrl;
        }
      }
      throw Exception('Failed to fetch audio for surah $surahNumber');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Get audio URL for verse from AlQuran Cloud API
  Future<String> getVerseAudioUrl(int surahNumber, int verseNumber, {String reciter = 'Abdul_Basit_Murattal'}) async {
    try {
      final response = await _alquranDio.get('/ayah/$surahNumber:$verseNumber/$reciter');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['status'] == true && data['data'] != null) {
          return data['data']['audio'];
        }
      }
      throw Exception('Failed to fetch audio for verse $surahNumber:$verseNumber');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Download file (for audio caching)
  Future<Response> downloadFile(String url, String savePath) async {
    try {
      final response = await _alquranDio.download(url, savePath);
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }



  // Error handling — returns typed exceptions so callers can distinguish offline vs server errors.
  Exception _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.transformTimeout:
        return const NoInternetException();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode != null && statusCode >= 500) {
          return ServerUnavailableException(statusCode: statusCode);
        }
        switch (statusCode) {
          case 400:
            return Exception('Bad request. Please check your input.');
          case 401:
            return Exception('Unauthorized. Please check your credentials.');
          case 403:
            return Exception('Forbidden. You do not have permission to access this resource.');
          case 404:
            return Exception('Resource not found.');
          default:
            return Exception('An error occurred: ${error.message}');
        }
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      case DioExceptionType.badCertificate:
        return const NoInternetException('Сертификати бехатар нест');
      case DioExceptionType.unknown:
        // Check if it is a socket/network-level error
        final msg = error.message ?? '';
        if (msg.contains('SocketException') || msg.contains('Connection refused') || msg.contains('Network')) {
          return const NoInternetException();
        }
        return Exception('An unknown error occurred: ${error.message}');
    }
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class AlQuranCloudException implements Exception {
  final String message;
  AlQuranCloudException(this.message);
  
  @override
  String toString() => message;
}

class AlQuranCloudService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  
  /// Fetches the complete Quran data from AlQuran Cloud API
  Future<Map<String, dynamic>> fetchCompleteQuran() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/quran'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw AlQuranCloudException('Failed to load Quran data: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw AlQuranCloudException('Network is unreachable. Please check your internet connection.');
    } on HttpException catch (e) {
      throw AlQuranCloudException('HTTP error: ${e.message}');
    } on FormatException {
      throw AlQuranCloudException('Invalid response format from server.');
    } catch (e) {
      throw AlQuranCloudException('Unexpected error: $e');
    }
  }
  
  /// Fetches a specific surah by number
  Future<Map<String, dynamic>> fetchSurah(int surahNumber) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/surah/$surahNumber'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw AlQuranCloudException('Failed to load surah $surahNumber: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw AlQuranCloudException('Network is unreachable. Please check your internet connection.');
    } on HttpException catch (e) {
      throw AlQuranCloudException('HTTP error: ${e.message}');
    } on FormatException {
      throw AlQuranCloudException('Invalid response format from server.');
    } catch (e) {
      throw AlQuranCloudException('Unexpected error: $e');
    }
  }
  
  /// Fetches a specific verse by surah and verse number
  Future<Map<String, dynamic>> fetchVerse(int surahNumber, int verseNumber) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/ayah/$surahNumber:$verseNumber'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw AlQuranCloudException('Failed to load verse $surahNumber:$verseNumber: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw AlQuranCloudException('Network is unreachable. Please check your internet connection.');
    } on HttpException catch (e) {
      throw AlQuranCloudException('HTTP error: ${e.message}');
    } on FormatException {
      throw AlQuranCloudException('Invalid response format from server.');
    } catch (e) {
      throw AlQuranCloudException('Unexpected error: $e');
    }
  }
  
  /// Fetches all available editions (translations, reciters, tafsir, etc.)
  Future<Map<String, dynamic>> fetchEditions() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/edition'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw AlQuranCloudException('Failed to load editions: HTTP ${response.statusCode}');
      }
    } on SocketException {
      throw AlQuranCloudException('Network is unreachable. Please check your internet connection.');
    } on HttpException catch (e) {
      throw AlQuranCloudException('HTTP error: ${e.message}');
    } on FormatException {
      throw AlQuranCloudException('Invalid response format from server.');
    } catch (e) {
      throw AlQuranCloudException('Unexpected error: $e');
    }
  }
}

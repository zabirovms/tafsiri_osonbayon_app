import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_constants.dart';

/// Service for accessing Quran page SVGs from Google Cloud Storage
/// Pages are numbered 1-604 (standard Uthmani Mushaf pagination)
class QuranPageSvgService {
  static const String _cloudBasePath = 'quran-pages-svg';
  
  // Singleton pattern
  static final QuranPageSvgService _instance = QuranPageSvgService._internal();
  factory QuranPageSvgService() => _instance;
  QuranPageSvgService._internal();

  /// Get the Google Cloud Storage URL for a page SVG
  /// Returns the public URL (e.g., 'https://storage.googleapis.com/quran-tajik/quran-pages-svg/001.svg')
  String getPageSvgUrl(int pageNumber) {
    if (pageNumber < 1 || pageNumber > 604) {
      throw ArgumentError('Page number must be between 1 and 604');
    }
    final fileName = '${pageNumber.toString().padLeft(3, '0')}.svg';
    return '${AppConstants.gcsBaseUrl}/${AppConstants.gcsBucketName}/$_cloudBasePath/$fileName';
  }

  /// Get page number from verse page field
  /// Returns null if verse doesn't have page information
  int? getPageFromVerse(int? versePage) {
    return versePage;
  }

  /// Get the range of pages for a surah
  /// Returns [startPage, endPage] or null if not available
  List<int>? getSurahPageRange(int? startPage, int? endPage) {
    if (startPage != null && endPage != null) {
      return [startPage, endPage];
    }
    return null;
  }
}



















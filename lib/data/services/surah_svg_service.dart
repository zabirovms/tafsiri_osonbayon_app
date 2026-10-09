/// Service for accessing surah name SVGs from app assets
/// All SVGs are bundled with the app for optimal performance
class SurahSvgService {
  static const String _assetsBasePath = 'assets/svgs/surah_names/';

  // Singleton pattern
  static final SurahSvgService _instance = SurahSvgService._internal();
  factory SurahSvgService() => _instance;
  SurahSvgService._internal();

  /// Get the asset path for a surah's SVG file
  /// Returns the asset path (e.g., 'assets/svgs/surah_names/001.svg')
  String getSurahSvgAssetPath(int surahNumber) {
    final fileName = '${surahNumber.toString().padLeft(3, '0')}.svg';
    return '$_assetsBasePath$fileName';
  }

  /// Get the asset path for circle.svg
  /// Returns the asset path (e.g., 'assets/svgs/surah_names/circle.svg')
  String getCircleSvgAssetPath() {
    return '${_assetsBasePath}circle.svg';
  }
}

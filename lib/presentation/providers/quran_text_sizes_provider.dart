import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/services/settings_service.dart';

/// Quran/settings text sizes (Arabic, translation, transliteration).
/// Used by surah page, Bukhari screens, and invalidated when user changes in Settings.
class QuranTextSizes {
  final double arabic;
  final double translation;
  final double transliteration;

  const QuranTextSizes({
    required this.arabic,
    required this.translation,
    required this.transliteration,
  });

  static QuranTextSizes get defaults => QuranTextSizes(
        arabic: AppConstants.defaultArabicTextSize,
        translation: AppConstants.defaultTranslationTextSize,
        transliteration: AppConstants.defaultTransliterationTextSize,
      );
}

final quranTextSizesProvider = FutureProvider<QuranTextSizes>((ref) async {
  final s = SettingsService();
  await s.init();
  return QuranTextSizes(
    arabic: s.getArabicTextSize(),
    translation: s.getTranslationTextSize(),
    transliteration: s.getTransliterationTextSize(),
  );
});

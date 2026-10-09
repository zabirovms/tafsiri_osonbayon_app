import '../config/api_config.dart';

class AppConstants {
  // App Information
  static const String appName = 'Тафсири Осонбаён';
  static const String appVersion = '1.0.0';
  // Feature flag: UI entry points + routing; see docs/MUSHAF_MODULE_RESTORE_GUIDE.md
  static const bool enableMushafModule = true;
  // Masnavi module stripped from release; see docs/MASNAVI_MODULE_RESTORE_GUIDE.md
  static const bool enableMasnaviModule = false;
  // Support Us Module Flag (Default false so it never flickers before Firebase Remote Config fetches)
  static const bool enableSupportUsModule = true;
  // Support Payment Phone Number
  static const String supportPhoneNumber = '+992988894346';

  // API Configuration - Use ApiConfig for security
  static String get supabaseUrl => ApiConfig.supabaseUrl;
  static String get supabaseAnonKey => ApiConfig.supabaseAnonKey;
  static String get alquranCloudUrl => ApiConfig.alquranCloudUrl;

  // Storage Configuration (Google Cloud Storage)
  static const String gcsBaseUrl = 'https://storage.googleapis.com';
  static const String gcsBucketName = 'quran-tajik';
  static const String backgroundsBasePath = 'backgrounds';
  static const String backgroundsBaseUrl =
      '$gcsBaseUrl/$gcsBucketName/$backgroundsBasePath';

  // Database Configuration
  static const String quranDatabaseName = 'quran.db';
  static const int quranDatabaseVersion = 1;

  // Hive Box Names
  static const String settingsBox = 'settings';
  static const String bookmarksBox = 'bookmarks';
  static const String userPreferencesBox = 'user_preferences';
  static const String searchHistoryBox = 'search_history';
  static const String tasbeehBox = 'tasbeeh';
  static const String wordLearningBox = 'word_learning';
  static const String downloadedTranslationsBox = 'downloaded_translations';
  static const String schedulerBox = 'scheduler';
  static const String prayerTimesBox = 'prayer_times';
  static const String feedbackBox = 'feedback';

  // Audio Configuration
  static const String audioBaseUrl =
      'https://cdn.islamic.network/quran/audio-surah/128/ar.alafasy';
  static const String audioBackupUrl =
      'https://cdn.islamic.network/quran/audio/128/ar.alafasy/surah';

  // Pagination
  static const int versesPerPage = 10;
  static const int searchResultsPerPage = 20;

  // UI Configuration
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Search Configuration
  static const int minSearchLength = 2;
  static const int maxSearchHistory = 50;

  // Tasbeeh Configuration
  static const List<int> defaultTasbeehTargets = [33, 99, 100, 500];
  static const int defaultTasbeehTarget = 33;

  // Word Learning Configuration
  static const int beginnerWordCount = 10;
  static const int intermediateWordCount = 20;
  static const int advancedWordCount = 30;

  // Supported Languages
  static const List<String> supportedLanguages = [
    'tajik_ayati',
    'tajik_alomuddin',
    'tajik_pioneers',
    'tajik_khojamirov',
    'farsi',
    'russian_kuliev',
  ];

  // Default Language
  static const String defaultLanguage = 'tajik_alomuddin'; // Абуаломуддин

  // Tafsir source keys and display names
  static const String tafsirSourceTajik = 'tajik_abu_alomuddin';
  static const String tafsirSourceRuIbnKathir = 'ru_ibn_kathir';

  static String getTafsirSourceName(String sourceKey) {
    switch (sourceKey) {
      case tafsirSourceTajik:
        return 'Тафсири Осонбаёни Абуаломуддин';
      case tafsirSourceRuIbnKathir:
        return 'Тафсир Ибн Касир (русский)';
      default:
        return 'Тафсири Осонбаёни Абуаломуддин';
    }
  }

  // Translation Names
  static String getTranslationName(String languageCode) {
    switch (languageCode) {
      case 'tajik_ayati':
        return 'Абдул Муҳаммад Оятӣ';
      case 'tajik_alomuddin':
        return 'Абуаломуддин';
      case 'tajik_pioneers':
        return 'Pioneers of Translation Center';
      case 'tajik_khojamirov':
        return 'Хоҷамиров';
      case 'farsi':
        return 'Форсӣ';
      case 'russian_kuliev':
        return 'Русӣ (Эльмир Кулиев)';
      default:
        return 'Тоҷикӣ';
    }
  }

  // Font Sizes
  static const double minFontSize = 12.0;
  static const double maxFontSize = 32.0;
  static const double defaultFontSize = 16.0;

  // Surah Page Text Sizes
  static const double defaultArabicTextSize = 26.0;
  static const double defaultTranslationTextSize = 16.0;
  static const double defaultTransliterationTextSize = 14.0;

  // Line Spacing
  static const double minLineSpacing = 1.0;
  static const double maxLineSpacing = 2.5;
  static const double defaultLineSpacing = 1.5;

  // Font Families
  static const String tajikFontFamily = 'NotoSans';
  static const String defaultArabicFontFamily = 'QPC_Hafs';
  static const String englishFontFamily = 'Roboto';
  
  // Available Arabic Quran fonts for user selection:
  static const List<({String key, String label})> arabicFontOptions = [
    (key: 'QPC_Hafs', label: 'QPC Hafs'),
    (key: 'QPC_Hafs_Tajweed', label: 'Таҷвид'),
    (key: 'AlQuranNeov5x1', label: 'Al Quran Neo'),
    (key: 'IndopakNastaleeq', label: 'Indopak Nastaleeq'),
  ];

  /// Get actual .ttf font family for rendering (maps QPC_Hafs_Tajweed -> QPC_Hafs)
  static String getEffectiveFontFamily(String fontKey) {
    if (fontKey == 'QPC_Hafs_Tajweed') return 'QPC_Hafs';
    return fontKey;
  }

  /// Hadith number shown in Settings → text size preview.
  static const int bukhariMenuTextPreviewHadithNumber = 2088;

  // Tajik Surah Names Map
  static const Map<int, String> surahNamesTajik = <int, String>{
    1: 'Ал-Фотиҳа', 2: 'Ал-Бақара', 3: 'Оли Имрон', 4: 'Ан-Нисо', 5: 'Ал-Маида',
    6: 'Ал-Анъом', 7: 'Ал-Аъроф', 8: 'Ал-Анфол', 9: 'Ат-Тавба', 10: 'Юнус',
    11: 'Ҳуд', 12: 'Юсуф', 13: 'Ар-Раъд', 14: 'Иброҳим', 15: 'Ал-Ҳиҷр',
    16: 'Ан-Наҳл', 17: 'Ал-Исро', 18: 'Ал-Каҳф', 19: 'Марям', 20: 'Тоҳо',
    21: 'Ал-Анбиё', 22: 'Ал-Ҳаҷҷ', 23: 'Ал-Муъминун', 24: 'Ан-Нур', 25: 'Ал-Фурқон',
    26: 'Аш-Шуъаро', 27: 'Ан-Намл', 28: 'Ал-Қасас', 29: 'Ал-Анкабут', 30: 'Ар-Рум',
    31: 'Луқмон', 32: 'Ас-Саҷда', 33: 'Ал-Аҳзоб', 34: 'Сабаъ', 35: 'Фотир',
    36: 'Ясин', 37: 'Ас-Соффот', 38: 'Сод', 39: 'Аз-Зумар', 40: 'Ғофир',
    41: 'Фуссилат', 42: 'Аш-Шуро', 43: 'Аз-Зухруф', 44: 'Ад-Духон', 45: 'Ал-Ҷосия',
    46: 'Ал-Аҳқоф', 47: 'Муҳаммад', 48: 'Ал-Фатҳ', 49: 'Ал-Ҳуҷурот', 50: 'Қоф',
    51: 'Аз-Зориёт', 52: 'Ат-Тур', 53: 'Ан-Наҷм', 54: 'Ал-Қамар', 55: 'Ар-Раҳмон',
    56: 'Ал-Воқиа', 57: 'Ал-Ҳадид', 58: 'Ал-Муҷодала', 59: 'Ал-Ҳашр', 60: 'Ал-Мумтаҳана',
    61: 'Ас-Сафф', 62: 'Ал-Ҷумъа', 63: 'Ал-Мунофиқун', 64: 'Ат-Тағобун', 65: 'Ат-Талақ',
    66: 'Ат-Таҳрим', 67: 'Ал-Мулк', 68: 'Ал-Қалам', 69: 'Ал-Ҳоққа', 70: 'Ал-Маъориҷ',
    71: 'Нуҳ', 72: 'Ал-Ҷинн', 73: 'Ал-Муззаммил', 74: 'Ал-Муддассир', 75: 'Ал-Қиёма',
    76: 'Ал-Инсон', 77: 'Ал-Мурсалот', 78: 'Ан-Набоъ', 79: 'Ан-Назиъот', 80: 'Абаса',
    81: 'Ат-Таквир', 82: 'Ал-Инфитор', 83: 'Ал-Мутоффифин', 84: 'Ал-Иншиқоқ', 85: 'Ал-Буруҷ',
    86: 'Ат-Ториқ', 87: 'Ал-Аъло', 88: 'Ал-Ғошия', 89: 'Ал-Фаҷр', 90: 'Ал-Балад',
    91: 'Аш-Шамс', 92: 'Ал-Лайл', 93: 'Ад-Дуҳо', 94: 'Аш-Шарҳ', 95: 'Ат-Тин',
    96: 'Ал-Алақ', 97: 'Ал-Қадр', 98: 'Ал-Баййина', 99: 'Аз-Залзала', 100: 'Ал-Адиёт',
    101: 'Ал-Қориа', 102: 'Ат-Такасур', 103: 'Ал-Аср', 104: 'Ал-Ҳумаза', 105: 'Ал-Фил',
    106: 'Қурайш', 107: 'Ал-Маъун', 108: 'Ал-Кавсар', 109: 'Ал-Кафирун', 110: 'Ан-Наср',
    111: 'Ал-Масад', 112: 'Ал-Ихлос', 113: 'Ал-Фалақ', 114: 'Ан-Нас',
  };

  static String getSurahNameTajik(int surahNumber) {
    return surahNamesTajik[surahNumber] ?? 'Сураи $surahNumber';
  }
}

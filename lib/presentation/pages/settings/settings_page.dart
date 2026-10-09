import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import '../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../data/services/settings_service.dart';

import '../../../data/services/app_rating_service.dart';
import '../../../data/services/tajweed_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/config/feature_badges_config.dart';
import '../../providers/feature_badge_provider.dart';
import '../../../shared/widgets/feature_badge.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/constants/audio_constants.dart';
import '../../widgets/translation_selection_dialog.dart';
import '../../widgets/reciter_selection_dialog.dart';
import '../../widgets/bottom_navigation_bar_widget.dart';
import '../../providers/reciter_provider.dart' show reciterProvider;
import '../../providers/translation_audio_provider.dart' show translationAudioEditionProvider;
import '../../providers/quran_text_sizes_provider.dart' show quranTextSizesProvider;
import '../../../data/services/support_us_service.dart';
import '../../../data/services/storage_stats_service.dart';


// Settings providers
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) => SettingsNotifier());

final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

// App settings model
class AppSettings {
  final String themeMode;
  final String themeAccent;
  final String lightBackgroundStyle;
  final String darkBackgroundStyle;
  final String language;
  final double fontSize;
  final String fontFamily;
  final String arabicFont;
  final bool showTransliteration;
  final bool showTranslation;
  final bool showTafsir;
  final bool audioEnabled;
  final double audioVolume;
  final bool hapticFeedbackEnabled;
  final String reciter;
  final bool autoPlay;
  final bool repeatMode;
  final bool hasSeenPrayerTimesInfo;

  String get effectiveArabicFontFamily => AppConstants.getEffectiveFontFamily(arabicFont);

  AppSettings({
    this.themeMode = 'system',
    this.themeAccent = '#d4a574',
    this.lightBackgroundStyle = 'light_classic',
    this.darkBackgroundStyle = 'dark_oled',
    this.language = 'tajik',
    this.fontSize = 16.0,
    this.fontFamily = 'Roboto',
    this.arabicFont = 'QPC_Hafs',
    this.showTransliteration = true,
    this.showTranslation = true,
    this.showTafsir = true,
    this.audioEnabled = true,
    this.audioVolume = 0.8,
    this.hapticFeedbackEnabled = true,
    this.reciter = 'default',
    this.autoPlay = false,
    this.repeatMode = false,
    this.hasSeenPrayerTimesInfo = false,
  });

  AppSettings copyWith({
    String? themeMode,
    String? themeAccent,
    String? lightBackgroundStyle,
    String? darkBackgroundStyle,
    String? language,
    double? fontSize,
    String? fontFamily,
    String? arabicFont,
    bool? showTransliteration,
    bool? showTranslation,
    bool? showTafsir,
    bool? audioEnabled,
    double? audioVolume,
    bool? hapticFeedbackEnabled,
    String? reciter,
    bool? autoPlay,
    bool? repeatMode,
    bool? hasSeenPrayerTimesInfo,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      themeAccent: themeAccent ?? this.themeAccent,
      lightBackgroundStyle: lightBackgroundStyle ?? this.lightBackgroundStyle,
      darkBackgroundStyle: darkBackgroundStyle ?? this.darkBackgroundStyle,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      arabicFont: arabicFont ?? this.arabicFont,
      showTransliteration: showTransliteration ?? this.showTransliteration,
      showTranslation: showTranslation ?? this.showTranslation,
      showTafsir: showTafsir ?? this.showTafsir,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      audioVolume: audioVolume ?? this.audioVolume,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
      reciter: reciter ?? this.reciter,
      autoPlay: autoPlay ?? this.autoPlay,
      repeatMode: repeatMode ?? this.repeatMode,
      hasSeenPrayerTimesInfo: hasSeenPrayerTimesInfo ?? this.hasSeenPrayerTimesInfo,
    );
  }
}

// Settings notifier
class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(_getInitialSettings());

  static SharedPreferences? _prefs;

  static SharedPreferences? getPrefs() => _prefs;

  static void setPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  static const String _defaultLightAccent = '#d4a574';
  static const String _defaultDarkAccent = '#d4a574';

  static const String _keyTheme = 'theme';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyThemeAccent = 'theme_accent';
  static const String _keyLanguage = 'language';
  static const String _keyFontSize = 'font_size';
  static const String _keyFontFamily = 'font_family';
  static const String _keyArabicFont = 'arabic_font';
  static const String _keyShowTransliteration = 'show_transliteration';
  static const String _keyShowTranslation = 'show_translation';
  static const String _keyShowTafsir = 'show_tafsir';
  static const String _keyAudioEnabled = 'audio_enabled';
  static const String _keyAudioVolume = 'audio_volume';
  static const String _keyHapticFeedbackEnabled = 'haptic_feedback_enabled';
  static const String _keyReciter = 'reciter';
  static const String _keyAutoPlay = 'auto_play';
  static const String _keyRepeatMode = 'repeat_mode';

  static AppSettings _getInitialSettings() {
    final prefs = _prefs;
    if (prefs == null) {
      return AppSettings();
    }

    final legacyTheme = prefs.getString(_keyTheme) ?? 'newLight';
    final storedMode = prefs.getString(_keyThemeMode);
    final storedAccent = prefs.getString(_keyThemeAccent);

    String inferredModeFromLegacy(String v) {
      switch (v) {
        case 'newDark':
        case 'dark':
        case 'nightSky':
          return 'dark';
        case 'system':
          return 'system';
        default:
          return 'light';
      }
    }

    String inferredAccentFromLegacy(String v) {
      switch (v) {
        case 'softBeige':
        case 'elegantMarble':
          return '#78350f';
        case 'nightSky':
          return '#1e293b';
        case 'silverLight':
          return '#475569';
        default:
          return '#d4a574';
      }
    }

    final savedArabicFont = prefs.getString(_keyArabicFont);
    final effectiveArabicFont = (savedArabicFont == null || savedArabicFont == 'QPC_Uthmanic_Hafs' || savedArabicFont == 'AmiriQuran' || savedArabicFont == 'ScheherazadeNew')
        ? 'QPC_Hafs'
        : savedArabicFont;

    if (effectiveArabicFont == 'QPC_Hafs_Tajweed') {
      TajweedService().init();
    }

    return AppSettings(
      themeMode: storedMode ?? inferredModeFromLegacy(legacyTheme),
      themeAccent: storedAccent ?? inferredAccentFromLegacy(legacyTheme),
      lightBackgroundStyle: prefs.getString('light_bg_style') ?? 'light_classic',
      darkBackgroundStyle: prefs.getString('dark_bg_style') ?? 'dark_oled',
      language: prefs.getString(_keyLanguage) ?? 'tajik',
      fontSize: prefs.getDouble(_keyFontSize) ?? 16.0,
      fontFamily: prefs.getString(_keyFontFamily) ?? 'Roboto',
      arabicFont: effectiveArabicFont,
      showTransliteration: prefs.getBool(_keyShowTransliteration) ?? true,
      showTranslation: prefs.getBool(_keyShowTranslation) ?? true,
      showTafsir: prefs.getBool(_keyShowTafsir) ?? true,
      audioEnabled: prefs.getBool(_keyAudioEnabled) ?? true,
      audioVolume: prefs.getDouble(_keyAudioVolume) ?? 0.8,
      hapticFeedbackEnabled: prefs.getBool(_keyHapticFeedbackEnabled) ?? true,
      reciter: prefs.getString(_keyReciter) ?? 'default',
      autoPlay: prefs.getBool(_keyAutoPlay) ?? false,
      repeatMode: prefs.getBool(_keyRepeatMode) ?? false,
      hasSeenPrayerTimesInfo: prefs.getBool('has_seen_prayer_times_info') ?? false,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, state.themeMode);
    await prefs.setString(_keyThemeAccent, state.themeAccent);
    await prefs.setString('light_bg_style', state.lightBackgroundStyle);
    await prefs.setString('dark_bg_style', state.darkBackgroundStyle);
    await prefs.setString(_keyTheme, state.themeMode);
    await prefs.setString(_keyLanguage, state.language);
    await prefs.setDouble(_keyFontSize, state.fontSize);
    await prefs.setString(_keyFontFamily, state.fontFamily);
    await prefs.setString(_keyArabicFont, state.arabicFont);
    await prefs.setBool(_keyShowTransliteration, state.showTransliteration);
    await prefs.setBool(_keyShowTranslation, state.showTranslation);
    await prefs.setBool(_keyShowTafsir, state.showTafsir);
    await prefs.setBool(_keyAudioEnabled, state.audioEnabled);
    await prefs.setDouble(_keyAudioVolume, state.audioVolume);
    await prefs.setBool(_keyHapticFeedbackEnabled, state.hapticFeedbackEnabled);
    await prefs.setString(_keyReciter, state.reciter);
    await prefs.setBool(_keyAutoPlay, state.autoPlay);
    await prefs.setBool(_keyRepeatMode, state.repeatMode);
    await prefs.setBool('has_seen_prayer_times_info', state.hasSeenPrayerTimesInfo);
  }

  void setThemeMode(String themeMode) {
    var nextAccent = state.themeAccent;
    // Keep user custom color untouched; only swap defaults between light/dark.
    if (themeMode == 'dark' && state.themeAccent == _defaultLightAccent) {
      nextAccent = _defaultDarkAccent;
    } else if (themeMode == 'light' && state.themeAccent == _defaultDarkAccent) {
      nextAccent = _defaultLightAccent;
    }
    state = state.copyWith(themeMode: themeMode, themeAccent: nextAccent);
    _saveSettings();
  }

  void setThemeAccent(String themeAccent) {
    state = state.copyWith(themeAccent: themeAccent);
    _saveSettings();
  }

  void setLightBackgroundStyle(String style) {
    state = state.copyWith(lightBackgroundStyle: style);
    _saveSettings();
  }

  void setDarkBackgroundStyle(String style) {
    state = state.copyWith(darkBackgroundStyle: style);
    _saveSettings();
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
    _saveSettings();
  }

  void setFontSize(double fontSize) {
    state = state.copyWith(fontSize: fontSize);
    _saveSettings();
  }

  void setFontFamily(String fontFamily) {
    state = state.copyWith(fontFamily: fontFamily);
    _saveSettings();
  }

  void setArabicFont(String font) {
    state = state.copyWith(arabicFont: font);
    _saveSettings();
    if (font == 'QPC_Hafs_Tajweed') {
      TajweedService().init();
    }
  }

  void setShowTransliteration(bool show) {
    state = state.copyWith(showTransliteration: show);
    _saveSettings();
  }

  void setShowTranslation(bool show) {
    state = state.copyWith(showTranslation: show);
    _saveSettings();
  }

  void setShowTafsir(bool show) {
    state = state.copyWith(showTafsir: show);
    _saveSettings();
  }

  void setAudioEnabled(bool enabled) {
    state = state.copyWith(audioEnabled: enabled);
    _saveSettings();
  }

  void setAudioVolume(double volume) {
    state = state.copyWith(audioVolume: volume);
    _saveSettings();
  }

  void setHapticFeedbackEnabled(bool enabled) {
    state = state.copyWith(hapticFeedbackEnabled: enabled);
    _saveSettings();
  }

  void setReciter(String reciter) {
    state = state.copyWith(reciter: reciter);
    _saveSettings();
  }

  void setAutoPlay(bool enabled) {
    state = state.copyWith(autoPlay: enabled);
    _saveSettings();
  }

  void setRepeatMode(bool enabled) {
    state = state.copyWith(repeatMode: enabled);
    _saveSettings();
  }

  void setHasSeenPrayerTimesInfo(bool value) {
    state = state.copyWith(hasSeenPrayerTimesInfo: value);
    _saveSettings();
  }

  Future<void> resetToDefaults() async {
    state = AppSettings();
    await _saveSettings();
  }
}

/// Section title aligned with Sahih Bukhari app menu (primary, compact).
Widget _settingsSectionHeader(BuildContext context, String title) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        color: cs.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

/// Collapsible block (Quran options, sources, etc.) for a shorter first view.
class _ExpandableSettingsGroup extends ConsumerStatefulWidget {
  const _ExpandableSettingsGroup({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.expandedBuilder,
    this.featureId,
  });

  final IconData leading;
  final String title;
  final String subtitle;
  final Widget Function() expandedBuilder;
  final String? featureId;

  @override
  ConsumerState<_ExpandableSettingsGroup> createState() => _ExpandableSettingsGroupState();
}

class _ExpandableSettingsGroupState extends ConsumerState<_ExpandableSettingsGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showBadge = widget.featureId != null &&
        ref.watch(featureBadgeVisibleProvider(widget.featureId!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(widget.leading, color: cs.primary),
          title: Row(
            children: [
              Text(widget.title),
              if (showBadge) ...[
                const SizedBox(width: 8),
                const BadgeLabel(text: 'НАВ'),
              ],
            ],
          ),
          subtitle: Text(widget.subtitle),
          trailing: Icon(
            _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: cs.onSurfaceVariant,
          ),
          onTap: () => setState(() => _expanded = !_expanded),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: widget.expandedBuilder(),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});
  static const String _kQuranAppPackageId = 'com.quran.tj.quranapp';
  static const String _kQuranAppPlayUrl =
      'https://play.google.com/store/apps/details?id=$_kQuranAppPackageId';
  static const String _kBukhariPackageId = 'com.quran.tj.bukhari';
  static const String _kBukhariPlayUrl =
      'https://play.google.com/store/apps/details?id=$_kBukhariPackageId';
  static const String _kDuasPackageId = 'com.quran.tj.dua';
  static const String _kDuasPlayUrl =
      'https://play.google.com/store/apps/details?id=$_kDuasPackageId';
  static const String _kMasnaviPackageId = 'com.masnavi.tj.masnavi';
  static const String _kMasnaviPlayUrl =
      'https://play.google.com/store/apps/details?id=$_kMasnaviPackageId';
  static const String _kJahondonUrl = 'https://geo.quran.tj';

  static const String _kYaqeenLogoAsset = 'assets/images/covers/yaqeen.png';
  static const String _kBukhariLogoAsset = 'assets/images/covers/bukhari.png';
  static const String _kDuasLogoAsset = 'assets/images/covers/duas.png';
  static const String _kMasnaviLogoAsset = 'assets/images/covers/masnavi.jpg';
  static const String _kJahondonLogoAsset = 'assets/images/covers/jahondon.jpg';


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final packageInfoAsync = ref.watch(packageInfoProvider);

    return Scaffold(
      // Removed extendBody to ensure content never goes under system navigation bar
      appBar: AppBar(
        title: const Text('Танзимот'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            try {
              if (GoRouter.of(context).canPop()) {
                GoRouter.of(context).pop();
              } else {
                GoRouter.of(context).go('/');
              }
            } catch (e) {
              GoRouter.of(context).go('/');
            }
          },
        ),
      ),
      bottomNavigationBar: const BottomNavigationBarWidget(),
      body: SafeArea(
        top: true,
        bottom: true,
        left: false,
        right: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 8),
          children: [
            _settingsSectionHeader(context, 'Намоиш'),
            _buildThemeSetting(settings, ref, context),
            const Divider(height: 12),
            _settingsSectionHeader(context, 'Қуръон'),
            _ExpandableSettingsGroup(
              featureId: FeatureBadges.quranSettingsGroup,
              leading: Icons.menu_book_rounded,
              title: 'Танзимоти саҳифаи Қуръон',
              subtitle: 'Забон, қорӣ, андозаи матн ва ғ.',
              expandedBuilder: () => const _QuranSettingsSection(),
            ),

            const Divider(height: 12),
            _settingsSectionHeader(context, 'Хотира ва кэш'),
            const _ExpandableSettingsGroup(
              leading: Icons.storage_rounded,
              title: 'Идоракунии хотира',
              subtitle: 'Истифодаи хотира ва пок кардани кэш',
              expandedBuilder: _StorageSettingsSection.new,
            ),


            const Divider(height: 24),
            ..._buildOurAppsSection(context),
            const Divider(height: 24),
            ..._buildSupportSection(context, ref),
            const Divider(height: 24),
            _settingsSectionHeader(context, 'Тамос бо мо'),
            _buildSocialLinksSection(context),
            const Divider(height: 24),
            _settingsSectionHeader(context, 'Мо дар'),
            _buildOurPresenceSection(context),
            const Divider(height: 24),
            _settingsSectionHeader(context, 'Манбаъҳо'),
            _ExpandableSettingsGroup(
              leading: Icons.cloud_done_rounded,
              title: 'Манбаъҳо',
              subtitle: 'AlQuran Cloud, Tanzil, CDN Islamic Network ва ғ.',
              expandedBuilder: () => _buildSpecialThanksSection(context),
            ),
            packageInfoAsync.when(
              data: (packageInfo) => _buildVersionWidget(context, packageInfo),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionWidget(BuildContext context, PackageInfo packageInfo) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppConstants.appName,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Версияи ${packageInfo.version} (${packageInfo.buildNumber})',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildThemeSetting(AppSettings settings, WidgetRef ref, BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final notifier = ref.read(settingsProvider.notifier);
    final selectedMode = settings.themeMode;
    final selectedAccent = settings.themeAccent;
    final systemDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final effectiveDark = switch (selectedMode) {
      'dark' => true,
      'light' => false,
      _ => systemDark,
    };

    final accentOptions = <(String id, Color color)>[
      ('#d4a574', const Color(0xFFD4A574)),
      ('#16697a', const Color(0xFF16697A)),
      ('#334155', const Color(0xFF334155)),
      ('#c6ac42', const Color(0xFFC6AC42)),
      ('#1e293b', const Color(0xFF1E293B)),
      ('#27272a', const Color(0xFF27272A)),
      ('#78350f', const Color(0xFF78350F)),
      ('#475569', const Color(0xFF475569)),
      ('#06b6d4', const Color(0xFF06B6D4)),
      ('#6b9080', const Color(0xFF6B9080)),
      ('#fda4af', const Color(0xFFFDA4AF)),
      ('#fbcfe8', const Color(0xFFFBCFE8)),
      ('#78716c', const Color(0xFF78716C)),
      ('#0f766e', const Color(0xFF0F766E)),
    ];

    final accentColor = accentOptions.firstWhere(
      (option) => option.$1 == selectedAccent,
      orElse: () => accentOptions.first,
    ).$2;

    final targetLightTheme = AppTheme.lightFromAccent(accentColor, backgroundStyle: settings.lightBackgroundStyle);
    final targetDarkTheme = AppTheme.darkFromAccent(accentColor, backgroundStyle: settings.darkBackgroundStyle);

    // Light and Dark background paper style presets for Eye Protection & Comfort
    final lightBgOptions = [
      ('light_classic', 'Классикӣ (Стандартӣ)', const Color(0xFFF4F3F0), const Color(0xFF1A1917)),
      ('light_sepia', 'Сепия (Муҳофизати чашм - Гарм)', const Color(0xFFFBF0D9), const Color(0xFF3E2723)),
      ('light_amber', 'Янтарӣ (Муҳофизати чашм - Мулоим)', const Color(0xFFFAF0E6), const Color(0xFF3B2F2F)),
      ('light_mint', 'Зайтунӣ (Сабзи роҳатбахш)', const Color(0xFFEAF5ED), const Color(0xFF1B3B2B)),
      ('light_sand', 'Реги саҳро (Ором)', const Color(0xFFF5EBE0), const Color(0xFF382D26)),
      ('light_slate', 'Нуқрагӣ (Сард)', const Color(0xFFF1F5F9), const Color(0xFF0F172A)),
      ('light_rose', 'Шафақ (Мулоим)', const Color(0xFFFFF0F2), const Color(0xFF3D2529)),
    ];

    final darkBgOptions = [
      ('dark_oled', 'ОПИАТ (Сиёҳи мутлақ)', const Color(0xFF09090B), const Color(0xFFF3F4F6)),
      ('dark_coffee', 'Қаҳваранг (Муҳофизати чашм - Гарм)', const Color(0xFF181210), const Color(0xFFF5EBE6)),
      ('dark_navy', 'Осмони Шаб (Нилии ором)', const Color(0xFF0B1325), const Color(0xFFE2E8F0)),
      ('dark_emerald', 'Зумрад (Сабзи торик)', const Color(0xFF061D17), const Color(0xFFE6F4F1)),
      ('dark_charcoal', 'Ангиштӣ (Мулоим)', const Color(0xFF161618), const Color(0xFFF0F0F2)),
      ('dark_plum', 'Шафақи торик (Бунафш)', const Color(0xFF140E1B), const Color(0xFFF1EAF8)),
    ];

    final activeBgOptions = effectiveDark ? darkBgOptions : lightBgOptions;
    final activeStyleKey = effectiveDark ? settings.darkBackgroundStyle : settings.lightBackgroundStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(effectiveDark ? 'Торик' : 'Равшан'),
          trailing: _AnimatedThemeSwitch(
            initialValue: effectiveDark,
            targetLightTheme: targetLightTheme,
            targetDarkTheme: targetDarkTheme,
            onModeChanged: (isDark) {
              notifier.setThemeMode(isDark ? 'dark' : 'light');
            },
          ),
        ),
        const SizedBox(height: 4),

        // Background Paper Style Selector Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Услуби пасманзар',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: activeBgOptions.map((option) {
                final (key, label, scaffoldColor, textColor) = option;
                final isSelected = activeStyleKey == key;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Tooltip(
                    message: label,
                    child: ThemeSwitcher(
                      clipper: const ThemeSwitcherCircleClipper(),
                      builder: (context) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            final newTheme = effectiveDark
                                ? AppTheme.darkFromAccent(accentColor, backgroundStyle: key)
                                : AppTheme.lightFromAccent(accentColor, backgroundStyle: key);
                            ThemeSwitcher.of(context).changeTheme(
                              theme: newTheme,
                              onAnimationFinish: () {
                                if (effectiveDark) {
                                  notifier.setDarkBackgroundStyle(key);
                                } else {
                                  notifier.setLightBackgroundStyle(key);
                                }
                              },
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: scaffoldColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? accentColor : cs.outlineVariant,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    size: 18,
                                    color: textColor,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 4),

        // Accent Colors Selector Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            'Ранги тугмаҳо',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: accentOptions.map((option) {
                final isSelected = selectedAccent == option.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ThemeSwitcher(
                    clipper: const ThemeSwitcherCircleClipper(),
                    builder: (context) {
                      return InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () {
                          final newTheme = effectiveDark
                              ? AppTheme.darkFromAccent(option.$2, backgroundStyle: settings.darkBackgroundStyle)
                              : AppTheme.lightFromAccent(option.$2, backgroundStyle: settings.lightBackgroundStyle);
                          ThemeSwitcher.of(context).changeTheme(
                            theme: newTheme,
                            onAnimationFinish: () {
                              notifier.setThemeAccent(option.$1);
                            },
                          );
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: option.$2,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? cs.onSurface : cs.outlineVariant,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 18,
                                  color: option.$2.computeLuminance() > 0.55
                                      ? Colors.black
                                      : Colors.white,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // Removed font size setting

  // Removed font family setting


  // Removed audio enabled toggle


  // Removed reciter single-tile and bottom-sheet entry; showing inline instead

  Widget _appLogoAvatar(String assetPath, ColorScheme cs) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: cs.surface,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ClipOval(
          child: Image.asset(
            assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Icon(
              Icons.apps_rounded,
              size: 18,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOurAppsSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          'Барномаҳои мо',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      ListTile(
        leading: _appLogoAvatar(_kYaqeenLogoAsset, cs),
        title: const Text('Яқин'),
        trailing: Icon(Icons.open_in_new_rounded, color: cs.onSurfaceVariant),
        onTap: () => _openPlayListingByPackageId(
          context,
          _kQuranAppPackageId,
          _kQuranAppPlayUrl,
        ),
      ),
      ListTile(
        leading: _appLogoAvatar(_kBukhariLogoAsset, cs),
        title: const Text('Саҳеҳи Бухорӣ'),
        trailing: Icon(Icons.open_in_new_rounded, color: cs.onSurfaceVariant),
        onTap: () => _openPlayListingByPackageId(
          context,
          _kBukhariPackageId,
          _kBukhariPlayUrl,
        ),
      ),
      ListTile(
        leading: _appLogoAvatar(_kMasnaviLogoAsset, cs),
        title: const Text('Осори ниёгон'),
        trailing: Icon(Icons.open_in_new_rounded, color: cs.onSurfaceVariant),
        onTap: () => _openPlayListingByPackageId(
          context,
          _kMasnaviPackageId,
          _kMasnaviPlayUrl,
        ),
      ),
      ListTile(
        leading: _appLogoAvatar(_kJahondonLogoAsset, cs),
        title: const Text('Ҷаҳондон'),
        subtitle: const Text('geo.quran.tj', style: TextStyle(fontSize: 12)),
        trailing: Icon(Icons.open_in_new_rounded, color: cs.onSurfaceVariant),
        onTap: () => _openUrl(_kJahondonUrl),
      ),
      ListTile(
        leading: _appLogoAvatar(_kDuasLogoAsset, cs),
        title: const Text('Зикру дуоҳо'),
        trailing: Icon(Icons.open_in_new_rounded, color: cs.onSurfaceVariant),
        onTap: () => _openPlayListingByPackageId(
          context,
          _kDuasPackageId,
          _kDuasPlayUrl,
        ),
      ),
    ];
  }

  List<Widget> _buildSupportSection(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final supportEnabled = ref.watch(supportUsEnabledProvider);

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Text(
          'Дастгирӣ кунед',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      ListTile(
        leading: Icon(Icons.star_rate_rounded, color: cs.primary),
        title: const Text('Баҳо додан'),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: _openPlayStore,
      ),
      ListTile(
        leading: Icon(Icons.share_rounded, color: cs.primary),
        title: const Text('Мубодила кардан'),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: () => _shareApp(context),
      ),
      if (supportEnabled)
        ListTile(
          leading: Icon(Icons.favorite_rounded, color: cs.primary),
          title: Row(
            children: [
              const Text('Дастгирии молиявӣ'),
              if (ref.watch(featureBadgeVisibleProvider(FeatureBadges.supportUs))) ...[
                const SizedBox(width: 8),
                const BadgeLabel(text: 'НАВ'),
              ],
            ],
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          onTap: () {
            ref.read(badgeControllerProvider).markSeen(FeatureBadges.supportUs);
            GoRouter.of(context).push('/support-us');
          },
        ),
      ListTile(
        leading: Icon(Icons.system_update_rounded, color: cs.primary),
        title: const Text('Навсозии барнома'),
        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: _openPlayStore,
      ),
    ];
  }

  Widget _buildSpecialThanksSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final externalTrailing = Icon(Icons.open_in_new_rounded, color: cs.onSurfaceVariant, size: 22);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.cloud_outlined, color: cs.primary),
          title: const Text('AlQuran Cloud'),
          subtitle: const Text('Матни Қуръон ва тарҷумаҳо'),
          trailing: externalTrailing,
          onTap: () => _openUrl('https://alquran.cloud/'),
        ),
        ListTile(
          leading: Icon(Icons.public_rounded, color: cs.primary),
          title: const Text('Tanzil.net'),
          subtitle: const Text('Матни Қуръон ва тарҷумаҳо'),
          trailing: externalTrailing,
          onTap: () => _openUrl('https://tanzil.net/'),
        ),
        ListTile(
          leading: Icon(Icons.audio_file_outlined, color: cs.primary),
          title: const Text('CDN Islamic Network'),
          subtitle: const Text('Аудиоҳои Қуръон'),
          trailing: externalTrailing,
          onTap: () => _openUrl('https://alquran.cloud/cdn'),
        ),
        ListTile(
          leading: Icon(Icons.person_outline_rounded, color: cs.onSurfaceVariant),
          title: const Text('Абуаломуддин'),
          subtitle: const Text('Тафсири осонбаён — муаллиф ва мутарҷим'),
          onTap: null,
          enabled: false,
        ),
        ListTile(
          leading: Icon(Icons.menu_book_outlined, color: cs.primary),
          title: const Text('Quranic Universal Library'),
          subtitle: const Text('Тарҷумаи калима ба калима'),
          trailing: externalTrailing,
          onTap: () => _openUrl('https://qul.tarteel.ai/'),
        ),
        ListTile(
          leading: Icon(Icons.link_outlined, color: cs.onSurfaceVariant),
          title: const Text('Дигар манбаъҳо'),
          subtitle: const Text('Ҳама дигар манбаъҳои онлайн'),
          onTap: null,
          enabled: false,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Ҳамаи ҳуқуқҳо ба муаллифон ва манбаъҳои мутобиқ тааллуқ доранд. Маводҳо дар ин барнома аз манбаъҳои гуногун ҷамъоварӣ шудаанд.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLinksSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final externalTrailing = Icon(Icons.open_in_new_rounded, color: cs.onSurfaceVariant, size: 22);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.instagram, color: Color(0xFFE4405F)),
          title: const Text('Инстаграм'),
          subtitle: const Text('app.quran.tj'),
          trailing: externalTrailing,
          onTap: () => _openUrl('https://www.instagram.com/app.quran.tj'),
        ),
        ListTile(
          leading: Icon(Icons.email_outlined, color: cs.primary),
          title: const Text('Почта'),
          subtitle: const Text('info@quran.tj'),
          trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          onTap: () => _openEmail(context, 'info@quran.tj'),
        ),
        ListTile(
          leading: Icon(Icons.rate_review_outlined, color: cs.primary),
          title: const Text('Фикру мулоҳизаҳо'),
          subtitle: const Text('Пешниҳод ё гузориши хатогӣ'),
          trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
          onTap: () => GoRouter.of(context).push('/feedback?source=settings'),
        ),
      ],
    );
  }

  Widget _buildOurPresenceSection(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final externalTrailing = Icon(Icons.open_in_new_rounded, color: cs.onSurfaceVariant, size: 22);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.youtube, color: Color(0xFFFF0000)),
          title: const Text('YouTube'),
          subtitle: const Text('Balkhiverse'),
          trailing: externalTrailing,
          onTap: () => _openUrl('https://www.youtube.com/@balkhiverse'),
        ),
        ListTile(
          leading: Icon(Icons.language_rounded, color: cs.primary),
          title: const Text('Вебсайт'),
          subtitle: const Text('www.quran.tj'),
          trailing: externalTrailing,
          onTap: () => _openUrl('https://www.quran.tj'),
        ),
        ListTile(
          leading: const FaIcon(FontAwesomeIcons.instagram, color: Color(0xFFE4405F)),
          title: const Text('Инстаграм'),
          subtitle: const Text('balkhiverse'),
          trailing: externalTrailing,
          onTap: () => _openUrl('https://www.instagram.com/balkhiverse/'),
        ),
      ],
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (kDebugMode) {
        debugPrint('Could not launch $url');
      }
    }
  }

  Future<void> _openPlayStore() async {
    await AppRatingService.openStoreListing();
  }

  Future<void> _openPlayListingByPackageId(
    BuildContext context,
    String packageId,
    String httpsPlayUrl,
  ) async {
    final appUri = Uri.parse('market://details?id=$packageId');
    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
      return;
    }
    await _openUrl(httpsPlayUrl);
  }

  Future<void> _shareApp(BuildContext context) async {
    const appName = AppConstants.appName;
    const appDescription = 'Барномаи комил барои хондани Қуръон бо тафсири осонбаён';
    final String storeUrl;
    if (Platform.isIOS) {
      storeUrl = 'https://apps.apple.com/app/id6787344485';
    } else {
      storeUrl = 'https://play.google.com/store/apps/details?id=com.quran.tj.osonbayon';
    }
    
    final shareText = '$appName\n$appDescription\n\n$storeUrl';
    
    try {
      final box = context.findRenderObject() as RenderBox?;
      await Share.share(
        shareText,
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );
    } catch (e) {
      if (context.mounted && kDebugMode) {
        debugPrint('Error sharing app: $e');
      }
    }
  }

  Future<void> _openEmail(BuildContext context, String email) async {
    try {
      // URL encode the subject properly
      final subject = Uri.encodeComponent('Тамос бо барномаи Қуръон');
      final uri = Uri.parse('mailto:$email?subject=$subject');
      
      // Try to launch email app
      if (await canLaunchUrl(uri)) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return; // Success, exit early
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error launching email with subject: $e');
          }
          // Fallback: try without subject
          final fallbackUri = Uri.parse('mailto:$email');
          if (await canLaunchUrl(fallbackUri)) {
            try {
              await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
              return; // Success with fallback
            } catch (e2) {
              if (kDebugMode) {
                debugPrint('Error launching email without subject: $e2');
              }
            }
          }
        }
      }
      
      // If we reach here, no email app is available
      // Fallback: copy email to clipboard and show message
      await Clipboard.setData(ClipboardData(text: email));
      if (context.mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: 'Суроғаи почта нусхабардорӣ карда шуд: $email',
          duration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error opening email: $e');
      }
      // Last resort: show email in a dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Тамос'),
            content: Text('Суроғаи почта: $email'),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: email));
                  Navigator.of(context).pop();
                  if (context.mounted) {
                    SnackBarHelper.showSuccess(
                      context: context,
                      message: 'Суроғаи почта нусхабардорӣ карда шуд',
                      duration: const Duration(seconds: 2),
                    );
                  }
                },
                child: const Text('Нусхабардорӣ'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Пӯшидан'),
              ),
            ],
          ),
        );
      }
    }
  }






}

/// Quran display/reading settings (same as surah page top bar settings).
class _QuranSettingsSection extends ConsumerStatefulWidget {
  const _QuranSettingsSection();

  @override
  ConsumerState<_QuranSettingsSection> createState() => _QuranSettingsSectionState();
}

class _QuranSettingsSectionState extends ConsumerState<_QuranSettingsSection> {
  late String _translationLang;
  late String _audioEdition;
  late bool _showArabic;
  late bool _showTafsir;
  late bool _wordByWordMode;
  late double _arabicTextSize;
  late double _translationTextSize;
  late double _transliterationTextSize;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _translationLang = AppConstants.defaultLanguage;
    _audioEdition = AudioConstants.defaultReciter;
    _showArabic = true;
    _showTafsir = true;
    _wordByWordMode = false;
    _arabicTextSize = AppConstants.defaultArabicTextSize;
    _translationTextSize = AppConstants.defaultTranslationTextSize;
    _transliterationTextSize = AppConstants.defaultTransliterationTextSize;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final s = SettingsService();
    await s.init();
    if (!mounted) return;
    setState(() {
      _translationLang = s.getTranslationLanguage();
      _audioEdition = s.getAudioEdition();
      _showArabic = s.getShowArabic();
      _showTafsir = s.getShowTafsir();
      _wordByWordMode = s.getWordByWordMode();
      _arabicTextSize = s.getArabicTextSize();
      _translationTextSize = s.getTranslationTextSize();
      _transliterationTextSize = s.getTransliterationTextSize();
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.translate, color: cs.primary),
          title: const Text('Забони тарҷума'),
          subtitle: Text(AppConstants.getTranslationName(_translationLang)),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: cs.onSurfaceVariant,
          ),
          onTap: () async {
            final newLang = await showDialog<String>(
              context: context,
              builder: (ctx) => TranslationSelectionDialog(
                currentTranslation: _translationLang,
              ),
            );
            if (newLang != null && mounted) setState(() => _translationLang = newLang);
          },
        ),
        Consumer(
          builder: (context, ref, _) {
            final qariId = _audioEdition;
            final isTranslation = !qariId.startsWith('ar.');
            final reciter = isTranslation ? null : ref.watch(reciterProvider(qariId));
            final translation = isTranslation ? ref.watch(translationAudioEditionProvider(qariId)) : null;
            final displayName = isTranslation
                ? (translation?.name ?? 'Тарҷума')
                : (reciter != null
                    ? (reciter.nameTajik.isNotEmpty && reciter.nameTajik != reciter.id
                        ? reciter.nameTajik
                        : (reciter.name.isNotEmpty && reciter.name != reciter.id
                            ? reciter.name
                            : 'Қорӣ'))
                    : 'Қорӣ');
            return ListTile(
              leading: Icon(Icons.record_voice_over, color: cs.primary),
              title: const Text('Қорӣ'),
              subtitle: Text(displayName),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: cs.onSurfaceVariant,
              ),
              onTap: () async {
                final selected = await showDialog<String>(
                  context: context,
                  builder: (ctx) => ReciterSelectionDialog(currentReciterId: _audioEdition),
                );
                if (selected != null && mounted) setState(() => _audioEdition = selected);
              },
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.font_download_rounded, color: cs.primary),
          title: const Text('Шрифти Қуръон'),
          subtitle: Text(
            AppConstants.arabicFontOptions.firstWhere(
              (o) => o.key == settings.arabicFont,
              orElse: () => AppConstants.arabicFontOptions.first,
            ).label,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: cs.onSurfaceVariant,
          ),
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Шрифти Қуръонро интихоб кунед'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AppConstants.arabicFontOptions.map((option) {
                    return RadioListTile<String>(
                      title: Text(
                        option.label,
                        style: TextStyle(
                          fontFamily: AppConstants.getEffectiveFontFamily(option.key),
                          fontSize: 18,
                        ),
                      ),
                      value: option.key,
                      groupValue: settings.arabicFont,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(settingsProvider.notifier).setArabicFont(value);
                          Navigator.pop(ctx);
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          secondary: Icon(Icons.menu_book_rounded, color: cs.primary),
          title: const Text('Намоиши матни арабӣ'),
          value: _showArabic,
          onChanged: (value) async {
            setState(() {
              _showArabic = value;
            });
            final s = SettingsService();
            await s.init();
            await s.setShowArabic(value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.auto_stories_rounded, color: cs.primary),
          title: const Text('Намоиши тафсир'),
          value: _showTafsir,
          onChanged: (value) async {
            setState(() {
              _showTafsir = value;
            });
            final s = SettingsService();
            await s.init();
            await s.setShowTafsir(value);
          },
        ),
        SwitchListTile(
          secondary: Icon(Icons.format_list_bulleted, color: cs.primary),
          title: const Text('Ҳолати калима ба калима'),
          value: _wordByWordMode,
          onChanged: (value) async {
            setState(() {
              _wordByWordMode = value;
            });
            final s = SettingsService();
            await s.init();
            await s.setWordByWordMode(value);
          },
        ),
        const SizedBox(height: 16),
        // Match ListTile horizontal inset — sliders were full-bleed after card layout removal.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Андозаи матн',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildTextSizeSlider(
                context,
                'Матни арабӣ',
                _arabicTextSize,
                14,
                32,
                onChanged: (v) => setState(() => _arabicTextSize = v),
                onChangeEnd: (v) async {
                  final s = SettingsService();
                  await s.init();
                  await s.setArabicTextSize(v);
                  if (mounted) ref.invalidate(quranTextSizesProvider);
                },
              ),
              const SizedBox(height: 8),
              _buildTextSizeSlider(
                context,
                'Тарҷума',
                _translationTextSize,
                12,
                24,
                onChanged: (v) => setState(() => _translationTextSize = v),
                onChangeEnd: (v) async {
                  final s = SettingsService();
                  await s.init();
                  await s.setTranslationTextSize(v);
                  if (mounted) ref.invalidate(quranTextSizesProvider);
                },
              ),
              const SizedBox(height: 8),
              _buildTextSizeSlider(
                context,
                'Транслитератсия',
                _transliterationTextSize,
                10,
                20,
                onChanged: (v) => setState(() => _transliterationTextSize = v),
                onChangeEnd: (v) async {
                  final s = SettingsService();
                  await s.init();
                  await s.setTransliterationTextSize(v);
                  if (mounted) ref.invalidate(quranTextSizesProvider);
                },
              ),
              const SizedBox(height: 16),
              _buildTextSizePreview(context, theme),
              const SizedBox(height: 16),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    setState(() {
                      _arabicTextSize = AppConstants.defaultArabicTextSize;
                      _translationTextSize = AppConstants.defaultTranslationTextSize;
                      _transliterationTextSize = AppConstants.defaultTransliterationTextSize;
                    });
                    final s = SettingsService();
                    await s.init();
                    await s.resetTextSizesToDefaults();
                    if (mounted) ref.invalidate(quranTextSizesProvider);
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Барқарор кардани андозаи пешфарз'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Қуръон 20:114
  static const String _previewTransliteration = 'Ва қур-Рабби зиднӣ ъилма.';
  static const String _previewTranslation = 'Ва бигӯ: «Эй Парвардигори ман, ба илми ман бияфзой».';

  Widget _buildTextSizePreview(BuildContext context, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Пешнамоиш',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Text.rich(
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.start,
                TextSpan(
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: _arabicTextSize,
                    height: 1.5,
                    color: theme.colorScheme.onSurface,
                    fontFamily: AppConstants.getEffectiveFontFamily(ref.watch(settingsProvider).arabicFont),
                  ),
                  children: const [
                    TextSpan(text: 'وَقُل رَّبِّ زِدْنِي عِلْمًا'),
                    TextSpan(
                      text: ' ١١٤',
                      style: TextStyle(fontFamily: 'QPC_Hafs'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _previewTransliteration,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: _transliterationTextSize,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 6),
            Text(
              _previewTranslation,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: _translationTextSize,
                color: theme.colorScheme.onSurface,
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSizeSlider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max, {
    required void Function(double) onChanged,
    void Function(double)? onChangeEnd,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).round(),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text('${value.round()}', style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _AnimatedThemeSwitch extends StatefulWidget {
  const _AnimatedThemeSwitch({
    required this.initialValue,
    required this.targetLightTheme,
    required this.targetDarkTheme,
    required this.onModeChanged,
  });

  final bool initialValue;
  final ThemeData targetLightTheme;
  final ThemeData targetDarkTheme;
  final Function(bool) onModeChanged;

  @override
  State<_AnimatedThemeSwitch> createState() => _AnimatedThemeSwitchState();
}

class _AnimatedThemeSwitchState extends State<_AnimatedThemeSwitch> {
  late bool _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  void didUpdateWidget(covariant _AnimatedThemeSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _currentValue = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ThemeSwitcher(
      clipper: const ThemeSwitcherCircleClipper(),
      builder: (context) {
        return Switch(
          value: _currentValue,
          onChanged: (isDark) {
            setState(() {
              _currentValue = isDark;
            });
            ThemeSwitcher.of(context).changeTheme(
              theme: isDark ? widget.targetDarkTheme : widget.targetLightTheme,
              isReversed: !isDark,
              onAnimationFinish: () {
                widget.onModeChanged(isDark);
              },
            );
          },
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return cs.primary;
            }
            return cs.primary.withValues(alpha: 0.35);
          }),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return cs.onPrimary;
            }
            return cs.primary;
          }),
          thumbIcon: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Icon(Icons.light_mode_rounded, size: 16, color: cs.primary);
            }
            return Icon(Icons.dark_mode_rounded, size: 16, color: cs.onPrimary);
          }),
        );
      },
    );
  }
}

class _StorageSettingsSection extends ConsumerWidget {
  const _StorageSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final breakdownAsync = ref.watch(storageBreakdownProvider);

    return breakdownAsync.when(
      data: (breakdown) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStorageItem(
                context,
                icon: Icons.storage_rounded,
                title: 'Базаи маълумот ва файлҳои барнома',
                sizeFormatted: breakdown.databaseSizeFormatted,
                subtitle: 'Матни Қуръон, тарҷумаҳо ва тафсир',
              ),
              const SizedBox(height: 12),
              _buildStorageItem(
                context,
                icon: Icons.audiotrack_rounded,
                title: 'Кэши аудиои сураҳо',
                sizeFormatted: breakdown.audioCacheSizeFormatted,
                subtitle: 'Файлҳои аудиои муваққатӣ',
              ),
              const SizedBox(height: 12),
              _buildStorageItem(
                context,
                icon: Icons.image_rounded,
                title: 'Кэши расмҳо',
                sizeFormatted: breakdown.imageCacheSizeFormatted,
                subtitle: 'Муқоваҳо ва манбаъҳои шабакавӣ',
              ),
              if (breakdown.downloadedAudioSizeBytes > 0) ...[
                const SizedBox(height: 12),
                _buildStorageItem(
                  context,
                  icon: Icons.download_done_rounded,
                  title: 'Аудиоҳои боргиришуда',
                  sizeFormatted: breakdown.downloadedAudioSizeFormatted,
                  subtitle: 'Сураҳои офлайн боргиришуда',
                ),
              ],
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ҷамъи хотира:',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    breakdown.totalAppSizeFormatted,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.cleaning_services_rounded),
                  label: const Text('Пок кардани кэш'),
                  onPressed: breakdown.totalCacheSizeBytes == 0
                      ? null
                      : () => _confirmClearCache(context, ref),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStorageItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String sizeFormatted,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(
          sizeFormatted,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  void _confirmClearCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Пок кардани кэш'),
        content: const Text('Шумо мехоҳед кэши аудио ва расмҳоро пок кунед? (Ин танҳо файлҳои муваққатиро пок мекунад, базаи маълумот ва танзимот бетағйир мемонанд)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Бекор кардан'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(storageStatsServiceProvider).clearAllCache();
              ref.invalidate(storageBreakdownProvider);
              if (context.mounted) {
                SnackBarHelper.showSuccess(
                  context: context,
                  message: 'Кэш бо муваффақият пок карда шуд!',
                );
              }
            },
            child: const Text('Пок кардан'),
          ),
        ],
      ),
    );
  }
}


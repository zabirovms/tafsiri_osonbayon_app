enum FeatureBadgeType {
  dot,
  label,
  counter,
}

class FeatureBadgeConfig {
  final String id;
  final String? parentId; // Links this sub-feature to a parent navigation item
  final int version;
  final FeatureBadgeType type;
  final bool initiallyVisible;

  const FeatureBadgeConfig({
    required this.id,
    this.parentId,
    this.version = 1,
    this.type = FeatureBadgeType.dot,
    this.initiallyVisible = true,
  });
}

class FeatureBadges {
  static const String learnWords = 'learn_words';
  static const String qaida = 'qaida';
  static const String vocabulary = 'vocabulary';
  static const String textSizeSettings = 'text_size_settings';
  static const String tajweed = 'tajweed';
  static const String duas = 'duas';
  static const String masnavi = 'masnavi';
  static const String crossword = 'crossword';
  static const String fillword = 'fillword';
  static const String farziAyn = 'farzi_ayn';
  static const String tajweedFont = 'tajweed_font';
  static const String supportUs = 'support_us';
  static const String qibla = 'qibla';
  static const String settingsTab = 'settings_tab';
  static const String quranSettingsGroup = 'quran_settings_group';

  static final Map<String, FeatureBadgeConfig> configs = {
    // Parent group badges
    settingsTab: const FeatureBadgeConfig(
      id: settingsTab,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),
    quranSettingsGroup: const FeatureBadgeConfig(
      id: quranSettingsGroup,
      parentId: settingsTab,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),

    // Legacy/old features are registered but marked as initially hidden so no badges are shown on them
    learnWords: const FeatureBadgeConfig(
      id: learnWords,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),
    qaida: const FeatureBadgeConfig(
      id: qaida,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),
    vocabulary: const FeatureBadgeConfig(
      id: vocabulary,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),
    textSizeSettings: const FeatureBadgeConfig(
      id: textSizeSettings,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),
    duas: const FeatureBadgeConfig(
      id: duas,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),
    masnavi: const FeatureBadgeConfig(
      id: masnavi,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),

    // Active features that should display badges for new users
    tajweed: const FeatureBadgeConfig(
      id: tajweed,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),
    qibla: const FeatureBadgeConfig(
      id: qibla,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: true,
    ),
    tajweedFont: const FeatureBadgeConfig(
      id: tajweedFont,
      parentId: quranSettingsGroup,
      version: 1,
      type: FeatureBadgeType.label,
      initiallyVisible: false,
    ),
    supportUs: const FeatureBadgeConfig(
      id: supportUs,
      version: 1,
      type: FeatureBadgeType.label,
      initiallyVisible: false,
    ),
    crossword: const FeatureBadgeConfig(
      id: crossword,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: true,
    ),
    fillword: const FeatureBadgeConfig(
      id: fillword,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: true,
    ),
    farziAyn: const FeatureBadgeConfig(
      id: farziAyn,
      version: 1,
      type: FeatureBadgeType.dot,
      initiallyVisible: false,
    ),
  };

  /// Returns a list of all immediate child badge IDs for a given parent.
  static List<String> getChildrenOf(String parentId) {
    return configs.values
        .where((config) => config.parentId == parentId)
        .map((config) => config.id)
        .toList();
  }
}

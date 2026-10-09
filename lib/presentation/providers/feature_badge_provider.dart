import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/feature_badges_config.dart';
import '../pages/settings/settings_page.dart' show SettingsNotifier;

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  final prefs = SettingsNotifier.getPrefs();
  if (prefs != null) return prefs;
  throw StateError('SharedPreferences has not been initialized.');
});

class FeatureBadgeState {
  final String featureId;
  final bool isVisible;
  final FeatureBadgeType type;
  final int count;
  final int seenVersion;

  const FeatureBadgeState({
    required this.featureId,
    required this.isVisible,
    required this.type,
    this.count = 0,
    this.seenVersion = 0,
  });

  FeatureBadgeState copyWith({
    bool? isVisible,
    int? count,
    int? seenVersion,
  }) {
    return FeatureBadgeState(
      featureId: featureId,
      isVisible: isVisible ?? this.isVisible,
      type: type,
      count: count ?? this.count,
      seenVersion: seenVersion ?? this.seenVersion,
    );
  }
}

class FeatureBadgeNotifier extends StateNotifier<Map<String, FeatureBadgeState>> {
  final SharedPreferences _prefs;

  FeatureBadgeNotifier(this._prefs) : super(const {}) {
    _init();
  }

  void _init() {
    final Map<String, FeatureBadgeState> initialState = {};
    for (final entry in FeatureBadges.configs.entries) {
      final config = entry.value;
      final featureId = entry.key;

      final legacyKey = _getLegacyKey(featureId);
      int seenVersion = _prefs.getInt('feature_badge_seen_version_$featureId') ?? 0;

      // Migrate legacy seen flags if version-based seenVersion is 0
      if (seenVersion == 0 && legacyKey != null) {
        final legacySeen = _prefs.getBool(legacyKey) ?? false;
        if (legacySeen) {
          seenVersion = 1;
          _prefs.setInt('feature_badge_seen_version_$featureId', 1);
        }
      }

      final manuallyHidden = _prefs.getBool('feature_badge_manually_hidden_$featureId') ?? false;
      final count = _prefs.getInt('feature_badge_count_$featureId') ?? 0;

      bool isVisible = false;
      if (manuallyHidden) {
        isVisible = false;
      } else if (config.version > seenVersion) {
        isVisible = config.initiallyVisible;
      } else if (seenVersion >= config.version) {
        isVisible = false;
      } else {
        isVisible = config.initiallyVisible;
      }

      initialState[featureId] = FeatureBadgeState(
        featureId: featureId,
        isVisible: isVisible,
        type: config.type,
        count: count,
        seenVersion: seenVersion,
      );
    }
    state = initialState;
  }

  String? _getLegacyKey(String featureId) {
    switch (featureId) {
      case FeatureBadges.learnWords:
        return 'new_feature_learn_words_tab_clicked';
      case FeatureBadges.qaida:
        return 'new_feature_qaida_clicked';
      case FeatureBadges.vocabulary:
        return 'new_feature_vocabulary_clicked';
      case FeatureBadges.textSizeSettings:
        return 'new_feature_text_size_settings_clicked';
      case FeatureBadges.tajweed:
        return 'new_feature_tajweed_clicked';
      case FeatureBadges.duas:
        return 'new_feature_duas_clicked';
      case FeatureBadges.masnavi:
        return 'new_feature_masnavi_clicked';
      default:
        return null;
    }
  }

  void show(String featureId, {int? count}) {
    final currentState = state[featureId];
    if (currentState == null) return;

    _prefs.remove('feature_badge_manually_hidden_$featureId');
    if (count != null) {
      _prefs.setInt('feature_badge_count_$featureId', count);
    }

    state = {
      ...state,
      featureId: currentState.copyWith(
        isVisible: true,
        count: count ?? currentState.count,
      ),
    };
  }

  void hide(String featureId) {
    final currentState = state[featureId];
    if (currentState == null) return;

    _prefs.setBool('feature_badge_manually_hidden_$featureId', true);

    state = {
      ...state,
      featureId: currentState.copyWith(isVisible: false),
    };
  }

  void markSeen(String featureId) {
    final currentState = state[featureId];
    if (currentState == null) return;

    final config = FeatureBadges.configs[featureId];
    if (config == null) return;

    _prefs.setInt('feature_badge_seen_version_$featureId', config.version);
    _prefs.remove('feature_badge_manually_hidden_$featureId');

    state = {
      ...state,
      featureId: currentState.copyWith(
        isVisible: false,
        seenVersion: config.version,
      ),
    };
  }

  void reset(String featureId) {
    final currentState = state[featureId];
    if (currentState == null) return;

    final config = FeatureBadges.configs[featureId];
    if (config == null) return;

    _prefs.remove('feature_badge_seen_version_$featureId');
    _prefs.remove('feature_badge_manually_hidden_$featureId');
    _prefs.remove('feature_badge_count_$featureId');

    state = {
      ...state,
      featureId: FeatureBadgeState(
        featureId: featureId,
        isVisible: config.initiallyVisible,
        type: config.type,
        count: 0,
        seenVersion: 0,
      ),
    };
  }

  void resetAll() {
    for (final featureId in FeatureBadges.configs.keys) {
      reset(featureId);
    }
  }

  bool isVisible(String featureId) {
    return state[featureId]?.isVisible ?? false;
  }
}

final featureBadgeProvider = StateNotifierProvider<FeatureBadgeNotifier, Map<String, FeatureBadgeState>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FeatureBadgeNotifier(prefs);
});

bool _isFeatureBadgeVisibleRecursive(Map<String, FeatureBadgeState> stateMap, String featureId) {
  final state = stateMap[featureId];
  if (state?.isVisible == true) return true;

  final childIds = FeatureBadges.getChildrenOf(featureId);
  for (final childId in childIds) {
    if (_isFeatureBadgeVisibleRecursive(stateMap, childId)) {
      return true; // Propagate visibility up to parent
    }
  }

  return false;
}

final featureBadgeVisibleProvider = Provider.family<bool, String>((ref, featureId) {
  final badgeStateMap = ref.watch(featureBadgeProvider);
  return _isFeatureBadgeVisibleRecursive(badgeStateMap, featureId);
});

final featureBadgeCountProvider = Provider.family<int, String>((ref, featureId) {
  final badgeState = ref.watch(featureBadgeProvider.select((map) => map[featureId]));
  return badgeState?.count ?? 0;
});

class FeatureBadgeController {
  final FeatureBadgeNotifier _notifier;

  FeatureBadgeController(this._notifier);

  void show(String featureId, {int? count}) => _notifier.show(featureId, count: count);
  void hide(String featureId) => _notifier.hide(featureId);
  void markSeen(String featureId) => _notifier.markSeen(featureId);
  void reset(String featureId) => _notifier.reset(featureId);
  bool isVisible(String featureId) => _notifier.isVisible(featureId);
  void resetAll() => _notifier.resetAll();
}

final badgeControllerProvider = Provider<FeatureBadgeController>((ref) {
  final notifier = ref.watch(featureBadgeProvider.notifier);
  return FeatureBadgeController(notifier);
});

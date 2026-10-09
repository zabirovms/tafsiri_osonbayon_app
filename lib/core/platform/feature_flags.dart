import 'platform_info.dart';

class FeatureFlags {
  final bool firestoreEnabled;
  final bool messagingEnabled;
  final bool analyticsEnabled;
  final bool storageEnabled;
  final bool quickActionsEnabled;
  final bool localNotificationsEnabled;
  final bool webViewEnabled;
  final bool youtubeEmbeddedEnabled;
  final bool systemMediaControlsEnabled;
  final bool inAppReviewEnabled;
  final bool inAppUpdateEnabled;

  const FeatureFlags({
    required this.firestoreEnabled,
    required this.messagingEnabled,
    required this.analyticsEnabled,
    required this.storageEnabled,
    required this.quickActionsEnabled,
    required this.localNotificationsEnabled,
    required this.webViewEnabled,
    required this.youtubeEmbeddedEnabled,
    required this.systemMediaControlsEnabled,
    required this.inAppReviewEnabled,
    required this.inAppUpdateEnabled,
  });

  factory FeatureFlags.resolve() {
    return FeatureFlags(
      firestoreEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS || PlatformInfo.isMacOS,
      messagingEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS,
      analyticsEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS || PlatformInfo.isMacOS,
      storageEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS || PlatformInfo.isMacOS,
      quickActionsEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS,
      localNotificationsEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS || PlatformInfo.isMacOS,
      webViewEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS,
      youtubeEmbeddedEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS,
      systemMediaControlsEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS || PlatformInfo.isMacOS,
      inAppReviewEnabled: PlatformInfo.isAndroid || PlatformInfo.isIOS || PlatformInfo.isMacOS,
      inAppUpdateEnabled: PlatformInfo.isAndroid,
    );
  }
}

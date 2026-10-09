import '../../data/services/fcm_service.dart';
import 'feature_flags.dart';
import 'firebase_service.dart';
import 'service_status.dart';
import 'service_registry.dart';
import 'notification_service.dart';
import 'quick_actions_service.dart';
import 'analytics_service.dart';
import 'feedback_repository.dart';

class AppBootstrapper {
  AppBootstrapper._();

  static Future<void> bootstrap() async {
    // 1. Resolve Platform capabilities
    final features = FeatureFlags.resolve();
    ServiceRegistry().featureFlags = features;

    // 2. Initialize Firebase Core and Sub-Services
    await FirebaseService.initialize(features);

    // 3. Resolve and register Analytics
    if (features.analyticsEnabled && ServiceStatus.analyticsReady) {
      ServiceRegistry().analyticsService = FirebaseAnalyticsService();
    } else {
      ServiceRegistry().analyticsService = NoOpAnalyticsService();
    }

    // 4. Resolve and register Feedback Repo
    if (features.firestoreEnabled && ServiceStatus.firestoreReady) {
      ServiceRegistry().feedbackRepository = CloudFeedbackRepository();
    } else {
      ServiceRegistry().feedbackRepository = LocalFeedbackRepository();
    }

    // 5. Resolve and register Notifications
    if (features.messagingEnabled && ServiceStatus.messagingReady) {
      ServiceRegistry().notificationService = FCMService();
    } else {
      ServiceRegistry().notificationService = NoOpNotificationService();
    }

    // 6. Resolve and register Quick Actions
    if (features.quickActionsEnabled) {
      ServiceRegistry().quickActionsService = MobileQuickActionsService();
    } else {
      ServiceRegistry().quickActionsService = NoOpQuickActionsService();
    }

    // 7. Controlled Initialization Sequence (Analytics first)
    await ServiceRegistry().analyticsService.initialize();
    // Note: NotificationService registration and permission sync are deferred to after
    // the first frame in main.dart to prevent blocking the app's native startup sequence.
  }
}

import 'feature_flags.dart';
import 'notification_service.dart';
import 'quick_actions_service.dart';
import 'analytics_service.dart';
import 'feedback_repository.dart';

class ServiceRegistry {
  ServiceRegistry._();
  static final ServiceRegistry _instance = ServiceRegistry._();
  factory ServiceRegistry() => _instance;

  late final FeatureFlags featureFlags;
  late final NotificationService notificationService;
  late final QuickActionsService quickActionsService;
  late final AnalyticsService analyticsService;
  late final FeedbackRepository feedbackRepository;
}

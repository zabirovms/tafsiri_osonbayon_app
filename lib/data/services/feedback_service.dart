import '../../core/platform/feedback_repository.dart';
import '../../core/platform/service_registry.dart';
import '../models/feedback_model.dart';
export '../../core/platform/feedback_repository.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  FeedbackRepository get _repo => ServiceRegistry().feedbackRepository;

  Future<void> trackSession() => _repo.trackSession();
  Future<bool> shouldShowPrompt() => _repo.shouldShowPrompt();
  Future<void> dismissPrompt({bool permanent = false}) => _repo.dismissPrompt(permanent: permanent);
  Future<String?> sendFeedback(FeedbackData feedback) => _repo.sendFeedback(feedback);
  Future<void> saveFeedbackLocally(FeedbackData feedback) => _repo.saveFeedbackLocally(feedback);
  Future<void> syncLocalFeedback() => _repo.syncLocalFeedback();
}

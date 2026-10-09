import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/models/feedback_model.dart';
import '../../data/services/feedback_service.dart';

enum FeedbackSubmitStatus { idle, loading, success, cached, error }

class FeedbackFormState {
  final int? rating; // 1 to 5, nullable (none selected by default)
  final String category;
  final String message;
  final String email;
  final bool includeDeviceInfo;
  final String? screenshotPath;
  final FeedbackSubmitStatus submitStatus;
  final String? errorMessage;
  final Map<String, dynamic>? deviceInfo;

  FeedbackFormState({
    this.rating, // Unselected by default (null)
    this.category = '❤️ Фикри умумӣ',
    this.message = '',
    this.email = '',
    this.includeDeviceInfo = true,
    this.screenshotPath,
    this.submitStatus = FeedbackSubmitStatus.idle,
    this.errorMessage,
    this.deviceInfo,
  });

  FeedbackFormState copyWith({
    int? rating,
    String? category,
    String? message,
    String? email,
    bool? includeDeviceInfo,
    String? screenshotPath,
    FeedbackSubmitStatus? submitStatus,
    String? errorMessage,
    Map<String, dynamic>? deviceInfo,
  }) {
    return FeedbackFormState(
      rating: rating ?? this.rating,
      category: category ?? this.category,
      message: message ?? this.message,
      email: email ?? this.email,
      includeDeviceInfo: includeDeviceInfo ?? this.includeDeviceInfo,
      screenshotPath: screenshotPath ?? this.screenshotPath,
      submitStatus: submitStatus ?? this.submitStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      deviceInfo: deviceInfo ?? this.deviceInfo,
    );
  }
}

class FeedbackNotifier extends StateNotifier<FeedbackFormState> {
  FeedbackNotifier() : super(FeedbackFormState()) {
    _loadDeviceInfo();
  }

  final FeedbackService _feedbackService = FeedbackService();
  final ImagePicker _picker = ImagePicker();

  Future<void> _loadDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      
      final Map<String, dynamic> info = {
        'appVersion': packageInfo.version,
        'appBuildNumber': packageInfo.buildNumber,
        'platform': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
      };

      if (kIsWeb) {
        info['web'] = true;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        info['deviceModel'] = androidInfo.model;
        info['deviceBrand'] = androidInfo.brand;
        info['sdkInt'] = androidInfo.version.sdkInt;
        info['release'] = androidInfo.version.release;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        info['deviceModel'] = iosInfo.utsname.machine;
        info['osVersion'] = iosInfo.systemVersion;
        info['deviceName'] = iosInfo.name;
      }

      state = state.copyWith(deviceInfo: info);
    } catch (e) {
      debugPrint('[FeedbackNotifier] Failed to load device info: $e');
    }
  }

  void updateRating(int rating) {
    state = state.copyWith(rating: rating);
  }

  void updateCategory(String category) {
    state = state.copyWith(category: category);
  }

  void updateMessage(String message) {
    state = state.copyWith(message: message);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void toggleDeviceInfo(bool value) {
    state = state.copyWith(includeDeviceInfo: value);
  }

  Future<void> pickScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress to save bandwidth
        maxWidth: 1080,
      );
      if (image != null) {
        state = state.copyWith(screenshotPath: image.path);
      }
    } catch (e) {
      debugPrint('[FeedbackNotifier] Error picking image: $e');
      state = state.copyWith(errorMessage: 'Хатогӣ ҳангоми интихоби акс.');
    }
  }

  void removeScreenshot() {
    state = state.copyWith(screenshotPath: null);
  }

  void reset() {
    final devInfo = state.deviceInfo;
    state = FeedbackFormState(deviceInfo: devInfo);
  }

  Future<void> submitFeedback({required String source}) async {
    final cleanMsg = state.message.trim();
    if (cleanMsg.isEmpty) {
      state = state.copyWith(
        submitStatus: FeedbackSubmitStatus.error,
        errorMessage: 'Лутфан матни фикру мулоҳизаро ворид кунед.',
      );
      return;
    }

    if (state.rating == null) {
      state = state.copyWith(
        submitStatus: FeedbackSubmitStatus.error,
        errorMessage: 'Лутфан баҳо диҳед (эмоҷиро интихоб кунед).',
      );
      return;
    }

    state = state.copyWith(submitStatus: FeedbackSubmitStatus.loading, errorMessage: null);

    try {
      // Generate a unique ID without external dependencies
      final random = Random();
      final randomVal = random.nextInt(100000);
      final uniqueId = 'fb_${DateTime.now().millisecondsSinceEpoch}_$randomVal';

      final feedback = FeedbackData(
        id: uniqueId,
        createdAt: DateTime.now(),
        source: source,
        rating: state.rating!,
        category: state.category,
        message: cleanMsg,
        email: state.email.trim().isEmpty ? null : state.email.trim(),
        deviceInfo: state.includeDeviceInfo ? state.deviceInfo : null,
        screenshotPath: state.screenshotPath,
      );

      final error = await _feedbackService.sendFeedback(feedback);

      if (error == null) {
        state = state.copyWith(submitStatus: FeedbackSubmitStatus.success);
      } else {
        // Firestore write failed — data was saved to Hive and will sync later.
        debugPrint('[FeedbackNotifier] Feedback cached locally. Reason: $error');
        state = state.copyWith(
          submitStatus: FeedbackSubmitStatus.cached,
          errorMessage: error,
        );
      }
    } catch (e) {
      debugPrint('[FeedbackNotifier] Error submitting feedback: $e');
      state = state.copyWith(
        submitStatus: FeedbackSubmitStatus.error,
        errorMessage: 'Хатогӣ ҳангоми фиристодани фикру мулоҳиза: $e',
      );
    }
  }
}

final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackFormState>((ref) {
  return FeedbackNotifier();
});

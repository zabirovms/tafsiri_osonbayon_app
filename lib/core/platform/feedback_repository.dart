import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/models/feedback_model.dart';
import '../../core/constants/app_constants.dart';

abstract class FeedbackRepository {
  Future<String?> sendFeedback(FeedbackData feedback);
  Future<void> saveFeedbackLocally(FeedbackData feedback);
  Future<void> syncLocalFeedback();
  Future<void> trackSession();
  Future<bool> shouldShowPrompt();
  Future<void> dismissPrompt({bool permanent = false});
}

class LocalFeedbackRepository implements FeedbackRepository {
  static const String _keyFeedbackSessions = 'feedback_session_count';
  static const String _keyFeedbackSubmitted = 'feedback_submitted';
  static const String _keyFeedbackDismissedUntil = 'feedback_dismissed_until';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(AppConstants.feedbackBox)) {
      return await Hive.openBox(AppConstants.feedbackBox);
    }
    return Hive.box(AppConstants.feedbackBox);
  }

  @override
  Future<void> trackSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_keyFeedbackSessions) ?? 0;
      await prefs.setInt(_keyFeedbackSessions, count + 1);
      debugPrint('[LocalFeedbackRepository] Tracked session launch: ${count + 1}');
    } catch (e) {
      debugPrint('[LocalFeedbackRepository] Error tracking session: $e');
    }
  }

  @override
  Future<bool> shouldShowPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (prefs.getBool(_keyFeedbackSubmitted) == true) {
        return false;
      }

      final dismissedUntilStr = prefs.getString(_keyFeedbackDismissedUntil);
      if (dismissedUntilStr != null) {
        final dismissedUntil = DateTime.parse(dismissedUntilStr);
        if (DateTime.now().isBefore(dismissedUntil)) {
          return false;
        }
      }

      final count = prefs.getInt(_keyFeedbackSessions) ?? 0;
      if (count < 7) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('[LocalFeedbackRepository] Error checking prompt status: $e');
      return false;
    }
  }

  @override
  Future<void> dismissPrompt({bool permanent = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snoozeDuration = permanent ? const Duration(days: 365 * 10) : const Duration(days: 14);
      final dismissUntil = DateTime.now().add(snoozeDuration);
      await prefs.setString(_keyFeedbackDismissedUntil, dismissUntil.toIso8601String());
    } catch (e) {
      debugPrint('[LocalFeedbackRepository] Error dismissing prompt: $e');
    }
  }

  Future<void> markAsSubmitted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyFeedbackSubmitted, true);
    } catch (e) {
      debugPrint('[LocalFeedbackRepository] Error marking as submitted: $e');
    }
  }

  @override
  Future<String?> sendFeedback(FeedbackData feedback) async {
    // Local repository only saves locally and reports caching.
    await saveFeedbackLocally(feedback);
    await markAsSubmitted();
    return 'Фикру мулоҳизаҳои шумо ба таври маҳаллӣ сабт карда шуд ва ҳангоми пайвастшавӣ ба интернет фиристода мешавад.';
  }

  @override
  Future<void> saveFeedbackLocally(FeedbackData feedback) async {
    try {
      final box = await _getBox();
      await box.put(feedback.id, feedback.toJson());
      debugPrint('[LocalFeedbackRepository] Cached feedback locally in Hive box.');
    } catch (e) {
      debugPrint('[LocalFeedbackRepository] Error caching feedback locally: $e');
    }
  }

  @override
  Future<void> syncLocalFeedback() async {
    // Local-only configuration doesn't perform cloud sync.
  }
}

class CloudFeedbackRepository extends LocalFeedbackRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<String?> sendFeedback(FeedbackData feedback) async {
    try {
      String? uploadUrl = feedback.screenshotUrl;

      // 1. Try to upload screenshot
      if (uploadUrl == null && feedback.screenshotPath != null && feedback.screenshotPath!.isNotEmpty) {
        try {
          final file = File(feedback.screenshotPath!);
          if (await file.exists()) {
            final fileName = 'screenshot_${feedback.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final ref = _storage.ref().child('feedback_screenshots/$fileName');
            final uploadTask = await ref.putFile(file).timeout(const Duration(seconds: 15));
            uploadUrl = await uploadTask.ref.getDownloadURL().timeout(const Duration(seconds: 10));
            debugPrint('[CloudFeedbackRepository] Screenshot uploaded to: $uploadUrl');
          }
        } catch (storageError) {
          debugPrint('[CloudFeedbackRepository] Screenshot upload failed (skipping): $storageError');
        }
      }

      // 2. Prepare final feedback data
      final finalFeedback = feedback.copyWith(
        screenshotUrl: uploadUrl,
      );

      // 3. Write feedback to Firestore
      await _firestore
          .collection('feedback')
          .doc(finalFeedback.id)
          .set(finalFeedback.toJson())
          .timeout(const Duration(seconds: 12));
      debugPrint('[CloudFeedbackRepository] Feedback uploaded successfully to Firestore.');

      // Mark as submitted
      await markAsSubmitted();

      // If this was a cached item, delete it from local box
      final box = await _getBox();
      if (box.containsKey(feedback.id)) {
        await box.delete(feedback.id);
      }

      return null; // success
    } catch (e) {
      final errorMsg = e.toString();
      debugPrint('[CloudFeedbackRepository] Error sending feedback to Firebase: $errorMsg');
      
      // Save locally to Hive if sending failed (so it can be retried later)
      await saveFeedbackLocally(feedback);
      
      return errorMsg; // return error to caller
    }
  }

  @override
  Future<void> syncLocalFeedback() async {
    try {
      // Check connectivity version-agnostically
      final connectivityResult = await Connectivity().checkConnectivity();
      
      final bool hasConnection;
      if (connectivityResult is List) {
        hasConnection = !connectivityResult.contains(ConnectivityResult.none);
      } else {
        // ignore: unrelated_type_equality_checks
        hasConnection = connectivityResult != ConnectivityResult.none;
      }

      if (!hasConnection) return;

      final box = await _getBox();
      final keys = box.keys.toList();
      if (keys.isEmpty) return;

      debugPrint('[CloudFeedbackRepository] Syncing ${keys.length} cached feedback items...');
      for (final key in keys) {
        final dataMap = box.get(key);
        if (dataMap != null) {
          final feedback = FeedbackData.fromJson(Map<String, dynamic>.from(dataMap as Map));
          final error = await sendFeedback(feedback);
          if (error == null) {
            debugPrint('[CloudFeedbackRepository] Synced cached feedback ${feedback.id}');
          } else {
            debugPrint('[CloudFeedbackRepository] Failed to sync ${feedback.id}: $error');
          }
        }
      }
    } catch (e) {
      debugPrint('[CloudFeedbackRepository] Error syncing cached feedback: $e');
    }
  }
}

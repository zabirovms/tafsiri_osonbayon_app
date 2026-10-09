import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';
import 'feature_flags.dart';
import 'service_status.dart';

class FirebaseService {
  FirebaseService._();

  static Future<void> initialize(FeatureFlags features) async {
    final needsFirebase = features.firestoreEnabled ||
        features.messagingEnabled ||
        features.analyticsEnabled ||
        features.storageEnabled;

    if (!needsFirebase) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Verify and set status per service
      if (features.firestoreEnabled) {
        try {
          final _ = FirebaseFirestore.instance;
          ServiceStatus.firestoreReady = true;
        } catch (e) {
          debugPrint('[FirebaseService] Firestore check failed: $e');
        }
      }
      if (features.analyticsEnabled) {
        try {
          final _ = FirebaseAnalytics.instance;
          ServiceStatus.analyticsReady = true;
        } catch (e) {
          debugPrint('[FirebaseService] Analytics check failed: $e');
        }
      }
      if (features.messagingEnabled) {
        try {
          final _ = FirebaseMessaging.instance;
          ServiceStatus.messagingReady = true;
        } catch (e) {
          debugPrint('[FirebaseService] Messaging check failed: $e');
        }
      }
      if (features.storageEnabled) {
        try {
          final _ = FirebaseStorage.instance;
          ServiceStatus.storageReady = true;
        } catch (e) {
          debugPrint('[FirebaseService] Storage check failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[FirebaseService] Core initialization failed: $e');
    }
  }
}

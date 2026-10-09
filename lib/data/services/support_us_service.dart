import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../core/constants/app_constants.dart';

/// Riverpod provider for whether the Support Us feature is enabled.
final supportUsEnabledProvider = StateNotifierProvider<SupportUsEnabledNotifier, bool>((ref) {
  return SupportUsEnabledNotifier();
});

/// Riverpod provider for the support phone number.
final supportUsPhoneNumberProvider = Provider<String>((ref) {
  return ref.watch(supportUsEnabledProvider.notifier).phoneNumber;
});

class SupportUsEnabledNotifier extends StateNotifier<bool> {
  SupportUsEnabledNotifier() : super(AppConstants.enableSupportUsModule) {
    _initRemoteConfig();
  }

  String _phoneNumber = AppConstants.supportPhoneNumber;
  String get phoneNumber => _phoneNumber;

  Future<void> _initRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Set Remote Config settings
      await remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode 
              ? const Duration(minutes: 1) 
              : const Duration(hours: 1),
        ),
      );

      // Set default parameters
      await remoteConfig.setDefaults(<String, dynamic>{
        'enable_support_us': AppConstants.enableSupportUsModule,
        'support_phone_number': AppConstants.supportPhoneNumber,
      });

      // Fetch and activate remote values
      final updated = await remoteConfig.fetchAndActivate();
      if (updated || remoteConfig.getBool('enable_support_us') != state) {
        state = remoteConfig.getBool('enable_support_us');
      }
      
      final remotePhone = remoteConfig.getString('support_phone_number');
      if (remotePhone.isNotEmpty) {
        _phoneNumber = remotePhone;
      }

      // Listen for realtime updates if supported
      remoteConfig.onConfigUpdated.listen((event) async {
        await remoteConfig.activate();
        state = remoteConfig.getBool('enable_support_us');
        final newPhone = remoteConfig.getString('support_phone_number');
        if (newPhone.isNotEmpty) {
          _phoneNumber = newPhone;
        }
      });
    } catch (e) {
      debugPrint('[SupportUsService] Remote config init/fetch warning: $e');
      // If Firebase or Remote Config fetch fails, state stays at initial default (false).
    }
  }
}

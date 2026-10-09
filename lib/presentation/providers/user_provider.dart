import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/settings_service.dart';

// User state
class UserState {
  final String userId;
  final bool isLoading;
  final String? error;

  UserState({
    required this.userId,
    this.isLoading = false,
    this.error,
  });

  UserState copyWith({
    String? userId,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      userId: userId ?? this.userId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// User notifier
class UserNotifier extends StateNotifier<UserState> {
  final SettingsService _settingsService;

  UserNotifier(this._settingsService) : super(UserState(userId: 'default_user')) {
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final userId = _settingsService.getUserId() ?? 'default_user';
      state = state.copyWith(
        userId: userId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await _settingsService.setUserId(userId);
      state = state.copyWith(userId: userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  String get currentUserId => state.userId;
}

// Provider for user notifier
final userNotifierProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final settingsService = SettingsService();
  return UserNotifier(settingsService);
});

// Convenience provider for current user ID
final currentUserIdProvider = Provider<String>((ref) {
  return ref.watch(userNotifierProvider).userId;
});

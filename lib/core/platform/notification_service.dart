import 'dart:async';

abstract class NotificationService {
  Future<void> initialize();
  Future<void> registerNotificationHandlers();
  Future<void> requestPermissionAndSyncToken();
  Stream<String?> get onPayload;
}

class NoOpNotificationService implements NotificationService {
  final StreamController<String?> _controller = StreamController<String?>.broadcast();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> registerNotificationHandlers() async {}

  @override
  Future<void> requestPermissionAndSyncToken() async {}

  @override
  Stream<String?> get onPayload => _controller.stream;
}

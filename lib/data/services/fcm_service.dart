import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'analytics_service.dart';
import '../../core/platform/notification_service.dart';

/// FCM Service for handling Firebase Cloud Messaging (remote push notifications)
class FCMService implements NotificationService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static const String fallbackRoute = '/';
  static const String _payloadRoutePrefix = 'route:';
  static const String _payloadExternalPrefix = 'external:';
  
  // Stream controller for FCM notification payloads
  final StreamController<String?> _payloadController = StreamController<String?>.broadcast();
  @override
  Stream<String?> get onPayload => _payloadController.stream;

  bool _handlersRegistered = false;
  bool _tokenPhaseComplete = false;
  String? _fcmToken;
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Get FCM token (send this to your backend if needed)
  String? get fcmToken => _fcmToken;

  /// True after [registerNotificationHandlers] and [requestPermissionAndSyncToken] succeed.
  bool get isInitialized => _handlersRegistered && _tokenPhaseComplete;

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FCMService] $message');
    }
  }

  /// Local notifications + FCM streams + cold-start notification (no permission dialog, no token).
  ///
  /// Call only after [Firebase.initializeApp]. Prefer first post-frame callback so startup work
  /// stays off the pre–[runApp] path; still early enough for [getInitialMessage] (terminated → tap).
  ///
  /// See FlutterFire: [FirebaseMessaging.onMessage], [onMessageOpenedApp], [getInitialMessage].
  @override
  Future<void> registerNotificationHandlers() async {
    if (_handlersRegistered) {
      _log('FCM handlers already registered');
      return;
    }

    try {
      // Foreground notification display on Android (high-importance channel); iOS presentation is separate.
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings =
          InitializationSettings(android: androidInit);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          unawaited(_handleNotificationResponsePayload(response.payload));
        },
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'fcm_channel',
        'FCM Notifications',
        description: 'Notifications from Firebase Cloud Messaging',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(channel);
      }

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        unawaited(_handleMessageOpened(message));
      });

      final RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _log('App opened from notification: ${initialMessage.messageId}');
        unawaited(_handleMessageOpened(initialMessage));
      }

      _handlersRegistered = true;
      _log('FCM notification handlers registered');
    } catch (e) {
      _log('Error registering FCM handlers: $e');
      rethrow;
    }
  }

  /// Permission (Apple/web + user-visible where applicable), token, and refresh listener.
  ///
  /// FlutterFire documents [requestPermission] for Apple & web before delivery; safe to defer
  /// slightly after first frame. [getToken] is not required before registering [onMessage] listeners.
  @override
  Future<void> requestPermissionAndSyncToken() async {
    if (_tokenPhaseComplete) {
      _log('FCM token phase already complete');
      return;
    }

    try {
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      var permissionResult = 'denied';
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _log('User granted notification permission');
        permissionResult = 'authorized';
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        _log('User granted provisional notification permission');
        permissionResult = 'provisional';
      } else {
        _log('User denied notification permission');
      }
      AnalyticsService().logNotificationPermissionResult(permissionResult);

      _fcmToken = await _messaging.getToken();
      _log('FCM Token: $_fcmToken');

      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _log('FCM Token refreshed: $newToken');
      });

      _tokenPhaseComplete = true;
      _log('FCM permission/token phase complete');
    } catch (e) {
      _log('Error in FCM permission/token phase: $e');
      rethrow;
    }
  }

  /// Full setup (handlers + permission + token). Prefer [registerNotificationHandlers] and
  /// [requestPermissionAndSyncToken] from [main] for lighter startup.
  @override
  Future<void> initialize() async {
    if (isInitialized) {
      _log('FCM already initialized');
      return;
    }
    await registerNotificationHandlers();
    await requestPermissionAndSyncToken();
  }

  /// Handle foreground messages (when app is open)
  void _handleForegroundMessage(RemoteMessage message) {
    _log('Received foreground message: ${message.messageId}');
    AnalyticsService().logNotificationReceived(source: 'fcm', foreground: true);

    // Show local notification when app is in foreground
    final notification = message.notification;
    if (notification != null) {
      final action = _resolveAction(message);
      
      _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fcm_channel',
            'FCM Notifications',
            channelDescription: 'Notifications from Firebase Cloud Messaging',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
        ),
        payload: action.toPayload(),
      );
    }
  }

  /// Handle message opened (when user taps notification)
  Future<void> _handleMessageOpened(RemoteMessage message) async {
    _log('Notification opened: ${message.messageId}');
    _log('Message data: ${message.data}');

    final action = _resolveAction(message);
    final routeForAnalytics = action.route ?? action.externalUrl ?? fallbackRoute;

    AnalyticsService().logNotificationOpened(
      source: 'fcm',
      route: routeForAnalytics,
      messageId: message.messageId,
    );

    if (action.externalUrl != null) {
      final opened = await _launchExternalUrl(action.externalUrl!);
      if (!opened) {
        _payloadController.add(fallbackRoute);
      }
      return;
    }

    final route = action.route ?? fallbackRoute;
    _log('Emitting route to navigation stream: $route');
    _payloadController.add(route);
  }

  _ResolvedAction _resolveAction(RemoteMessage message) {
    final rawRoute = message.data['route']?.toString();
    final rawPath = message.data['path']?.toString();
    final rawExternalUrl = message.data['external_url']?.toString();
    final inferred = _extractRouteFromData(message.data);
    final rawInternal = rawRoute ?? rawPath ?? inferred;

    final normalizedExternal = _normalizeExternalUrl(rawExternalUrl);
    if (normalizedExternal != null) {
      if (rawExternalUrl != null && normalizedExternal != rawExternalUrl.trim()) {
        AnalyticsService().safeLogEvent('notification_external_url_normalized', {
          'message_id': message.messageId ?? 'unknown',
          'raw_external_url': rawExternalUrl,
          'normalized_external_url': normalizedExternal,
        });
      }
      return _ResolvedAction(externalUrl: normalizedExternal);
    }

    final normalizedRoute = _normalizeRoute(rawInternal);
    if (rawInternal == null || normalizedRoute != rawInternal.trim()) {
      AnalyticsService().safeLogEvent('notification_route_normalized', {
        'message_id': message.messageId ?? 'unknown',
        'raw_route': rawInternal ?? 'null',
        'normalized_route': normalizedRoute,
      });
    }
    return _ResolvedAction(route: normalizedRoute);
  }

  String _normalizeRoute(String? rawRoute) {
    if (rawRoute == null) return fallbackRoute;
    var route = rawRoute.trim();
    if (route.isEmpty) return fallbackRoute;

    if (!route.startsWith('/')) {
      route = '/$route';
    }

    final uri = Uri.tryParse(route);
    if (uri == null) return fallbackRoute;

    final path = uri.path;
    if (path.isEmpty) return fallbackRoute;

    final isAllowed = _isAllowedRoute(path);
    if (!isAllowed) return fallbackRoute;

    final query = uri.hasQuery ? '?${uri.query}' : '';
    return '$path$query';
  }

  bool _isAllowedRoute(String path) {
    const exact = <String>{
      '/',
      '/quran',
      '/sections',
      '/bukhari',
      '/bukhari/bookmarks',
      '/bukhari/search-hadiths',
      '/duas',
      '/duas/rabbano',
      '/duas/prophets',
      '/duas/etiquette-of-supplication',
      '/gallery',
      '/quoted-verses',
      '/prophets',
      '/asmaul-husna',
      '/bookmarks',
      '/search',
      '/navigation',
      '/settings',
      '/scheduler',
      '/learn-words',
      '/tajweed',
      '/qaida',
      '/vocabulary',
      '/audio-home',
      '/audio-home/all-reciters',
      '/audio-home/player',
      '/audio-home/library',
      '/tasbeeh',
    };

    if (exact.contains(path)) return true;

    final patterns = <RegExp>[
      RegExp(r'^/surah/\d+$'),
      RegExp(r'^/surah/\d+/verse/\d+$'),
      RegExp(r'^/duas/category/[a-z0-9-]+$'),
      RegExp(r'^/qaida/lesson/\d+$'),
      RegExp(r'^/qaida/lesson/\d+/letter/[a-z0-9_-]+$'),
      RegExp(r'^/vocabulary/lesson/\d+$'),
      RegExp(r'^/vocabulary/lesson/\d+/quiz$'),
      RegExp(r'^/vocabulary/lesson/\d+/word/\d+$'),
      RegExp(r'^/youtube/[A-Za-z0-9_-]+$'),
      RegExp(r'^/youtube-video/[A-Za-z0-9_-]+$'),
      RegExp(r'^/live/[A-Za-z0-9._-]+$'),
      RegExp(r'^/audio-home/reciter/[A-Za-z0-9._-]+$'),
    ];
    return patterns.any((pattern) => pattern.hasMatch(path));
  }

  String? _normalizeExternalUrl(String? rawUrl) {
    if (rawUrl == null) return null;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return null;

    final scheme = uri.scheme.toLowerCase();
    const allowedSchemes = {'https', 'http', 'instagram', 'tg', 'mailto'};
    const allowedCustomSchemes = {'youtube', 'vnd.youtube'};

    if (scheme == 'https' || scheme == 'http') {
      if (uri.host.isEmpty) return null;
      return uri.toString();
    }

    if (allowedSchemes.contains(scheme) || allowedCustomSchemes.contains(scheme)) {
      return uri.toString();
    }
    return null;
  }

  Future<bool> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        _log('Cannot launch external URL: $url');
        AnalyticsService().safeLogEvent('notification_external_url_failed', {
          'url': url,
          'reason': 'cannot_launch',
        });
        return false;
      }
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        AnalyticsService().safeLogEvent('notification_external_url_failed', {
          'url': url,
          'reason': 'launch_returned_false',
        });
      }
      return launched;
    } catch (e) {
      _log('External URL launch error: $e');
      AnalyticsService().safeLogEvent('notification_external_url_failed', {
        'url': url,
        'reason': 'exception',
      });
      return false;
    }
  }

  Future<void> _handleNotificationResponsePayload(String? payload) async {
    if (payload == null || payload.isEmpty) {
      _payloadController.add(fallbackRoute);
      return;
    }

    if (payload.startsWith(_payloadExternalPrefix)) {
      final url = payload.substring(_payloadExternalPrefix.length);
      final opened = await _launchExternalUrl(url);
      AnalyticsService().logNotificationOpened(source: 'fcm', route: url);
      if (!opened) {
        _payloadController.add(fallbackRoute);
      }
      return;
    }

    final routePayload = payload.startsWith(_payloadRoutePrefix)
        ? payload.substring(_payloadRoutePrefix.length)
        : payload;
    final route = _normalizeRoute(routePayload);
    _log('FCM notification tapped: $payload -> $route');
    AnalyticsService().logNotificationOpened(source: 'fcm', route: route);
    _payloadController.add(route);
  }

  /// Extract route from message data
  /// Supports common patterns like surah/verse navigation
  String? _extractRouteFromData(Map<String, dynamic> data) {
    // Check for surah and verse
    if (data.containsKey('surah')) {
      final surah = data['surah'];
      final verse = data['verse'];
      if (verse != null) {
        return '/surah/$surah/verse/$verse';
      } else if (surah != null) {
        return '/surah/$surah';
      }
    }
    
    // Check for other common routes
    if (data.containsKey('type')) {
      final type = data['type'];
      switch (type) {
        case 'surah':
          return data['surah'] != null ? '/surah/${data['surah']}' : null;
        case 'dua':
          return '/duas/rabbano';
        case 'verse':
          return '/quoted-verses';
        case 'settings':
          return '/settings';
        default:
          return null;
      }
    }
    
    return null;
  }

  /// Subscribe to a topic (for targeted notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      _log('Subscribed to topic: $topic');
    } catch (e) {
      _log('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      _log('Unsubscribed from topic: $topic');
    } catch (e) {
      _log('Error unsubscribing from topic $topic: $e');
    }
  }
}

/// Background message handler (must be top-level function)
/// This handles FCM messages when the app is in the background or terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[FCM Background] Handling background message: ${message.messageId}');
    debugPrint('[FCM Background] Message data: ${message.data}');
  }
  
  // You can perform background tasks here
  // Note: This runs in a separate isolate, so you can't use UI code here
}

class _ResolvedAction {
  final String? route;
  final String? externalUrl;

  const _ResolvedAction({this.route, this.externalUrl});

  String toPayload() {
    if (externalUrl != null) {
      return '${FCMService._payloadExternalPrefix}$externalUrl';
    }
    return '${FCMService._payloadRoutePrefix}${route ?? FCMService.fallbackRoute}';
  }
}

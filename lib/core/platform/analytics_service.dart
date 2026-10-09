import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'service_registry.dart';

abstract class AnalyticsService {
  const AnalyticsService._(); // Generative constructor for subclasses

  factory AnalyticsService() => _DelegatingAnalyticsService();

  static NavigatorObserver get routeObserver => AnalyticsService().routeObserverInstance;

  Future<void> initialize();
  Future<void> logEvent(String name, [Map<String, Object>? params]);
  Future<void> logScreenView({required String screenName, String? screenClass});
  Future<void> setUserProperty(String name, String? value);
  Future<void> setCollectionEnabled(bool enabled);

  NavigatorObserver get routeObserverInstance => _AnalyticsRouteObserver(this);

  // Backward compatibility fallback for safeLogEvent
  Future<void> safeLogEvent(String name, [Map<String, Object>? params]) => logEvent(name, params);

  // ——— Custom Events (Common helper methods) ———
  Future<void> logSurahView(int surahNumber, {String? surahName}) async {
    await logEvent('surah_view', {
      'surah_number': surahNumber,
      if (surahName != null) 'surah_name': surahName,
    });
  }

  Future<void> logVerseView(int surahNumber, int verseNumber) async {
    await logEvent('verse_view', {
      'surah_number': surahNumber,
      'verse_number': verseNumber,
    });
  }

  Future<void> logAudioPlay({
    required String reciterId,
    int? surahNumber,
    String? source,
  }) async {
    await logEvent('audio_play', {
      'reciter_id': reciterId,
      if (surahNumber != null) 'surah_number': surahNumber,
      if (source != null) 'source': source,
    });
  }

  Future<void> logAudioPause({required String reciterId, int? surahNumber}) async {
    await logEvent('audio_pause', {
      'reciter_id': reciterId,
      if (surahNumber != null) 'surah_number': surahNumber,
    });
  }

  Future<void> logAudioReciterSelected(String reciterId) async {
    await logEvent('audio_reciter_selected', {'reciter_id': reciterId});
  }

  Future<void> logLessonStart(String lessonType, String lessonId) async {
    await logEvent('lesson_start', {'lesson_type': lessonType, 'lesson_id': lessonId});
  }

  Future<void> logLessonComplete(String lessonType, String lessonId, {int? score}) async {
    await logEvent('lesson_complete', {
      'lesson_type': lessonType,
      'lesson_id': lessonId,
      if (score != null) 'score': score,
    });
  }

  Future<void> logQuizComplete(String quizType, String quizId, int score) async {
    await logEvent('quiz_complete', {
      'quiz_type': quizType,
      'quiz_id': quizId,
      'score': score,
    });
  }

  Future<void> logDuaView(String categorySlug, {String? duaId}) async {
    await logEvent('dua_view', {
      'category': categorySlug,
      if (duaId != null) 'dua_id': duaId,
    });
  }

  Future<void> logBukhariChapterView(String bookId, String chapterId) async {
    await logEvent('bukhari_chapter_view', {'book_id': bookId, 'chapter_id': chapterId});
  }

  Future<void> logBukhariHadithRead(String hadithId) async {
    await logEvent('bukhari_hadith_read', {'hadith_id': hadithId});
  }

  Future<void> logBukhariBookmarkAdd() async {
    await logEvent('bukhari_bookmark_add', {});
  }

  Future<void> logBookmarkAdd(String type, {int? surahNumber, int? verseNumber}) async {
    await logEvent('bookmark_add', {
      'bookmark_type': type,
      if (surahNumber != null) 'surah_number': surahNumber,
      if (verseNumber != null) 'verse_number': verseNumber,
    });
  }

  Future<void> logShare(String contentType, {String? id}) async {
    await logEvent('share', {
      'content_type': contentType,
      if (id != null) 'content_id': id,
    });
  }

  Future<void> logSearch(String searchType, {int? resultCount}) async {
    await logEvent('search', {
      'search_type': searchType,
      if (resultCount != null) 'result_count': resultCount,
    });
  }

  Future<void> logNotificationPermissionResult(String result) async {
    await logEvent('notification_permission', {'result': result});
  }

  Future<void> logNotificationReceived({
    required String source,
    bool? foreground,
  }) async {
    await logEvent('notification_received', {
      'source': source,
      if (foreground != null) 'foreground': foreground ? 'true' : 'false',
    });
  }

  Future<void> logNotificationOpened({
    required String source,
    String? route,
    String? messageId,
  }) async {
    await logEvent('notification_opened', {
      'source': source,
      if (route != null && route.isNotEmpty) 'route': route,
      if (messageId != null) 'message_id': messageId,
    });
  }
}

class _DelegatingAnalyticsService extends AnalyticsService {
  static final _DelegatingAnalyticsService _instance = _DelegatingAnalyticsService._internal();
  factory _DelegatingAnalyticsService() => _instance;
  _DelegatingAnalyticsService._internal() : super._();

  AnalyticsService get _delegate => ServiceRegistry().analyticsService;

  @override
  Future<void> initialize() => _delegate.initialize();

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) =>
      _delegate.logEvent(name, params);

  @override
  Future<void> logScreenView({required String screenName, String? screenClass}) =>
      _delegate.logScreenView(screenName: screenName, screenClass: screenClass);

  @override
  Future<void> setUserProperty(String name, String? value) =>
      _delegate.setUserProperty(name, value);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _delegate.setCollectionEnabled(enabled);

  @override
  NavigatorObserver get routeObserverInstance => _delegate.routeObserverInstance;
}

class FirebaseAnalyticsService extends AnalyticsService {
  late final FirebaseAnalytics _analytics;

  FirebaseAnalyticsService() : super._();

  @override
  Future<void> initialize() async {
    _analytics = FirebaseAnalytics.instance;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[FirebaseAnalyticsService] $message');
    }
  }

  Future<void> _safe(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[FirebaseAnalyticsService] Error (silent): $e');
        debugPrint(st.toString());
      }
    }
  }

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    await _safe(() async {
      final safe = _sanitizeParams(params);
      await _analytics.logEvent(name: name, parameters: safe);
      if (kDebugMode) _log('event: $name ${safe ?? ''}');
    });
  }

  @override
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    await _safe(() async {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      if (kDebugMode) _log('screen_view: $screenName');
    });
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    await _safe(() async {
      await _analytics.setUserProperty(name: name, value: value);
    });
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    await _safe(() async {
      await _analytics.setAnalyticsCollectionEnabled(enabled);
      _log('Analytics collection enabled: $enabled');
    });
  }

  Map<String, Object>? _sanitizeParams(Map<String, Object>? params) {
    if (params == null || params.isEmpty) return null;
    final out = <String, Object>{};
    for (final e in params.entries) {
      if (e.value is String || e.value is int || e.value is double) {
        out[e.key] = e.value;
      } else if (e.value is bool) {
        out[e.key] = (e.value as bool) ? 'true' : 'false';
      }
    }
    return out.isEmpty ? null : out;
  }
}

class NoOpAnalyticsService extends AnalyticsService {
  NoOpAnalyticsService() : super._();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    if (kDebugMode) {
      debugPrint('[NoOpAnalyticsService] logEvent: $name $params');
    }
  }

  @override
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    if (kDebugMode) {
      debugPrint('[NoOpAnalyticsService] logScreenView: $screenName');
    }
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

class _AnalyticsRouteObserver extends NavigatorObserver {
  final AnalyticsService _service;
  static String? _lastLoggedScreenName;

  _AnalyticsRouteObserver(this._service);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logRoute(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _logRoute(newRoute);
  }

  void _logRoute(Route<dynamic> route) {
    final name = route.settings.name ?? 'unknown';
    if (name == _lastLoggedScreenName) return;
    _lastLoggedScreenName = name;
    _service.logScreenView(
      screenName: name,
      screenClass: route.settings.arguments is String
          ? route.settings.arguments as String
          : name,
    );
  }
}

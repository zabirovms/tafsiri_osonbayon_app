import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/performance_optimizer.dart';
import 'core/services/migration_service.dart';
import 'core/utils/hive_utils.dart';

import 'presentation/pages/settings/settings_page.dart';
import 'presentation/providers/feature_badge_provider.dart';
import 'core/platform/app_bootstrapper.dart';
import 'core/platform/service_registry.dart';
import 'core/platform/feature_flags.dart';
import 'core/navigation/app_deep_link_listener.dart';
import 'data/services/audio_service.dart';
import 'data/services/audio_cache_manager.dart';
import 'package:home_widget/home_widget.dart';

@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  // Ensure ServiceRegistry has FeatureFlags initialized in this clean isolate
  try {
    ServiceRegistry().featureFlags;
  } catch (_) {
    try {
      ServiceRegistry().featureFlags = FeatureFlags.resolve();
    } catch (_) {}
  }

  if (uri != null && uri.host == 'audiowidget') {
    final action = uri.pathSegments.first;
    final audioService = QuranAudioService();
    
    // Load last played surah and qari from local storage if needed
    final prefs = await SharedPreferences.getInstance();
    final lastSurah = prefs.getInt('widget_last_surah') ?? 1;
    final lastQari = prefs.getString('widget_last_qari') ?? 'ar.alafasy';
    
    if (action == 'toggle') {
      if (audioService.isPlaying) {
        await audioService.pause();
      } else if (audioService.currentSurahNumber != null) {
        await audioService.resume();
      } else {
        // Play last played surah
        await audioService.playSurah(lastSurah, edition: lastQari);
      }
    } else if (action == 'next') {
      await audioService.playNextSurah(edition: audioService.currentEdition);
    } else if (action == 'prev') {
      await audioService.playPreviousSurah(edition: audioService.currentEdition);
    }
  }
}

/// True only when the visible location is main menu `/`.
///
/// [RouterDelegate.currentConfiguration.uri.path] is often `''` on non-home
/// stack routes; treating empty as home broke system bar restore on other screens.
bool _routerShowsMainMenuHome(GoRouter router) {
  try {
    final fromProvider = router.routeInformationProvider.value.uri.path;
    if (fromProvider.isNotEmpty) {
      return fromProvider == '/';
    }
  } catch (_) {}
  try {
    return router.routerDelegate.currentConfiguration.uri.path == '/';
  } catch (_) {
    return false;
  }
}

void main() async {
  final totalStartTime = DateTime.now();
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('[SPLASH TIMING] App initialization started');
  debugPrint('═══════════════════════════════════════════════════════');
  
  WidgetsFlutterBinding.ensureInitialized();

  // Register home_widget background callback
  HomeWidget.registerInteractivityCallback(widgetBackgroundCallback);

  // Initialize unified platforms and services
  await AppBootstrapper.bootstrap();

  // Hive: only scheduler + prayer_times before runApp; other boxes after first frame.
  final hiveStartTime = DateTime.now();
  await Hive.initFlutter();
  final hiveInitDuration = DateTime.now().difference(hiveStartTime);
  debugPrint('[SPLASH TIMING] Hive.initFlutter(): ${hiveInitDuration.inMilliseconds}ms');

  final hiveCriticalStart = DateTime.now();
  await HiveUtils.initCritical();
  debugPrint(
    '[SPLASH TIMING] HiveUtils.initCritical() (2 boxes): '
    '${DateTime.now().difference(hiveCriticalStart).inMilliseconds}ms',
  );

  // Initialize SharedPreferences (used by SettingsNotifier and by Migration when it runs deferred)
  final prefsStartTime = DateTime.now();
  final prefs = await SharedPreferences.getInstance();
  SettingsNotifier.setPrefs(prefs);
  final prefsDuration = DateTime.now().difference(prefsStartTime);
  debugPrint('[SPLASH TIMING] SharedPreferences.getInstance(): ${prefsDuration.inMilliseconds}ms');

  // Migration deferred to after runApp() (see deferred block below).
  // AudioService.init is lazy: first Quran playback calls QuranAudioBinding.ensureInitialized()
  // (see audio_service.dart) to reduce AudioService.onCreate ANR at startup.

  // Set preferred orientations
  final orientationStartTime = DateTime.now();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final orientationDuration = DateTime.now().difference(orientationStartTime);
  debugPrint('[SPLASH TIMING] SystemChrome.setPreferredOrientations(): ${orientationDuration.inMilliseconds}ms');
  
  // Set system UI overlay style - compliant with Google Play Store policies
  // Both status bar and navigation bar use theme colors to match app appearance
  // Content never draws underneath system bars - compliant with Android UI guidelines
  // This will be updated per theme in the app widget, but we set a default here
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  // Ensure status/navigation bars stay visible by default
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  final totalDuration = DateTime.now().difference(totalStartTime);
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('[SPLASH TIMING] Total initialization time: ${totalDuration.inMilliseconds}ms (${(totalDuration.inMilliseconds / 1000).toStringAsFixed(2)}s)');
  debugPrint('═══════════════════════════════════════════════════════');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const _BackHandler(child: TajikQuranApp()),
    ),
  );

  // After first paint: register notifications, then Hive secondary.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    () async {
      try {
        final tFcm = DateTime.now();
        await ServiceRegistry().notificationService.registerNotificationHandlers();
        debugPrint(
          '[Main] Post-frame: Notification registerNotificationHandlers() in '
          '${DateTime.now().difference(tFcm).inMilliseconds}ms',
        );
      } catch (e) {
        debugPrint('[Main] Notification registerNotificationHandlers error: $e');
      }
      final tHive = DateTime.now();
      HiveUtils.initSecondary().then((_) {
        debugPrint(
          '[Main] Post-frame: HiveUtils.initSecondary() (7 boxes) in '
          '${DateTime.now().difference(tHive).inMilliseconds}ms',
        );
      }).catchError((Object e, StackTrace st) {
        debugPrint('[Main] HiveUtils.initSecondary error: $e');
      });
    }();
  });

  // Staggered deferred init (not needed for first frame). Spreads native/plugin work
  // so notification permission/token and migration do not pile up on the main isolate right after runApp.
  // AudioService: lazy on first playback (QuranAudioBinding in audio_service.dart).

  // Wave 1 — ~400ms after first frame: Notification permission + token, then PerformanceOptimizer
  Future.delayed(const Duration(milliseconds: 400), () async {
    try {
      final t1 = DateTime.now();
      await ServiceRegistry().notificationService.requestPermissionAndSyncToken();
      debugPrint(
        '[Main] Deferred wave1: Notification requestPermissionAndSyncToken in '
        '${DateTime.now().difference(t1).inMilliseconds}ms',
      );
      final t2 = DateTime.now();
      await PerformanceOptimizer().initialize();
      debugPrint('[Main] Deferred wave1: PerformanceOptimizer in ${DateTime.now().difference(t2).inMilliseconds}ms');
      await AudioCacheManager().autoCleanOldCaches();
      debugPrint('[Main] Deferred wave1: AudioCacheManager autoCleanOldCaches completed');
    } catch (e) {
      debugPrint('[Main] Deferred wave1 error: $e');
    }
  }).catchError((error) {
    debugPrint('[Main] Deferred wave1: $error');
  });

  // Wave 2 — ~1.5s: migration (I/O / version checks; keep separate from FCM burst)
  Future.delayed(const Duration(milliseconds: 1500), () async {
    try {
      final t3 = DateTime.now();
      await MigrationService().checkAndRunMigrations();
      debugPrint('[Main] Deferred wave2: Migration in ${DateTime.now().difference(t3).inMilliseconds}ms');
    } catch (e) {
      debugPrint('[Main] Deferred wave2 error: $e');
    }
  }).catchError((error) {
    debugPrint('[Main] Deferred wave2: $error');
  });

}

class TajikQuranApp extends ConsumerWidget {
  const TajikQuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    Color accentFor(String id) {
      switch (id) {
        case '#d4a574':
          return const Color(0xFFD4A574);
        case '#16697a':
          return const Color(0xFF16697A);
        case '#1e293b':
          return const Color(0xFF1E293B);
        case '#c6ac42':
          return const Color(0xFFC6AC42);
        case '#27272a':
          return const Color(0xFF27272A);
        case '#78350f':
          return const Color(0xFF78350F);
        case '#475569':
          return const Color(0xFF475569);
        case '#06b6d4':
          return const Color(0xFF06B6D4);
        case '#6b9080':
          return const Color(0xFF6B9080);
        case '#fda4af':
          return const Color(0xFFFDA4AF);
        case '#334155':
          return const Color(0xFF334155);
        case '#fbcfe8':
          return const Color(0xFFFBCFE8);
        case '#78716c':
          return const Color(0xFF78716C);
        case '#0f766e':
          return const Color(0xFF0F766E);
        default:
          return const Color(0xFFD4A574);
      }
    }

    final accent = accentFor(settings.themeAccent);
    final lightTheme = AppTheme.lightFromAccent(accent, backgroundStyle: settings.lightBackgroundStyle);
    final darkTheme = AppTheme.darkFromAccent(accent, backgroundStyle: settings.darkBackgroundStyle);
    final systemDark = PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    final isDark = settings.themeMode == 'system' ? systemDark : (settings.themeMode == 'dark');
    final initTheme = isDark ? darkTheme : lightTheme;

    return ThemeProvider(
      initTheme: initTheme,
      builder: (context, myTheme) {
        return ScreenUtilInit(
          designSize: const Size(375, 812), // iPhone X design size
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            // Theme-based system bars (home route manages its own status bar from scroll).
            try {
              final router = ref.read(routerProvider);
              if (!_routerShowsMainMenuHome(router)) {
                final isDarkTheme = myTheme.brightness == Brightness.dark;
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: Colors.transparent,
                    systemNavigationBarDividerColor: Colors.transparent,
                    statusBarIconBrightness:
                        isDarkTheme ? Brightness.light : Brightness.dark,
                    systemNavigationBarIconBrightness:
                        isDarkTheme ? Brightness.light : Brightness.dark,
                  ),
                );
              }
            } catch (_) {
              final isDarkTheme = myTheme.brightness == Brightness.dark;
              SystemChrome.setSystemUIOverlayStyle(
                SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  systemNavigationBarColor: Colors.transparent,
                  systemNavigationBarDividerColor: Colors.transparent,
                  statusBarIconBrightness:
                      isDarkTheme ? Brightness.light : Brightness.dark,
                  systemNavigationBarIconBrightness:
                      isDarkTheme ? Brightness.light : Brightness.dark,
                ),
              );
            }

            return MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: myTheme,
              routerConfig: ref.watch(routerProvider),
              builder: (context, child) {
                return ThemeSwitchingArea(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: const TextScaler.linear(1.0),
                    ),
                    child: _StatusBarVisibilityWrapper(
                      child: AppDeepLinkListener(
                        child: child!,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Widget that ensures the status bar and bottom navigation bar are always visible globally
/// This wrapper monitors route changes and ensures system bars remain visible
class _StatusBarVisibilityWrapper extends StatefulWidget {
  final Widget child;

  const _StatusBarVisibilityWrapper({required this.child});

  @override
  State<_StatusBarVisibilityWrapper> createState() => _StatusBarVisibilityWrapperState();
}

class _StatusBarVisibilityWrapperState extends State<_StatusBarVisibilityWrapper>
    with WidgetsBindingObserver {
  String? _lastRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure system bars are visible when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSystemBarsVisible();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    debugPrint('[Memory] Low memory pressure signal received - purging image caches');
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (e) {
      debugPrint('[Memory] Error purging image cache: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Clear live image cache when paused to free RAM for background apps
      try {
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}
    }
    if (state == AppLifecycleState.detached) {
      try {
        QuranAudioService().dispose();
      } catch (_) {}
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check if route has changed
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
        if (_lastRoute != currentLocation) {
          _lastRoute = currentLocation;
          // Route changed - ensure system bars are updated with theme colors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureSystemBarsVisible();
          });
        }
      }
    } catch (e) {
      // If route check fails, continue with normal behavior
    }
    
    // Ensure system bars are visible whenever dependencies change (e.g., route changes, theme changes)
    // This is called when navigating between routes or when theme changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSystemBarsVisible();
    });
  }

  void _ensureSystemBarsVisible() {
    if (!mounted) return;
    
    // Check if we're on YouTube page - completely skip system bar updates to allow fullscreen
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        final currentLocation = router.routerDelegate.currentConfiguration.uri.path;
        if (currentLocation.startsWith('/youtube-video') || currentLocation.startsWith('/youtube/')) {
          // On YouTube page - completely skip all system UI updates
          // Let the YouTube player handle fullscreen mode without interference
          return;
        }
      }
    } catch (e) {
      // If route check fails, continue with normal behavior
    }
    
    // Force status bar and bottom navigation bar to be visible
    // SystemUiOverlay.values includes both top (status) and bottom (navigation) bars
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    // Home (/) uses a scroll-based status bar (hero vs scaffold); MainMenuPage applies it.
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null && _routerShowsMainMenuHome(router)) {
        return;
      }
    } catch (e) {
      // Continue with global overlay style
    }
    
    // Update both status bar and navigation bar colors based on current theme
    // Ensures system bars match app theme and are always solid and visible (Google Play Store compliant)
    // Works correctly with both 3-button and gesture navigation
    // This runs after every build to ensure theme-based colors always override any page-specific settings
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get theme colors to apply globally via AnnotatedRegion
    // This ensures the system navigation bar respects the app theme at all times
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use AnnotatedRegion at the root level to ensure theme-based system UI style
    // has the highest priority and overrides any AppBar or page-specific settings
    final systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    );
    
    // Update system bars after every build to ensure theme-based colors are always applied
    // This ensures that even if a page sets its own system UI overlay style, the theme-based
    // colors will be restored after the page builds
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSystemBarsVisible();
    });

    // Home (/) manages status bar from scroll (hero vs scaffold); skip root AnnotatedRegion
    // so it does not force scaffold over the hero-colored bar.
    bool isHomeRoute = false;
    try {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        isHomeRoute = _routerShowsMainMenuHome(router);
      }
    } catch (_) {}
    
    // Wrap with AnnotatedRegion to ensure theme-based system UI style takes precedence
    // over AppBar and page-specific settings
    if (isHomeRoute) {
      return widget.child;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemUiOverlayStyle,
      child: widget.child,
    );
  }
}

class _BackHandler extends StatelessWidget {
  final Widget child;
  const _BackHandler({required this.child});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        try {
          final router = GoRouter.of(context);
          final currentLocation = GoRouterState.of(context).uri.path;

          final tabRoutes = ['/search', '/bookmarks', '/settings', '/quran'];

          if (tabRoutes.contains(currentLocation)) {
            router.go('/');
          } else if (router.canPop()) {
            try {
              router.pop();
            } catch (_) {
              router.go('/');
            }
          } else if (currentLocation == '/') {
            await SystemNavigator.pop();
          } else {
            router.go('/');
          }
        } catch (_) {
          if (!context.mounted) return;
          try {
            GoRouter.of(context).go('/');
          } catch (_) {}
        }
      },
      child: child,
    );
  }
}

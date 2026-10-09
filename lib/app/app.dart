import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/surah/surah_page.dart';
import '../presentation/pages/bookmarks/bookmarks_page.dart';
import '../presentation/pages/search/search_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/feedback/feedback_page.dart';
import '../presentation/pages/privacy/privacy_policy_page.dart';

import '../presentation/pages/quran_pages/pages_menu_page.dart';
import '../presentation/pages/support_us/support_us_page.dart';
import '../data/services/analytics_service.dart';
import '../core/navigation/main_menu_route_observer.dart';

// Router configuration
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    observers: [
      AnalyticsService.routeObserver,
      mainMenuSystemUiRouteObserver,
    ],
    redirect: (context, state) {
      final uri = state.uri;
      var path = uri.path;

      if (path.length > 1 && path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }

      // Handle web search links: /surah/15/34 -> /surah/15/verse/34
      final surahAyahMatch = RegExp(r'^/surah/(\d+)/(\d+)$').firstMatch(path);
      if (surahAyahMatch != null) {
        final surah = surahAyahMatch.group(1);
        final verse = surahAyahMatch.group(2);
        final query = uri.hasQuery ? '?${uri.query}' : '';
        return '/surah/$surah/verse/$verse$query';
      }

      return null;
    },
    routes: [
      // Quran Home Page (Root)
      GoRoute(
        path: '/',
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomePage(),
        ),
      ),

      // Quran Page alias
      GoRoute(
        path: '/quran',
        name: 'quran',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomePage(),
        ),
      ),

      // Support Us Page
      GoRoute(
        path: '/support-us',
        name: 'support-us',
        builder: (context, state) => const SupportUsPage(),
      ),

      // Feedback Page
      GoRoute(
        path: '/feedback',
        name: 'feedback',
        builder: (context, state) => const FeedbackPage(),
      ),

      // Privacy Policy Page
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),

      // Surah Page
      GoRoute(
        path: '/surah/:surahNumber',
        name: 'surah',
        pageBuilder: (context, state) {
          final surahNumber = int.parse(state.pathParameters['surahNumber']!);
          final swipe = state.uri.queryParameters['swipe'];
          final isMushaf = state.uri.queryParameters['mode'] == 'mushaf' ||
              state.uri.queryParameters['mushaf'] == 'true';
          final page = state.uri.queryParameters['page'] != null
              ? int.tryParse(state.uri.queryParameters['page']!)
              : null;
          final verse = state.uri.queryParameters['verse'] != null
              ? int.tryParse(state.uri.queryParameters['verse']!)
              : null;
          return NoTransitionPage(
            key: ValueKey('surah-$surahNumber-mushaf-$isMushaf-page-$page-verse-$verse'),
            child: SurahPage(
              surahNumber: surahNumber,
              initialVerseNumber: verse,
              initialPageNumber: page,
              initialMushafMode: isMushaf,
              swipeDirection: swipe,
            ),
          );
        },
      ),

      // Verse Page (/surah/15/verse/34)
      GoRoute(
        path: '/surah/:surahNumber/verse/:verseNumber',
        name: 'verse',
        pageBuilder: (context, state) {
          final surahNumber = int.parse(state.pathParameters['surahNumber']!);
          final verseNumber = int.parse(state.pathParameters['verseNumber']!);
          final swipe = state.uri.queryParameters['swipe'];
          final isMushaf = state.uri.queryParameters['mode'] == 'mushaf' ||
              state.uri.queryParameters['mushaf'] == 'true';
          final page = state.uri.queryParameters['page'] != null
              ? int.tryParse(state.uri.queryParameters['page']!)
              : null;
          return NoTransitionPage(
            key: ValueKey('surah-$surahNumber-verse-$verseNumber-mushaf-$isMushaf'),
            child: SurahPage(
              surahNumber: surahNumber,
              initialVerseNumber: verseNumber,
              initialPageNumber: page,
              initialMushafMode: isMushaf,
              swipeDirection: swipe,
            ),
          );
        },
      ),

      // Mushaf View (604 pages)
      GoRoute(
        path: '/mushaf',
        name: 'mushaf',
        pageBuilder: (context, state) {
          final page = state.uri.queryParameters['page'] != null
              ? int.tryParse(state.uri.queryParameters['page']!)
              : null;
          final surah = state.uri.queryParameters['surah'] != null
              ? int.tryParse(state.uri.queryParameters['surah']!)
              : 1;
          return NoTransitionPage(
            key: ValueKey('mushaf-page-$page-surah-$surah'),
            child: SurahPage(
              surahNumber: surah ?? 1,
              initialPageNumber: page,
              initialMushafMode: true,
            ),
          );
        },
      ),

      // Search & Navigator Page
      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (context, state) {
          final q = state.uri.queryParameters['q'];
          final filter = state.uri.queryParameters['filter'];
          final surah = state.uri.queryParameters['surah'] != null
              ? int.tryParse(state.uri.queryParameters['surah']!)
              : null;
          final verse = state.uri.queryParameters['verse'] != null
              ? int.tryParse(state.uri.queryParameters['verse']!)
              : null;

          return NoTransitionPage(
            child: SearchPage(
              initialQuery: q,
              initialFilter: filter,
              initialSurah: surah,
              initialVerse: verse,
            ),
          );
        },
      ),

      // Bookmarks Page
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: BookmarksPage(userId: 'local'),
        ),
      ),

      // Settings Page
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SettingsPage(),
        ),
      ),



      // Quran Pages Menu
      GoRoute(
        path: '/quran-pages',
        name: 'quran_pages',
        builder: (context, state) => const PagesMenuPage(),
      ),
    ],
  );
});

class QuranApp extends ConsumerWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Тафсири Осонбаён',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

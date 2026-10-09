import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/app.dart';
import '../../data/services/audio_service.dart';
import 'app_link_mapper.dart';

/// Subscribes to Android App Links / iOS universal links via [app_links] and
/// navigates using the shared [routerProvider] [GoRouter].
class AppDeepLinkListener extends ConsumerStatefulWidget {
  final Widget child;

  const AppDeepLinkListener({super.key, required this.child});

  @override
  ConsumerState<AppDeepLinkListener> createState() =>
      _AppDeepLinkListenerState();
}

class _AppDeepLinkListenerState extends ConsumerState<AppDeepLinkListener> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen(_onAppLink);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initial = await _appLinks.getInitialLink();
        _onAppLink(initial);
      } catch (e) {
        debugPrint('[AppDeepLinkListener] getInitialLink error: $e');
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _onAppLink(Uri? uri) {
    if (uri == null || !mounted) return;

    // Intercept widget controls (prevents router navigation when buttons are clicked)
    if (uri.path.startsWith('/audiowidget/')) {
      final action = uri.pathSegments.last;
      final audioService = QuranAudioService();
      
      () async {
        try {
          final prefs = await SharedPreferences.getInstance();
          final lastSurah = prefs.getInt('widget_last_surah') ?? 1;
          final lastQari = prefs.getString('widget_last_qari') ?? 'ar.alafasy';

          if (action == 'toggle') {
            if (audioService.isPlaying) {
              await audioService.pause();
            } else if (audioService.currentSurahNumber != null) {
              await audioService.resume();
            } else {
              await audioService.playSurah(lastSurah, edition: lastQari);
            }
          } else if (action == 'next') {
            await audioService.playNextSurah(edition: audioService.currentEdition);
          } else if (action == 'prev') {
            await audioService.playPreviousSurah(edition: audioService.currentEdition);
          }
        } catch (e) {
          debugPrint('[AppDeepLinkListener] Widget action error: $e');
        }
      }();
      return;
    }

    final initialLocation = AppLinkMapper.toGoLocation(uri);
    if (initialLocation == null) return;

    final String location;
    if (initialLocation == '/audio-home/player') {
      final audioService = QuranAudioService();
      if (!audioService.isPlaying && audioService.currentSurahNumber == null) {
        location = '/audio-home';
      } else {
        location = initialLocation;
      }
    } else {
      location = initialLocation;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        ref.read(routerProvider).go(location);
      } catch (e) {
        debugPrint('[AppDeepLinkListener] go($location) error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

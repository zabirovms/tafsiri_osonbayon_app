import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';

class BottomNavigationBarWidget extends ConsumerStatefulWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  ConsumerState<BottomNavigationBarWidget> createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState
    extends ConsumerState<BottomNavigationBarWidget> {
  int _activeIndex = 0; // Default to Quran

  int _getActiveIndex(String? location) {
    if (location == null ||
        location == '/' ||
        location == '/quran' ||
        location.startsWith('/surah/') ||
        location.startsWith('/mushaf')) {
      return 0; // Quran
    }
    if (location == '/search' || location.startsWith('/search')) {
      return 1; // Navigator / Search
    }
    if (location == '/bookmarks' || location.startsWith('/bookmarks')) {
      return 2; // Bookmarks
    }
    if (location == '/settings' || location.startsWith('/settings')) {
      return 3; // Settings
    }
    return 0;
  }

  void _updateIndexFromRoute() {
    final routerState = GoRouterState.of(context);
    final location = routerState.uri.path;
    final routeIndex = _getActiveIndex(location);

    if (_activeIndex != routeIndex && mounted) {
      setState(() {
        _activeIndex = routeIndex;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateIndexFromRoute();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final routerState = GoRouterState.of(context);
    final location = routerState.uri.path;
    final routeIndex = _getActiveIndex(location);

    if (_activeIndex != routeIndex && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _activeIndex = routeIndex;
          });
        }
      });
    }

    return NavigationBar(
      selectedIndex: _activeIndex,
      elevation: 0,
      height: 64,
      backgroundColor: theme.scaffoldBackgroundColor,
      indicatorColor: colorScheme.primaryContainer,
      onDestinationSelected: (index) {
        if (index == _activeIndex) return;
        setState(() {
          _activeIndex = index;
        });

        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/search');
            break;
          case 2:
            context.go('/bookmarks');
            break;
          case 3:
            context.go('/settings');
            break;
        }
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(FlutterIslamicIcons.quran),
          selectedIcon: Icon(FlutterIslamicIcons.quran),
          label: 'Қуръон',
        ),
        const NavigationDestination(
          icon: Icon(Icons.search),
          selectedIcon: Icon(Icons.search),
          label: 'Ҷустуҷӯ',
        ),
        const NavigationDestination(
          icon: Icon(Icons.bookmark_border),
          selectedIcon: Icon(Icons.bookmark),
          label: 'Захираҳо',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Танзимот',
        ),
      ],
    );
  }
}

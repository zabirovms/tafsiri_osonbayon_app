import 'package:flutter/material.dart';

/// Used by main menu home to detect when another route is pushed on top, so hero
/// status bar styling does not leak over other screens.
final RouteObserver<PageRoute<dynamic>> mainMenuSystemUiRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

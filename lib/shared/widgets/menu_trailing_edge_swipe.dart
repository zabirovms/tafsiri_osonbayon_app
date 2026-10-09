import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Opens [route] when the user swipes horizontally across the screen in the
/// direction that reveals the trailing-side menu (LTR: right → left; RTL: left → right).
///
/// Uses a [Listener] so vertical [ListView] scrolling keeps working; only gestures
/// that are clearly horizontal and long enough (or a fast horizontal fling) open the menu.
class MenuTrailingEdgeSwipe extends StatefulWidget {
  const MenuTrailingEdgeSwipe({
    super.key,
    required this.child,
    this.route = '/settings',
    this.minDistance = 56,
    this.horizontalVsVerticalRatio = 1.25,
    this.flingMinHorizontalSpeed = 520,
  });

  final Widget child;
  final String route;

  /// Minimum horizontal travel (logical pixels) to treat as an intentional swipe.
  final double minDistance;

  /// Horizontal delta must exceed vertical delta by this factor.
  final double horizontalVsVerticalRatio;

  /// If horizontal speed exceeds this (px/s) and dominates vertical, open even when travel is short.
  final double flingMinHorizontalSpeed;

  @override
  State<MenuTrailingEdgeSwipe> createState() => _MenuTrailingEdgeSwipeState();
}

class _MenuTrailingEdgeSwipeState extends State<MenuTrailingEdgeSwipe> {
  final Map<int, Offset> _pointerStarts = {};
  final Map<int, VelocityTracker> _velocityTrackers = {};

  bool _openDirectionMatchesDx(double dx) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (rtl) {
      return dx > 0;
    }
    return dx < 0;
  }

  bool _openDirectionMatchesVelocity(Offset v) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    if (rtl) {
      return v.dx > 0;
    }
    return v.dx < 0;
  }

  void _maybeOpenFromDrag(Offset? start, Offset end) {
    if (start == null || !context.mounted) return;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    if (dx.abs() < widget.minDistance) return;
    if (dx.abs() < dy.abs() * widget.horizontalVsVerticalRatio) return;
    if (!_openDirectionMatchesDx(dx)) return;
    context.push(widget.route);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _pointerStarts[event.pointer] = event.position;
        final tracker = VelocityTracker.withKind(event.kind);
        tracker.addPosition(event.timeStamp, event.position);
        _velocityTrackers[event.pointer] = tracker;
      },
      onPointerMove: (event) {
        _velocityTrackers[event.pointer]?.addPosition(
          event.timeStamp,
          event.position,
        );
      },
      onPointerUp: (event) {
        final start = _pointerStarts.remove(event.pointer);
        final tracker = _velocityTrackers.remove(event.pointer);
        if (tracker != null && context.mounted) {
          final v = tracker.getVelocity().pixelsPerSecond;
          final horizontalDominant =
              v.dx.abs() > v.dy.abs() && v.dx.abs() > widget.flingMinHorizontalSpeed;
          if (horizontalDominant && _openDirectionMatchesVelocity(v)) {
            context.push(widget.route);
            return;
          }
        }
        _maybeOpenFromDrag(start, event.position);
      },
      onPointerCancel: (event) {
        _pointerStarts.remove(event.pointer);
        _velocityTrackers.remove(event.pointer);
      },
      child: widget.child,
    );
  }
}

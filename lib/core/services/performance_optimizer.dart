import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  Timer? _memoryCleanupTimer;
  Timer? _cacheCleanupTimer;
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, int> _accessCounts = {};

  // Initialize performance optimizations
  Future<void> initialize() async {
    _startMemoryCleanup();
    _startCacheCleanup();
    _optimizeSystemSettings();
  }

  // Memory management
  void _startMemoryCleanup() {
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _cleanupMemory(),
    );
  }

  void _cleanupMemory() {
    // Force garbage collection (only on mobile platforms)
    if (!kIsWeb) {
      try {
        SystemChannels.platform.invokeMethod('System.gc');
      } catch (e) {
        // Ignore errors on platforms that don't support this
      }
    }
    
    // Clear old cache entries
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      return now.difference(timestamp).inMinutes > 30;
    });
  }

  // Cache management
  void _startCacheCleanup() {
    _cacheCleanupTimer = Timer.periodic(
      const Duration(hours: 1),
      (timer) => _cleanupCache(),
    );
  }

  void _cleanupCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp).inHours > 24) {
        keysToRemove.add(key);
      }
    });
    
    for (final key in keysToRemove) {
      _cacheTimestamps.remove(key);
      _accessCounts.remove(key);
    }
  }

  // Track cache access
  void trackCacheAccess(String key) {
    _cacheTimestamps[key] = DateTime.now();
    _accessCounts[key] = (_accessCounts[key] ?? 0) + 1;
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEntries': _cacheTimestamps.length,
      'mostAccessed': _getMostAccessedKey(),
      'oldestEntry': _getOldestEntry(),
    };
  }

  String? _getMostAccessedKey() {
    if (_accessCounts.isEmpty) return null;
    return _accessCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  DateTime? _getOldestEntry() {
    if (_cacheTimestamps.isEmpty) return null;
    return _cacheTimestamps.values
        .reduce((a, b) => a.isBefore(b) ? a : b);
  }

  // System optimizations
  void _optimizeSystemSettings() {
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Note: System UI overlay style is now managed by _StatusBarVisibilityWrapper
    // in main.dart to ensure navigation bar is always visible with proper color
    // We don't set it here to avoid overriding the theme-based color
  }

  // Image optimization
  static Widget optimizedImage({
    required String imageUrl,
    required Widget placeholder,
    required Widget errorWidget,
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder;
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget;
      },
      // Enable caching
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
    );
  }

  // List optimization
  static Widget optimizedListView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Performance optimizations
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
    );
  }

  // Grid optimization
  static Widget optimizedGridView({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Performance optimizations
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
    );
  }

  // Text optimization
  static Widget optimizedText(
    String text, {
    TextStyle? style,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
    TextDirection? textDirection,
  }) {
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      textDirection: textDirection,
      // Performance optimizations
      softWrap: true,
      textScaleFactor: 1.0,
    );
  }

  // Dispose resources
  void dispose() {
    _memoryCleanupTimer?.cancel();
    _cacheCleanupTimer?.cancel();
    _cacheTimestamps.clear();
    _accessCounts.clear();
  }
}

// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  int _frameCount = 0;
  int _lastFrameCount = 0;
  DateTime _lastTime = DateTime.now();
  double _fps = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPersistentFrameCallback(_onFrame);
    }
  }

  void _onFrame(Duration timeStamp) {
    if (!widget.enabled) return;
    
    _frameCount++;
    final now = DateTime.now();
    final elapsed = now.difference(_lastTime).inMilliseconds;
    
    if (elapsed >= 1000) {
      _fps = (_frameCount - _lastFrameCount) * 1000 / elapsed;
      _lastFrameCount = _frameCount;
      _lastTime = now;
      
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'FPS: ${_fps.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Memory usage widget
class MemoryUsageWidget extends StatefulWidget {
  final bool enabled;

  const MemoryUsageWidget({
    super.key,
    this.enabled = false,
  });

  @override
  State<MemoryUsageWidget> createState() => _MemoryUsageWidgetState();
}

class _MemoryUsageWidgetState extends State<MemoryUsageWidget> {
  Timer? _timer;
  String _memoryUsage = '0 MB';

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) => _updateMemoryUsage(),
    );
  }

  void _updateMemoryUsage() {
    // Memory usage is only available on native platforms, not web
    if (kIsWeb) {
      _memoryUsage = 'N/A (Web)';
    } else {
      // This is a simplified memory usage calculation
      // In a real app, you'd use platform channels to get actual memory usage
      _memoryUsage = 'N/A';
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    
    return Positioned(
      top: 80,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Memory: $_memoryUsage',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

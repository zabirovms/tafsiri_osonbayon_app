import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/utils/reciter_image_helper.dart';

/// Widget that loads reciter images using exact filename mapping
/// Shows placeholder for unmapped reciters
class ReciterImage extends StatefulWidget {
  final String reciterId;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ReciterImage({
    super.key,
    required this.reciterId,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<ReciterImage> createState() => _ReciterImageState();
}

class _ReciterImageState extends State<ReciterImage> {
  String? _imageUrl;
  /// After one network failure, show a static fallback and remove [CachedNetworkImage]
  /// so nothing keeps retrying or re-entering error builders.
  bool _networkLoadFailed = false;
  bool _loggedNetworkFailure = false;
  bool _loggedNetworkSuccess = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = ReciterImageHelper.getReciterPhotoUrl(widget.reciterId);
    if (kDebugMode) {
      if (_imageUrl != null) {
        debugPrint('[ReciterImage] Loading image for ${widget.reciterId}: $_imageUrl');
      } else {
        debugPrint('[ReciterImage] No mapping for ${widget.reciterId}, showing placeholder');
      }
    }
  }

  @override
  void didUpdateWidget(ReciterImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reciterId != widget.reciterId) {
      _imageUrl = ReciterImageHelper.getReciterPhotoUrl(widget.reciterId);
      _networkLoadFailed = false;
      _loggedNetworkFailure = false;
      _loggedNetworkSuccess = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_imageUrl == null) {
      return widget.errorWidget ?? _defaultErrorWidget();
    }

    final isLocal = ReciterImageHelper.isLocalAsset(_imageUrl);

    Widget imageWidget;

    if (isLocal) {
      imageWidget = Image.asset(
        _imageUrl!,
        fit: widget.fit,
        alignment: widget.alignment,
        errorBuilder: (context, error, stackTrace) {
          if (kDebugMode) {
            debugPrint('[ReciterImage] Failed to load local asset $_imageUrl: $error');
          }
          return widget.errorWidget ?? _defaultErrorWidget();
        },
      );
    } else if (_networkLoadFailed) {
      imageWidget = widget.errorWidget ?? _defaultErrorWidget();
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: _imageUrl!,
        key: ValueKey('reciter_image_${widget.reciterId}'),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        alignment: widget.alignment,
        memCacheWidth: widget.width != null && widget.width!.isFinite ? widget.width!.toInt() : null,
        memCacheHeight: widget.height != null && widget.height!.isFinite ? widget.height!.toInt() : null,
        maxWidthDiskCache: 500,
        maxHeightDiskCache: 500,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 100),
        placeholder: (context, url) => widget.placeholder ?? _defaultPlaceholder(),
        errorWidget: (context, url, error) {
          if (!_loggedNetworkFailure) {
            _loggedNetworkFailure = true;
            if (kDebugMode) {
              debugPrint('[ReciterImage] Failed to load $_imageUrl: $error');
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _networkLoadFailed = true);
              }
            });
          }
          return widget.errorWidget ?? _defaultErrorWidget();
        },
        imageBuilder: (context, imageProvider) {
          if (!_loggedNetworkSuccess) {
            _loggedNetworkSuccess = true;
            if (kDebugMode) {
              debugPrint('[ReciterImage] Successfully loaded $_imageUrl');
            }
          }
          return Image(
            image: imageProvider,
            fit: widget.fit,
            alignment: widget.alignment,
          );
        },
      );
    }

    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    if (widget.width != null || widget.height != null) {
      imageWidget = SizedBox(
        width: widget.width,
        height: widget.height,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _defaultPlaceholder() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final baseColor = colorScheme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);
    final highlightColor = colorScheme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.1);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }

  Widget _defaultErrorWidget() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final size = widget.width ?? widget.height ?? 48.0;
    final iconSize = size * 0.5;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: widget.borderRadius,
      ),
      child: Icon(
        Icons.person_outline,
        size: iconSize,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
    );
  }
}

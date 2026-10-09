import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingWidget extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isShimmer;
  final LoadingType type;
  final Color? baseColor;
  final Color? highlightColor;

  const LoadingWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.isShimmer = true,
    this.type = LoadingType.rectangle,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isShimmer) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Enhanced color scheme using solid theme container colors for distinct visibility
    final base = widget.baseColor ?? 
        (isDark 
            ? theme.colorScheme.surfaceContainerHigh 
            : theme.colorScheme.surfaceContainerHighest);
    final highlight = widget.highlightColor ?? 
        (isDark 
            ? theme.colorScheme.surfaceContainerHighest 
            : theme.colorScheme.surface);
    
    // Solid gradient colors to prevent transparency from washing out the shimmer mask
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        base,
        highlight,
        base,
      ],
    );

    Widget content = _buildContent(theme, gradient, base, highlight);

    if (widget.isShimmer) {
      return Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        period: const Duration(milliseconds: 1000),
        direction: ShimmerDirection.ltr,
        child: content,
      );
    }

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: content,
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme, LinearGradient gradient, Color base, Color highlight) {
    final isDark = theme.brightness == Brightness.dark;
    
    switch (widget.type) {
      case LoadingType.rectangle:
        return Container(
          width: widget.width,
          height: widget.height ?? 20,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            border: Border.all(
              color: isDark 
                  ? Colors.grey[700]!.withValues(alpha: 0.3)
                  : Colors.grey[300]!.withValues(alpha: 0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      
      case LoadingType.circle:
        return Container(
          width: widget.width ?? widget.height ?? 40,
          height: widget.height ?? widget.width ?? 40,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        );
      
      case LoadingType.card:
        return Container(
          width: widget.width,
          height: widget.height ?? 120,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withValues(alpha: 0.15)
                    : Colors.grey.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 12,
                  width: 200,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      
      case LoadingType.text:
        return Container(
          width: widget.width,
          height: widget.height ?? 16,
          decoration: BoxDecoration(
            color: base,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        );
    }
  }
}

enum LoadingType {
  rectangle,
  circle,
  card,
  text,
}

class LoadingListWidget extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;
  final LoadingType itemType;
  final bool isShimmer;

  const LoadingListWidget({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.padding,
    this.itemType = LoadingType.rectangle,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: LoadingWidget(
            height: itemHeight,
            type: itemType,
            isShimmer: isShimmer,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }
}

class LoadingGridWidget extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final LoadingType itemType;
  final bool isShimmer;

  const LoadingGridWidget({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.5,
    this.padding,
    this.itemType = LoadingType.card,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LoadingWidget(
          type: itemType,
          isShimmer: isShimmer,
          borderRadius: BorderRadius.circular(12),
        );
      },
    );
  }
}

// Specialized loading widgets for common use cases
class LoadingCardWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isShimmer;

  const LoadingCardWidget({
    super.key,
    this.width,
    this.height,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return LoadingWidget(
      width: width,
      height: height ?? 120,
      type: LoadingType.card,
      isShimmer: isShimmer,
      borderRadius: BorderRadius.circular(12),
    );
  }
}

class LoadingTextWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final int lines;
  final bool isShimmer;

  const LoadingTextWidget({
    super.key,
    this.width,
    this.height,
    this.lines = 3,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        lines,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? 8 : 0),
          child: LoadingWidget(
            width: index == lines - 1 ? (width ?? 200) * 0.7 : width,
            height: height ?? 16,
            type: LoadingType.text,
            isShimmer: isShimmer,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Full-screen loading widget that fills available space with shimmer cards
class LoadingFullScreenWidget extends StatelessWidget {
  final Color? backgroundColor;
  final int itemCount;
  final bool isShimmer;
  final double itemHeight;
  final EdgeInsets? padding;
  final EdgeInsets? itemPadding;
  final BorderRadius? borderRadius;

  const LoadingFullScreenWidget({
    super.key,
    this.backgroundColor,
    this.itemCount = 8,
    this.isShimmer = true,
    this.itemHeight = 120,
    this.padding,
    this.itemPadding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: backgroundColor ?? theme.scaffoldBackgroundColor,
      child: ListView.builder(
        padding: padding ?? const EdgeInsets.all(16),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: itemPadding ?? const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: borderRadius ?? BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 1. Leading number box: 48x48 square
                  LoadingWidget(
                    width: 48,
                    height: 48,
                    type: LoadingType.rectangle,
                    borderRadius: BorderRadius.circular(12),
                    isShimmer: isShimmer,
                  ),
                  const SizedBox(width: 16),
                  
                  // 2. Center details: Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LoadingWidget(
                          width: 120,
                          height: 16,
                          type: LoadingType.rectangle,
                          borderRadius: BorderRadius.circular(4),
                          isShimmer: isShimmer,
                        ),
                        const SizedBox(height: 8),
                        LoadingWidget(
                          width: 80,
                          height: 12,
                          type: LoadingType.rectangle,
                          borderRadius: BorderRadius.circular(4),
                          isShimmer: isShimmer,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // 3. Trailing Arabic SVG name pill: 80x32
                  LoadingWidget(
                    width: 80,
                    height: 32,
                    type: LoadingType.rectangle,
                    borderRadius: BorderRadius.circular(20),
                    isShimmer: isShimmer,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Deprecated: Use LoadingFullScreenWidget or LoadingListWidget instead
@Deprecated('Use LoadingFullScreenWidget or LoadingListWidget instead')
class LoadingCircularWidget extends StatelessWidget {
  final double? size;
  final bool isShimmer;
  final bool fullScreen;
  final Color? backgroundColor;

  const LoadingCircularWidget({
    super.key,
    this.size,
    this.isShimmer = true,
    this.fullScreen = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (fullScreen) {
      return LoadingFullScreenWidget(
        backgroundColor: backgroundColor,
        isShimmer: isShimmer,
      );
    }
    // For non-fullscreen, return empty to avoid circular widget
    return const SizedBox.shrink();
  }
}

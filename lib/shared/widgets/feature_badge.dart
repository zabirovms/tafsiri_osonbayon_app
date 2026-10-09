import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/feature_badges_config.dart';
import '../../presentation/providers/feature_badge_provider.dart';

class BadgeDot extends StatelessWidget {
  final Color? color;
  final double size;

  const BadgeDot({
    super.key,
    this.color,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.red;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: 0.5),
            blurRadius: 4,
            spreadRadius: 1.5,
          ),
        ],
      ),
    );
  }
}

class BadgeLabel extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets padding;

  const BadgeLabel({
    super.key,
    this.text = 'НАВ', // Localized to Tajik
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg = backgroundColor ?? theme.colorScheme.error;
    final effectiveText = textColor ?? Colors.white;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: effectiveBg.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: effectiveText,
          fontWeight: FontWeight.w900,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BadgeCounter extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const _BadgeCounter({
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final countText = count > 99 ? '99+' : '$count';
    final effectiveBg = backgroundColor ?? theme.colorScheme.error;
    final effectiveText = textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: effectiveBg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: effectiveBg.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      alignment: Alignment.center,
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        countText,
        style: theme.textTheme.labelSmall?.copyWith(
          color: effectiveText,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AppBadge extends ConsumerWidget {
  final String featureId;
  final Widget child;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final FeatureBadgeType? badgeTypeOverride;
  final String? labelTextOverride;
  final Color? badgeColorOverride;
  final Color? textColorOverride;

  const AppBadge({
    super.key,
    required this.featureId,
    required this.child,
    this.top = -3,
    this.right = -3,
    this.bottom,
    this.left,
    this.badgeTypeOverride,
    this.labelTextOverride,
    this.badgeColorOverride,
    this.textColorOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(featureBadgeVisibleProvider(featureId));

    final config = FeatureBadges.configs[featureId];
    final type = badgeTypeOverride ?? config?.type ?? FeatureBadgeType.dot;

    Widget badgeWidget;
    switch (type) {
      case FeatureBadgeType.dot:
        badgeWidget = BadgeDot(color: badgeColorOverride);
        break;
      case FeatureBadgeType.label:
        badgeWidget = BadgeLabel(
          text: labelTextOverride ?? 'НАВ',
          backgroundColor: badgeColorOverride,
          textColor: textColorOverride,
        );
        break;
      case FeatureBadgeType.counter:
        final count = ref.watch(featureBadgeCountProvider(featureId));
        badgeWidget = _BadgeCounter(
          count: count,
          backgroundColor: badgeColorOverride,
          textColor: textColorOverride,
        );
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: top,
          right: right,
          bottom: bottom,
          left: left,
          child: IgnorePointer(
            child: AnimatedScale(
              scale: isVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: badgeWidget,
            ),
          ),
        ),
      ],
    );
  }
}

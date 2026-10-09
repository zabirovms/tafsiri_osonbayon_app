import 'package:flutter/material.dart';

class BottomSheetHelper {
  /// Shows a standard bottom sheet with uniform styling.
  static Future<T?> showStandard<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    bool showDragHandle = true,
    double? maxHeightMultiplier, // e.g. 0.8 to restrict maximum height
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final content = builder(context);
        if (maxHeightMultiplier != null) {
          return SafeArea(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * maxHeightMultiplier,
              ),
              child: content,
            ),
          );
        }
        return SafeArea(child: content);
      },
    );
  }

  /// Shows a draggable, scrollable bottom sheet with uniform styling.
  static Future<T?> showScrollable<T>({
    required BuildContext context,
    required ScrollableWidgetBuilder builder,
    double initialChildSize = 0.5,
    double minChildSize = 0.25,
    double maxChildSize = 0.9,
    bool showDragHandle = true,
    Color? backgroundColor,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: backgroundColor ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: initialChildSize,
          minChildSize: minChildSize,
          maxChildSize: maxChildSize,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showDragHandle) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child: builder(context, scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomErrorWidget extends StatefulWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData? icon;
  final String? title;
  final bool showFeedbackButton;
  final String? errorDetails;
  final bool? isNetworkError;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon,
    this.title,
    this.showFeedbackButton = true,
    this.errorDetails,
    this.isNetworkError,
  });

  @override
  State<CustomErrorWidget> createState() => _CustomErrorWidgetState();
}

class _CustomErrorWidgetState extends State<CustomErrorWidget> {
  bool _isRetrying = false;

  bool get _isNetwork {
    if (widget.isNetworkError != null) return widget.isNetworkError!;
    final text = '${widget.title ?? ''} ${widget.message}'.toLowerCase();
    return text.contains('интернет') ||
        text.contains('пайваст') ||
        text.contains('офлайн') ||
        text.contains('network') ||
        text.contains('connection') ||
        text.contains('socketexception');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isNetError = _isNetwork;

    final displayIcon = widget.icon ?? (isNetError ? Icons.wifi_off_rounded : Icons.error_outline);
    final iconColor = isNetError ? cs.primary : cs.error;
    final shouldShowFeedback = widget.showFeedbackButton && !isNetError;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              displayIcon,
              size: 64,
              color: iconColor,
            ),
            const SizedBox(height: 16),
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              widget.message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.onRetry != null || shouldShowFeedback) ...[
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (widget.onRetry != null)
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_isRetrying) return;
                        setState(() {
                          _isRetrying = true;
                        });
                        try {
                          widget.onRetry!.call();
                        } catch (_) {}
                        // Keep the spinner visible for at least 800ms for visual feedback
                        await Future.delayed(const Duration(milliseconds: 800));
                        if (mounted) {
                          setState(() {
                            _isRetrying = false;
                          });
                        }
                      },
                      icon: _isRetrying
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                              ),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(_isRetrying ? 'Дар ҳоли такрор...' : 'Аз нав такрор'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  if (shouldShowFeedback)
                    OutlinedButton.icon(
                      onPressed: () {
                        final encodedMsg = Uri.encodeComponent(widget.errorDetails ?? widget.message);
                        GoRouter.of(context).push(
                          '/feedback?source=custom_error_widget&category=Bug&text=$encodedMsg',
                        );
                      },
                      icon: const Icon(Icons.bug_report_outlined, size: 18),
                      label: const Text('Гузориш додан'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String message;
  final IconData? icon;
  final String? title;
  final Widget? action;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.icon,
    this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

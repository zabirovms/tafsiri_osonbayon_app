import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ErrorReportDialog extends StatelessWidget {
  final String errorMessage;

  const ErrorReportDialog({super.key, required this.errorMessage});

  /// Shows the error report dialog
  static Future<void> show(BuildContext context, {required String errorMessage}) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => ErrorReportDialog(errorMessage: errorMessage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: cs.error, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Хатогӣ рух дод',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ҳангоми иҷрои амал хатогӣ ба амал омад. Шумо метавонед ба мо дар ҳалли ин мушкилот кӯмак расонед.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.errorContainer.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.error.withValues(alpha: 0.15)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: SingleChildScrollView(
                child: Text(
                  errorMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: cs.error,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Пӯшидан',
            style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            final encodedMsg = Uri.encodeComponent(errorMessage);
            // Navigate to feedback page pre-filled with the error
            GoRouter.of(context).push(
              '/feedback?source=error_report&category=Bug&text=$encodedMsg',
            );
          },
          icon: const Icon(Icons.bug_report_outlined, size: 18),
          label: const Text('Гузориш додан'),
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

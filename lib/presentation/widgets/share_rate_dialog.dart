import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/services/app_rating_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/share_helper.dart';

/// Dialog for prompting users to share and rate the app
/// Designed to be non-intrusive and user-friendly
class ShareRateDialog extends StatelessWidget {
  const ShareRateDialog({super.key});

  /// Show the dialog if conditions are met
  static Future<void> showIfNeeded(BuildContext context) async {
    final shouldShow = await AppRatingService.shouldShowPrompt();
    if (shouldShow && context.mounted) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const ShareRateDialog(),
      );
    }
  }

  /// Show the dialog manually (e.g., from settings)
  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ShareRateDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                color: colorScheme.onPrimaryContainer,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Барномаро дастгирӣ кунед',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'Агар барнома ба шумо писанд омад, лутфан онро бо дӯстон ва наздикон мубодила кунед ё дар Play Store баҳо диҳед. Аллоҳ аз шумо розӣ бошад!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Share button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleShare(context),
                    icon: const Icon(Icons.share, size: 20),
                    label: const Text('Мубодила'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Rate button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleRate(context),
                    icon: const Icon(Icons.star, size: 20),
                    label: const Text('Баҳо'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Dismiss button
            TextButton(
              onPressed: () => _handleDismiss(context, neverShowAgain: false),
              child: Text(
                'Баъдтар',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    final origin = ShareHelper.getSharePositionOrigin(context);
    Navigator.of(context).pop();
    
    try {
      final String downloadUrl;
      if (Platform.isIOS) {
        downloadUrl = 'https://apps.apple.com/app/id6787344485';
      } else {
        const packageName = 'com.quran.tj.osonbayon';
        downloadUrl = 'https://play.google.com/store/apps/details?id=$packageName';
      }
      
      final shareText = '${AppConstants.appName}\n\n'
          'Боргирӣ кардан: $downloadUrl';

      await Share.share(
        shareText,
        subject: AppConstants.appName,
        sharePositionOrigin: origin,
      );

      await AppRatingService.markUserShared();
    } catch (e) {
      // Handle error silently
      debugPrint('Error sharing: $e');
    }
  }

  Future<void> _handleRate(BuildContext context) async {
    Navigator.of(context).pop();
    await AppRatingService.requestInAppReview();
  }

  Future<void> _handleDismiss(BuildContext context, {required bool neverShowAgain}) async {
    Navigator.of(context).pop();
    await AppRatingService.markUserDismissed(neverShowAgain: neverShowAgain);
  }
}


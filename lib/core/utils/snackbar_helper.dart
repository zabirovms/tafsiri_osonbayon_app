import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:flutter/material.dart';
import '../../presentation/widgets/error_report_dialog.dart';

class SnackBarHelper {
  static void showSuccess({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      title: title ?? 'Бобарор',
      message: message,
      contentType: ContentType.success,
      duration: duration,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context: context,
      title: title ?? 'Хатогӣ',
      message: message,
      contentType: ContentType.failure,
      duration: duration,
    );
  }

  static void showErrorDialog({
    required BuildContext context,
    required String message,
  }) {
    ErrorReportDialog.show(context, errorMessage: message);
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      title: title ?? 'Огоҳӣ',
      message: message,
      contentType: ContentType.warning,
      duration: duration,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context: context,
      title: title ?? 'Маълумот',
      message: message,
      contentType: ContentType.help,
      duration: duration,
    );
  }

  static void _show({
    required BuildContext context,
    required String title,
    required String message,
    required ContentType contentType,
    required Duration duration,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color? snackbarColor;
    
    if (contentType == ContentType.success) {
      snackbarColor = colorScheme.primary;
    } else if (contentType == ContentType.failure) {
      snackbarColor = colorScheme.error;
    } else if (contentType == ContentType.warning) {
      snackbarColor = colorScheme.tertiary;
    } else if (contentType == ContentType.help) {
      snackbarColor = colorScheme.secondary;
    }

    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      content: AwesomeSnackbarContent(
        title: title,
        message: message,
        contentType: contentType,
        color: snackbarColor,
      ),
    );

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(snackBar);
  }
}

import 'package:flutter/material.dart';
import 'package:qcf_quran/qcf_quran.dart';

/// Helper to generate dynamic QcfThemeData for Mushaf mode (15-line view).
class MushafThemeHelper {
  static QcfThemeData getTheme(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isDark) {
      return QcfThemeData.dark().copyWith(
        pageBackgroundColor: theme.scaffoldBackgroundColor,
        verseTextColor: cs.onSurface,
        verseNumberColor: cs.primary,
        basmalaColor: cs.onSurface,
        headerTextColor: cs.onSurface,
      );
    } else {
      return QcfThemeData(
        pageBackgroundColor: theme.scaffoldBackgroundColor,
        verseTextColor: cs.onSurface,
        verseNumberColor: cs.primary,
        basmalaColor: cs.onSurface,
        headerTextColor: cs.onSurface,
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';

class AppTheme {
  // Background paper style presets (Light & Dark)
  static (Color scaffold, Color card, Color text, Color border) getLightStyleColors(String style) {
    switch (style) {
      case 'light_sepia': // Warm Sepia / Anti-Blue Light
        return (const Color(0xFFFBF0D9), const Color(0xFFFFFDF7), const Color(0xFF3E2723), const Color(0xFFF5E5C9));
      case 'light_amber': // Warm Amber Cream
        return (const Color(0xFFFAF0E6), const Color(0xFFFFFBF7), const Color(0xFF3B2F2F), const Color(0xFFF2E6D9));
      case 'light_mint': // Soft Sage Mint / Islamic Green
        return (const Color(0xFFEAF5ED), const Color(0xFFF7FCF9), const Color(0xFF1B3B2B), const Color(0xFFD6EBE0));
      case 'light_slate': // Silver Slate / Clean Cool
        return (const Color(0xFFF1F5F9), const Color(0xFFFFFFFF), const Color(0xFF0F172A), const Color(0xFFE2E8F0));
      case 'light_rose': // Warm Dusk Rose
        return (const Color(0xFFFFF0F2), const Color(0xFFFFF9FA), const Color(0xFF3D2529), const Color(0xFFF7DDE2));
      case 'light_sand': // Natural Desert Sand
        return (const Color(0xFFF5EBE0), const Color(0xFFFAF5EF), const Color(0xFF382D26), const Color(0xFFE8DCD0));
      case 'light_classic': // Classic Warm Ivory (default)
      default:
        return (const Color(0xFFF4F3F0), const Color(0xFFFFFFFF), const Color(0xFF1A1917), const Color(0xFFE5E3DF));
    }
  }

  static (Color scaffold, Color card, Color text, Color border) getDarkStyleColors(String style) {
    switch (style) {
      case 'dark_navy': // Midnight Navy
        return (const Color(0xFF0B1325), const Color(0xFF152238), const Color(0xFFE2E8F0), const Color(0xFF1E2D4A));
      case 'dark_emerald': // Dark Forest Emerald
        return (const Color(0xFF061D17), const Color(0xFF0E2E25), const Color(0xFFE6F4F1), const Color(0xFF143E33));
      case 'dark_coffee': // Espresso Coffee / Eye Protection Dark
        return (const Color(0xFF181210), const Color(0xFF241C19), const Color(0xFFF5EBE6), const Color(0xFF332723));
      case 'dark_charcoal': // Soft Dark Charcoal
        return (const Color(0xFF161618), const Color(0xFF212124), const Color(0xFFF0F0F2), const Color(0xFF2C2C30));
      case 'dark_plum': // Soft Twilight Plum
        return (const Color(0xFF140E1B), const Color(0xFF1F1729), const Color(0xFFF1EAF8), const Color(0xFF2D223B));
      case 'dark_oled': // OLED Pure Black (default)
      default:
        return (const Color(0xFF09090B), const Color(0xFF16171A), const Color(0xFFF3F4F6), const Color(0xFF232427));
    }
  }

  static ThemeData lightFromAccent(Color accent, {String backgroundStyle = 'light_classic'}) {
    final (scaffold, card, text, border) = getLightStyleColors(backgroundStyle);
    final base = newLightTheme;
    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        primaryContainer: accent,
        surface: card,
        onSurface: text,
        outline: border,
        surfaceContainer: scaffold,
      ),
      cardTheme: base.cardTheme.copyWith(color: card),
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: text,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(color: text),
      ),
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: card,
        selectedItemColor: accent,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return const Color(0xFF908E89);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent.withValues(alpha: 0.45);
          return const Color(0xFFD5D3CE);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  static ThemeData darkFromAccent(Color accent, {String backgroundStyle = 'dark_oled'}) {
    final (scaffold, card, text, border) = getDarkStyleColors(backgroundStyle);
    final base = newDarkTheme;
    return base.copyWith(
      scaffoldBackgroundColor: scaffold,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        primaryContainer: accent,
        surface: card,
        onSurface: text,
        outline: border,
        surfaceContainer: scaffold,
      ),
      cardTheme: base.cardTheme.copyWith(color: card),
      appBarTheme: base.appBarTheme.copyWith(
        foregroundColor: text,
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(color: text),
      ),
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: card,
        selectedItemColor: accent,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return const Color(0xFFA5A5A8);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent.withValues(alpha: 0.45);
          return const Color(0xFF282A2F);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  // Color Palette - Light Theme (New Palette)
  static const Color primaryColor = Color(0xFF16697A); // Teal
  static const Color primaryVariant = Color(0xFF0F4F5F); // Darker teal
  static const Color secondaryColor = Color(0xFF698F3F); // Olive green
  static const Color accentColor = Color(0xFFD58936); // Orange
  
  static const Color backgroundColor = Color(0xFFDBDBDB); // Light gray
  static const Color surfaceColor = Color(0xFFFFFFFF); // White
  static const Color errorColor = Color(0xFFD32F2F); // Red
  
  // Dark Theme Colors
  static const Color darkBackgroundColor = Color(0xFF071029); // --bg
  static const Color darkSurfaceColor = Color(0xFF0d1a2b); // --surface
  static const Color darkPrimaryColor = Color(0xFF5ee0ff); // --accent
  static const Color darkTextColor = Color(0xFFe6f0ff); // --text
  static const Color darkMutedColor = Color(0xFF9fb0d4); // --muted
  static const Color darkButtonTextColor = Color(0xFF021524); // --btn-text
  static const Color darkCodeBackground = Color(0xFF041020); // --code-bg
  
  // Text Colors - Light Theme (New Palette)
  static const Color textPrimaryColor = Color(0xFF6F5E5C); // Brown/gray
  static const Color textSecondaryColor = Color(0xFF8A7A78); // Lighter brown/gray
  static const Color textHintColor = Color(0xFFBDBDBD);
  
  // Arabic Text Colors
  static const Color arabicTextColor = Color(0xFF6F5E5C); // Brown/gray (matches textPrimaryColor)
  static const Color arabicTextColorDark = Color(0xFFe6f0ff); // --text
  
  // Custom Themes Palettes
  // Soft Beige
  static const Color softBeigeBackground = Color(0xFFF5F0E1);
  static const Color softBeigeOnBackground = Color(0xFF5A4D3F);
  // Elegant Marble
  static const Color elegantMarbleBackground = Color(0xFFF8F4F0);
  static const Color elegantMarbleOnBackground = Color(0xFF5A4033);
  // Night Sky (dark)
  static const Color nightSkyBackground = Color(0xFF2C3E50);
  static const Color nightSkyOnBackground = Color(0xFFF5F3E7);
  // Silver Light
  static const Color silverLightBackground = Color(0xFFC0C0C0);
  static const Color silverLightOnBackground = Color(0xFF333333);
  
  // Modern High-Contrast Light Theme
  static ThemeData get newLightTheme {
    const Color background = Color(0xFFF4F3F0); // High-contrast Warm Ivory scaffold background
    const Color foreground = Color(0xFF1A1917); // Deep charcoal text
    const Color mutedForeground = Color(0xFF73726F);
    const Color card = Color(0xFFFFFFFF); // Pure white cards/surfaces
    const Color border = Color(0xFFE5E3DF); // Subtle warm outline border
    const Color input = Color(0xFFE5E3DF);
    const Color primary = Color(0xFF08584E); // hsl(175 87% 23%) - Green
    const Color primaryForeground = Color(0xFFFCFEFF); // hsl(211 100% 99%)
    const Color secondary = Color(0xFF8F5A24); // hsl(28 60% 35%) - Brown
    const Color secondaryForeground = Color(0xFFFAFAF9); // hsl(60 9.1% 97.8%)
    const Color accent = Color(0xFFC6AC42); // hsl(43 50% 52%) - Gold
    const Color accentForeground = Color(0xFF1A1917); // hsl(24 9.8% 10%)
    const Color destructive = Color(0xFFE63946); // hsl(0 84.2% 60.2%)
    const Color destructiveForeground = Color(0xFFFAFAF9); // hsl(60 9.1% 97.8%)
    const Color ring = Color(0xFF1A1917);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.light(
        primary: primary,
        primaryContainer: primary,
        secondary: secondary,
        tertiary: accent,
        surface: card,
        error: destructive,
        onPrimary: primaryForeground,
        onSecondary: secondaryForeground,
        onTertiary: accentForeground,
        onSurface: foreground,
        onError: destructiveForeground,
        outline: border,
        outlineVariant: input,
        surfaceContainer: background,
        surfaceContainerHigh: const Color(0xFFEBEAE6),
        surfaceContainerHighest: const Color(0xFFE2E0DB),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: card,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: foreground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: foreground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: mutedForeground,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: mutedForeground,
        ),
      ),
      fontFamily: AppConstants.tajikFontFamily,
    );
  }

  // Modern High-Contrast OLED Dark Theme
  static ThemeData get newDarkTheme {
    const Color background = Color(0xFF09090B); // Carbon deep pitch black scaffold background
    const Color foreground = Color(0xFFF3F4F6); // Off-white text
    const Color mutedForeground = Color(0xFFA5A5A8);
    const Color card = Color(0xFF16171A); // Elevated dark surfaces
    const Color border = Color(0xFF232427); // Subtle dark outline border
    const Color input = Color(0xFF232427);
    const Color primary = Color(0xFF08584E); // Green
    const Color primaryForeground = Color(0xFFFCFEFF);
    const Color secondary = Color(0xFFA36629);
    const Color secondaryForeground = Color(0xFFFAFAFA);
    const Color accent = Color(0xFFF5CC3D);
    const Color accentForeground = Color(0xFF1F1F1F);
    const Color destructive = Color(0xFF9E2A2A);
    const Color destructiveForeground = Color(0xFFFAFAFA);
    const Color ring = Color(0xFFD6D6D6);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        primaryContainer: primary,
        secondary: secondary,
        tertiary: accent,
        surface: card,
        error: destructive,
        onPrimary: primaryForeground,
        onSecondary: secondaryForeground,
        onTertiary: accentForeground,
        onSurface: foreground,
        onError: destructiveForeground,
        outline: border,
        outlineVariant: input,
        surfaceContainer: background,
        surfaceContainerHigh: const Color(0xFF1F2024),
        surfaceContainerHighest: const Color(0xFF282A2F),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: foreground,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: foreground,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        color: card,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: primaryForeground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: input,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: ring, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: destructive),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: card,
        selectedItemColor: primary,
        unselectedItemColor: mutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: foreground,
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: foreground,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: foreground,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: mutedForeground,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: mutedForeground,
        ),
      ),
      fontFamily: AppConstants.tajikFontFamily,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography system for Mirei app using Google Sans Rounded as primary font
/// Based on Material Design 3 typography scale with custom font implementation
/// Reference: PixelPlay app typography patterns
///
/// Primary font: Custom Google Sans Rounded (loaded from assets)
/// Display font: Montserrat (loaded via Google Fonts for special displays)
class AppTypography {
  static const String primaryFontFamily = 'GoogleSans';
  static const String displayFontFamily = 'Montserrat';

  /// Get the primary Google Sans Rounded text theme (custom font from assets)
  static TextTheme googleSansTextTheme([TextTheme? textTheme]) {
    textTheme ??= ThemeData.light().textTheme;

    // Base text theme using custom Google Sans from assets
    return TextTheme(
      // Display styles - largest text on screen
      displayLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.displayLarge?.fontSize ?? 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        height: textTheme.displayLarge?.height,
      ),
      displayMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.displayMedium?.fontSize ?? 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: textTheme.displayMedium?.height,
      ),
      displaySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.displaySmall?.fontSize ?? 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: textTheme.displaySmall?.height,
      ),

      // Headline styles - high-emphasis text
      headlineLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.headlineLarge?.fontSize ?? 32,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: textTheme.headlineLarge?.height,
      ),
      headlineMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.headlineMedium?.fontSize ?? 28,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: textTheme.headlineMedium?.height,
      ),
      headlineSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.headlineSmall?.fontSize ?? 24,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: textTheme.headlineSmall?.height,
      ),

      // Title styles - medium-emphasis text
      titleLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.titleLarge?.fontSize ?? 22,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: textTheme.titleLarge?.height,
      ),
      titleMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.titleMedium?.fontSize ?? 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: textTheme.titleMedium?.height,
      ),
      titleSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.titleSmall?.fontSize ?? 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: textTheme.titleSmall?.height,
      ),

      // Label styles - UI components
      labelLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.labelLarge?.fontSize ?? 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: textTheme.labelLarge?.height,
      ),
      labelMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.labelMedium?.fontSize ?? 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: textTheme.labelMedium?.height,
      ),
      labelSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.labelSmall?.fontSize ?? 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        height: textTheme.labelSmall?.height,
      ),

      // Body styles - main content text
      bodyLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.bodyLarge?.fontSize ?? 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: textTheme.bodyLarge?.height,
      ),
      bodyMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.bodyMedium?.fontSize ?? 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: textTheme.bodyMedium?.height,
      ),
      bodySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontSize: textTheme.bodySmall?.fontSize ?? 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: textTheme.bodySmall?.height,
      ),
    );
  }

  /// Get dark theme text theme with Google Sans Rounded
  static TextTheme openSansTextThemeDark([TextTheme? textTheme]) {
    textTheme ??= ThemeData.dark().textTheme;
    return googleSansTextTheme(textTheme);
  }

  /// Get Montserrat text theme for special display purposes
  static TextTheme montserratDisplayTheme([TextTheme? textTheme]) {
    textTheme ??= ThemeData.light().textTheme;
    return GoogleFonts.montserratTextTheme(textTheme).copyWith(
      displayLarge: GoogleFonts.montserrat(
        textStyle: textTheme.displayLarge,
        fontWeight: FontWeight.w300,
        letterSpacing: -1.5,
      ),
      displayMedium: GoogleFonts.montserrat(
        textStyle: textTheme.displayMedium,
        fontWeight: FontWeight.w300,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.montserrat(
        textStyle: textTheme.displaySmall,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
      ),
    );
  }
}

/// Custom text styles for specific use cases in Mirei app
/// Following PixelPlay patterns with Google Sans + Montserrat
class CustomTextStyles {
  /// Hero text style for splash screens and major headings (Montserrat)
  static TextStyle heroText({Color? color}) => GoogleFonts.montserrat(
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.0,
    color: color,
  );

  /// App bar title style (Google Sans)
  static TextStyle appBarTitle({Color? color}) => const TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  ).apply(color: color);

  /// Button text style (Google Sans)
  static TextStyle buttonText({Color? color}) => const TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  ).apply(color: color);

  /// Caption text style for subtle information (Google Sans)
  static TextStyle caption({Color? color}) => const TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  ).apply(color: color);

  /// Meditation timer style (Montserrat with tabular figures)
  static TextStyle meditationTimer({Color? color}) => GoogleFonts.montserrat(
    fontSize: 36,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Mini player styles removed per request

  /// Journal entry title style (Google Sans)
  static TextStyle journalTitle({Color? color}) => const TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
  ).apply(color: color);

  /// Journal entry body style (Google Sans)
  static TextStyle journalBody({Color? color}) => const TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  ).apply(color: color);

  /// Mood tracker label style (Google Sans)
  static TextStyle moodLabel({Color? color}) => const TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
  ).apply(color: color);

  /// Navigation tab style (Google Sans)
  static TextStyle navigationTab({Color? color}) => const TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  ).apply(color: color);
}

/// Typography helper methods
class TypographyHelpers {
  /// Create consistent text theme for the entire app
  static TextTheme createAppTextTheme({
    required Brightness brightness,
    TextTheme? baseTheme,
  }) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return AppTypography.googleSansTextTheme(baseTheme ?? base);
  }

  /// Get font weight based on emphasis level
  static FontWeight getEmphasisWeight(TextEmphasis emphasis) {
    switch (emphasis) {
      case TextEmphasis.high:
        return FontWeight.w600;
      case TextEmphasis.medium:
        return FontWeight.w500;
      case TextEmphasis.low:
        return FontWeight.w400;
    }
  }

  /// Get letter spacing for different text scales
  static double getLetterSpacing(double fontSize) {
    if (fontSize >= 24) return -0.25; // Large displays
    if (fontSize >= 16) return 0.15; // Body text
    if (fontSize >= 14) return 0.25; // Labels
    return 0.4; // Small text
  }
}

/// Text emphasis levels for consistent styling
enum TextEmphasis { high, medium, low }

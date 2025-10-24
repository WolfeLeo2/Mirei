import 'package:flutter/material.dart';
import '../theme/typography.dart';

/// App Text Styles
/// Convenient access to commonly used text styles throughout the app
/// Wraps CustomTextStyles for easier access and adds more semantic styles
class AppTextStyles {
  AppTextStyles._(); // Private constructor to prevent instantiation

  // ========== Hero & Display Styles ==========

  /// Large hero text for splash screens and major headings
  static TextStyle hero({Color? color}) =>
      CustomTextStyles.heroText(color: color);

  /// App bar title
  static TextStyle appBarTitle({Color? color}) =>
      CustomTextStyles.appBarTitle(color: color);

  // ========== Headings ==========

  /// H1 - Largest heading (32px)
  static TextStyle h1({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 32,
    fontWeight: weight ?? FontWeight.w400,
    letterSpacing: 0,
    color: color,
  );

  /// H2 - Large heading (28px)
  static TextStyle h2({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 28,
    fontWeight: weight ?? FontWeight.w400,
    letterSpacing: 0,
    color: color,
  );

  /// H3 - Medium heading (24px)
  static TextStyle h3({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 24,
    fontWeight: weight ?? FontWeight.w400,
    letterSpacing: 0,
    color: color,
  );

  /// H4 - Small heading (20px)
  static TextStyle h4({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 20,
    fontWeight: weight ?? FontWeight.w500,
    letterSpacing: 0,
    color: color,
  );

  /// H5 - Extra small heading (18px)
  static TextStyle h5({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 18,
    fontWeight: weight ?? FontWeight.w500,
    letterSpacing: 0,
    color: color,
  );

  /// H6 - Tiny heading (16px)
  static TextStyle h6({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 16,
    fontWeight: weight ?? FontWeight.w500,
    letterSpacing: 0.15,
    color: color,
  );

  // ========== Body Text ==========

  /// Large body text (16px)
  static TextStyle bodyLarge({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 16,
    fontWeight: weight ?? FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
    color: color,
  );

  /// Regular body text (14px)
  static TextStyle bodyMedium({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 14,
    fontWeight: weight ?? FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.5,
    color: color,
  );

  /// Small body text (12px)
  static TextStyle bodySmall({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 12,
    fontWeight: weight ?? FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.5,
    color: color,
  );

  // ========== Captions & Labels ==========

  /// Caption text (12px) - for subtle information
  static TextStyle caption({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 12,
    fontWeight: weight ?? FontWeight.w400,
    letterSpacing: 0.4,
    color: color,
  );

  /// Label text (14px) - for UI components
  static TextStyle label({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 14,
    fontWeight: weight ?? FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
  );

  /// Small label (12px) - for compact UI
  static TextStyle labelSmall({Color? color, FontWeight? weight}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 12,
    fontWeight: weight ?? FontWeight.w500,
    letterSpacing: 0.5,
    color: color,
  );

  // ========== Buttons ==========

  /// Button text (14px)
  static TextStyle button({Color? color}) =>
      CustomTextStyles.buttonText(color: color);

  /// Large button text (16px)
  static TextStyle buttonLarge({Color? color}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
  );

  /// Small button text (12px)
  static TextStyle buttonSmall({Color? color}) => TextStyle(
    fontFamily: AppTypography.primaryFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: color,
  );

  // ========== Feature-Specific Styles ==========

  /// Journal entry title (18px)
  static TextStyle journalTitle({Color? color}) =>
      CustomTextStyles.journalTitle(color: color);

  /// Journal entry body (16px)
  static TextStyle journalBody({Color? color}) =>
      CustomTextStyles.journalBody(color: color);

  /// Mood label (13px)
  static TextStyle moodLabel({Color? color}) =>
      CustomTextStyles.moodLabel(color: color);

  /// Navigation tab (12px)
  static TextStyle navigationTab({Color? color}) =>
      CustomTextStyles.navigationTab(color: color);

  /// Meditation timer (36px)
  static TextStyle meditationTimer({Color? color}) =>
      CustomTextStyles.meditationTimer(color: color);

  // ========== Emphasis Variants ==========

  /// Bold variant of body text
  static TextStyle bodyBold({Color? color}) =>
      bodyMedium(color: color, weight: FontWeight.w600);

  /// Semibold variant of body text
  static TextStyle bodySemibold({Color? color}) =>
      bodyMedium(color: color, weight: FontWeight.w500);

  /// Light variant of body text
  static TextStyle bodyLight({Color? color}) =>
      bodyMedium(color: color, weight: FontWeight.w300);

  // ========== Special Purpose ==========

  /// Error message text
  static TextStyle error({Color color = const Color(0xFFCC3E3E)}) =>
      bodyMedium(color: color);

  /// Success message text
  static TextStyle success({Color color = const Color(0xFF27AE60)}) =>
      bodyMedium(color: color);

  /// Warning message text
  static TextStyle warning({Color color = const Color(0xFFF2994A)}) =>
      bodyMedium(color: color);

  /// Hint text (light, subtle)
  static TextStyle hint({Color? color}) => bodyMedium(
    color: color ?? const Color(0xFF718096),
    weight: FontWeight.w400,
  );

  /// Link text
  static TextStyle link({Color color = const Color(0xFF115e5a)}) => bodyMedium(
    color: color,
    weight: FontWeight.w500,
  ).copyWith(decoration: TextDecoration.underline);

  // ========== Utility Methods ==========

  /// Apply color to any text style
  static TextStyle withColor(TextStyle style, Color color) =>
      style.copyWith(color: color);

  /// Apply weight to any text style
  static TextStyle withWeight(TextStyle style, FontWeight weight) =>
      style.copyWith(fontWeight: weight);

  /// Apply opacity to text style color
  static TextStyle withOpacity(TextStyle style, double opacity) {
    final color = style.color ?? Colors.black;
    return style.copyWith(color: color.withValues(alpha: opacity));
  }

  /// Make text style italic
  static TextStyle italic(TextStyle style) =>
      style.copyWith(fontStyle: FontStyle.italic);

  /// Add underline to text style
  static TextStyle underline(TextStyle style) =>
      style.copyWith(decoration: TextDecoration.underline);

  /// Add line-through to text style
  static TextStyle lineThrough(TextStyle style) =>
      style.copyWith(decoration: TextDecoration.lineThrough);
}

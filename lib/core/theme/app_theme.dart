import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'mood_colors.dart';

class AppTheme {
  static const RoundedRectangleBorder _fallbackRounded = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  static OutlinedBorder _squircleOutlined(double radius) {
    try {
      return RoundedSuperellipseBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      );
    } catch (_) {
      return _fallbackRounded;
    }
  }

  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFFFAF6F1),
      textTheme: GoogleFonts.interTextTheme(),
      extensions: <ThemeExtension<dynamic>>[
        MoodColors.fromScheme(colorScheme: scheme),
      ],
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: _squircleOutlined(12),
        clipBehavior: Clip.antiAlias,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 2,
        modalElevation: 8,
        shape: _squircleOutlined(24),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: _squircleOutlined(20),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: _squircleOutlined(12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<OutlinedBorder>(
            _squircleOutlined(12),
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0F1115),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      extensions: <ThemeExtension<dynamic>>[
        MoodColors.fromScheme(colorScheme: scheme),
      ],
      cardTheme: CardThemeData(
        elevation: 1,
        margin: const EdgeInsets.all(8),
        shape: _squircleOutlined(12),
        clipBehavior: Clip.antiAlias,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surfaceTint,
        elevation: 2,
        modalElevation: 8,
        shape: _squircleOutlined(24),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: _squircleOutlined(20),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: _squircleOutlined(12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStateProperty.all<OutlinedBorder>(
            _squircleOutlined(12),
          ),
        ),
      ),
    );
  }
}

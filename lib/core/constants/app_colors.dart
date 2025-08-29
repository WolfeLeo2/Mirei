import 'package:flutter/material.dart';

/// App Color Constants
/// Primary theme color: Teal/Green (#115e5a)
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF115e5a);
  static const Color primaryDark = Color(0xFF0d4a47);
  static const Color primaryLight = Color(0xFF4a9b96);

  // Secondary Colors
  static const Color secondary = Color(0xFF6366F1);
  static const Color secondaryDark = Color(0xFF4F46E5);
  static const Color secondaryLight = Color(0xFF8B7CF6);

  // Neutral Colors
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textLight = Color(0xFF616161);

  // Background Colors
  static const Color background = Colors.white;
  static const Color backgroundLight = Color(0xFFF7FAFC);
  static const Color surface = Colors.white;

  // Success, Warning, Error
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF2994A);
  static const Color error = Color(0xFFCC3E3E);

  // Emotion Colors (for mood tracking)
  static const Color happy = Color(0xFFFFC107); // Bright yellow/amber
  static const Color cutesy = Color(0xFFE91E63); // Pink/magenta
  static const Color shocked = Color(0xFFFF5722); // Deep orange
  static const Color neutral = Color(0xFF9E9E9E); // Grey
  static const Color awkward = Color(0xFF9C27B0); // Purple
  static const Color disappointed = Color(0xFF607D8B); // Blue grey
  static const Color sad = Color(0xFF2196F3); // Blue
  static const Color angry = Color(0xFFF44336); // Red
  static const Color worried = Color(0xFF795548); // Brown
  static const Color tired = Color(0xFF673AB7); // Deep purple

  // Utility Colors
  static const Color divider = Color(0xFFE2E8F0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);

  // Gradient Combinations
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Theme-specific color variations
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);
  static Color primaryWithAlpha(double alpha) =>
      primary.withValues(alpha: alpha);

  // Helper method to get emotion color by mood name
  static Color getEmotionColor(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return happy;
      case 'cutesy':
        return cutesy;
      case 'shocked':
        return shocked;
      case 'neutral':
        return neutral;
      case 'awkward':
        return awkward;
      case 'disappointed':
        return disappointed;
      case 'sad':
        return sad;
      case 'angry':
        return angry;
      case 'worried':
        return worried;
      case 'tired':
        return tired;
      default:
        return neutral; // Default fallback
    }
  }
}

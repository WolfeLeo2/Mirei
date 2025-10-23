import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MoodColors extends ThemeExtension<MoodColors> {
  final Color happy;  
  final Color neutral;
  final Color sad;
  final Color angry;

  const MoodColors({
    required this.happy,
    required this.neutral,
    required this.sad,
    required this.angry,
  });

  factory MoodColors.fromScheme({required ColorScheme colorScheme}) {
    Color h(Color c) => AppColors.harmonizeToPrimary(c, colorScheme);
    return MoodColors(
      happy: h(AppColors.happy),
      neutral: h(AppColors.neutral),
      sad: h(AppColors.sad),
      angry: h(AppColors.angry),
    );
  }

  Color byMood(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return happy;
      case 'neutral':
        return neutral;
      case 'sad':
        return sad;
      case 'angry':
        return angry;
      default:
        return neutral;
    }
  }

  @override
  MoodColors copyWith({
    Color? happy,
    Color? neutral,
    Color? sad,
    Color? angry,
  }) {
    return MoodColors(
      happy: happy ?? this.happy,
      neutral: neutral ?? this.neutral,
      sad: sad ?? this.sad,
      angry: angry ?? this.angry,
    );
  }

  @override
  MoodColors lerp(ThemeExtension<MoodColors>? other, double t) {
    if (other is! MoodColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return MoodColors(
      happy: l(happy, other.happy),
      neutral: l(neutral, other.neutral),
      sad: l(sad, other.sad),
      angry: l(angry, other.angry),
    );
  }
}

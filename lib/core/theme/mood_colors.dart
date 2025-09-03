import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MoodColors extends ThemeExtension<MoodColors> {
  final Color happy;
  final Color cutesy;
  final Color shocked;
  final Color neutral;
  final Color awkward;
  final Color disappointed;
  final Color sad;
  final Color angry;
  final Color worried;
  final Color tired;

  const MoodColors({
    required this.happy,
    required this.cutesy,
    required this.shocked,
    required this.neutral,
    required this.awkward,
    required this.disappointed,
    required this.sad,
    required this.angry,
    required this.worried,
    required this.tired,
  });

  factory MoodColors.fromScheme({required ColorScheme colorScheme}) {
    Color h(Color c) => AppColors.harmonizeToPrimary(c, colorScheme);
    return MoodColors(
      happy: h(AppColors.happy),
      cutesy: h(AppColors.cutesy),
      shocked: h(AppColors.shocked),
      neutral: h(AppColors.neutral),
      awkward: h(AppColors.awkward),
      disappointed: h(AppColors.disappointed),
      sad: h(AppColors.sad),
      angry: h(AppColors.angry),
      worried: h(AppColors.worried),
      tired: h(AppColors.tired),
    );
  }

  Color byMood(String mood) {
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
        return neutral;
    }
  }

  @override
  MoodColors copyWith({
    Color? happy,
    Color? cutesy,
    Color? shocked,
    Color? neutral,
    Color? awkward,
    Color? disappointed,
    Color? sad,
    Color? angry,
    Color? worried,
    Color? tired,
  }) {
    return MoodColors(
      happy: happy ?? this.happy,
      cutesy: cutesy ?? this.cutesy,
      shocked: shocked ?? this.shocked,
      neutral: neutral ?? this.neutral,
      awkward: awkward ?? this.awkward,
      disappointed: disappointed ?? this.disappointed,
      sad: sad ?? this.sad,
      angry: angry ?? this.angry,
      worried: worried ?? this.worried,
      tired: tired ?? this.tired,
    );
  }

  @override
  MoodColors lerp(ThemeExtension<MoodColors>? other, double t) {
    if (other is! MoodColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return MoodColors(
      happy: l(happy, other.happy),
      cutesy: l(cutesy, other.cutesy),
      shocked: l(shocked, other.shocked),
      neutral: l(neutral, other.neutral),
      awkward: l(awkward, other.awkward),
      disappointed: l(disappointed, other.disappointed),
      sad: l(sad, other.sad),
      angry: l(angry, other.angry),
      worried: l(worried, other.worried),
      tired: l(tired, other.tired),
    );
  }
}

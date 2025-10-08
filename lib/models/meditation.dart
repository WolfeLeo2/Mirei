import 'package:flutter/material.dart';

class Meditation {
  final String title;
  final String duration;
  final String imagePath;
  final Color color;
  final String audioUrl;
  final List<Color> gradientColors;
  final String? category; // e.g., "SERENITY", "FOCUS", "SLEEP"
  final String? period; // e.g., "morning", "evening", "sleep"
  final String? activityType; // e.g., "walking", "yoga", "breathing"

  Meditation({
    required this.title,
    required this.duration,
    required this.imagePath,
    required this.color,
    required this.audioUrl,
    List<Color>? gradientColors,
    this.category,
    this.period,
    this.activityType,
  }) : gradientColors = gradientColors ?? [color, color.withOpacity(0.7)];
}

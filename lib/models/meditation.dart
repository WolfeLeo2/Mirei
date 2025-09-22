import 'package:flutter/material.dart';

class Meditation {
  final String title;
  final String duration;
  final String imagePath;
  final Color color;
  final String audioUrl;

  Meditation({
    required this.title,
    required this.duration,
    required this.imagePath,
    required this.color,
    required this.audioUrl,
  });
}

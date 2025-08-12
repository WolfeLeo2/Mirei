import 'package:flutter/material.dart';

class CardData {
  final String title;
  final String subtitle;
  final String imagePath;
  final Gradient gradient;

  const CardData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.gradient,
  });
}

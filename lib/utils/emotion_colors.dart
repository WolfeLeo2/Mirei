import 'package:flutter/material.dart';

const Map<String, Color> emotionColors = {
  'Angelic': Color(0xFF42C8E9),
  'Sorry': Color(0xFFBDBDBD),
  'Excited': Color(0xFF27AE60),
  'Embarrassed': Color(0xFFCC3E3E),
  'Happy': Color(0xFFF2994A),
  'Romantic': Color(0xFF892035),
  'Neutral': Color(0xFF828282),
  'Sad': Color(0xFF2F80ED),
  'Silly': Color(0xFF6B3B0B),
};

Color getEmotionColor(String mood) {
  return emotionColors[mood] ?? emotionColors['Neutral']!;
}

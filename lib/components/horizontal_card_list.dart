import 'package:flutter/material.dart';
import 'package:mirei/components/emotion_card.dart';

class HorizontalCardList extends StatelessWidget {
  const HorizontalCardList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: [
          EmotionCard(
            gradient: const LinearGradient(
              colors: [Color(0xFFfce5e7), Color(0xFFe8e0f9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            title: 'Relax Mode',
            subtitle: 'A soothing atmosphere for rest',
            imagePath: 'assets/images/image1.jpg',
          ),
          EmotionCard(
            gradient: const LinearGradient(
              colors: [Color(0xFFd9f0ff), Color(0xFFcde5fe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            title: 'Mood',
            subtitle: 'Boogey Woogey',
            imagePath: 'assets/images/image2.jpg',
          ),
          EmotionCard(
            title: 'Focus Mode',
            subtitle: 'Enhanced concentration',
            imagePath: 'assets/images/gradient.png',
            gradient: const LinearGradient(
              colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          EmotionCard(
            title: 'Relaxing',
            subtitle: 'A soothing atmosphere for rest',
            imagePath: 'assets/images/image2.jpg',
            gradient: const LinearGradient(
              colors: [Color(0xFFd9f0ff), Color(0xFFcde5fe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }
}

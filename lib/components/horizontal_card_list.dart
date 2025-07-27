import 'package:flutter/material.dart';
import 'package:mirei/components/emotion_card.dart';
import 'package:mirei/components/media_player_card.dart';

class HorizontalCardList extends StatelessWidget {
  final String assetPath;
  const HorizontalCardList({Key? key, required this.assetPath}) : super(key: key);

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
          MediaPlayerCard(assetPath: assetPath),
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

import 'package:flutter/material.dart';
import 'package:mirei/components/emotion_card.dart';
import 'package:mirei/components/media/album_card.dart';

class MediaCards extends StatelessWidget {
  const MediaCards({super.key});

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
            title: 'Relaxing',
            subtitle: 'A soothing atmosphere for rest',
            imagePath: 'assets/images/image2.jpg',
            gradient: const LinearGradient(
              colors: [Color(0xFFd9f0ff), Color(0xFFcde5fe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          AlbumCard(),
        ],
      ),
    );
  }
}

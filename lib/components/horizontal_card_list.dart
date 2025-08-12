import 'package:flutter/material.dart';
import 'package:mirei/components/music_card.dart';
import 'package:mirei/models/card_data.dart';

class HorizontalCardList extends StatelessWidget {
  final List<CardData> cardData;

  const HorizontalCardList({super.key, required this.cardData});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 270,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        physics: const BouncingScrollPhysics(), // Better scroll physics
        itemCount: cardData.length,
        itemBuilder: (context, index) {
          final card = cardData[index];
          return RepaintBoundary(
            child: MusicCard(
              gradient: card.gradient,
              title: card.title,
              subtitle: card.subtitle,
              imagePath: card.imagePath,
            ),
          );
        },
      ),
    );
  }
}

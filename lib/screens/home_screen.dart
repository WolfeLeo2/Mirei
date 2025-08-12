import 'package:flutter/material.dart';
import 'package:mirei/components/top_bar.dart';
import 'package:mirei/components/main_card.dart';
import 'package:mirei/components/section_header.dart';
import 'package:mirei/components/horizontal_card_list.dart';
import 'package:mirei/models/card_data.dart';
import 'package:mirei/models/session_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<CardData> cardData = [
    const CardData(
      gradient: LinearGradient(
        colors: [Color(0xFFfce5e7), Color(0xFFe8e0f9)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      title: 'Relax Mode',
      subtitle: 'A soothing atmosphere for rest',
      imagePath: 'assets/images/image1.jpg',
    ),
    const CardData(
      gradient: LinearGradient(
        colors: [Color(0xFFd9f0ff), Color(0xFFcde5fe)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      title: 'Mood',
      subtitle: 'Boogey Woogey',
      imagePath: 'assets/images/image2.jpg',
    ),
    const CardData(
      title: 'Focus Mode',
      subtitle: 'Enhanced concentration',
      imagePath: 'assets/images/gradient.png',
      gradient: LinearGradient(
        colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    const CardData(
      title: 'Relaxing',
      subtitle: 'A soothing atmosphere for rest',
      imagePath: 'assets/images/image2.jpg',
      gradient: LinearGradient(
        colors: [Color(0xFFd9f0ff), Color(0xFFcde5fe)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final session = getSessionInfo();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/color.jpg',
            ), //changed to evening image. Looks better
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            physics: const BouncingScrollPhysics(), // Better scroll feel
            children: [
              RepaintBoundary(child: TopBar(session: session)),
              const SizedBox(height: 20),
              RepaintBoundary(child: MainCard(session: session)),
              const SizedBox(height: 30),
              RepaintBoundary(child: SectionHeader()),
              const SizedBox(height: 20),
              RepaintBoundary(child: HorizontalCardList(cardData: cardData)),
              const SizedBox(height: 100), // Space for the bottom nav bar
            ],
          ),
        ),
      ),
    );
  }
}

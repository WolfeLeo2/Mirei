import 'package:flutter/material.dart';
import '../components/main_card.dart';
import '../components/horizontal_card_list.dart';
import '../components/section_header.dart';
import '../components/top_bar.dart';
import '../models/user.dart';
import '../models/card_data.dart'; // Add missing import
import '../models/session_info.dart'; // Add missing import
import '../utils/performance_mixins.dart'; // Add performance mixins

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> 
    with PerformanceOptimizedStateMixin { // Add performance mixin
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
            ),
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
        ),
        child: SafeArea(
          child: OptimizedListView(
            itemCount: 6, // Number of sections
            padding: const EdgeInsets.symmetric(vertical: 10),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              switch (index) {
                case 0:
                  return RepaintBoundary(child: TopBar(session: session));
                case 1:
                  return const SizedBox(height: 20);
                case 2:
                  return RepaintBoundary(child: MainCard(session: session));
                case 3:
                  return const SizedBox(height: 30);
                case 4:
                  return RepaintBoundary(child: SectionHeader());
                case 5:
                  return RepaintBoundary(child: HorizontalCardList(cardData: cardData));
                default:
                  return const SizedBox(height: 100); // Space for bottom nav
              }
            },
          ),
        ),
      ),
    );
  }
}

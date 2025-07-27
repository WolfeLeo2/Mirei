import 'package:flutter/material.dart';
import 'package:mirei/components/nav_bar.dart';
import 'package:mirei/components/top_bar.dart';
import 'package:mirei/components/main_card.dart';
import 'package:mirei/components/section_header.dart';
import 'package:mirei/components/horizontal_card_list.dart';
import 'package:mirei/models/session_info.dart';
import 'journal_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
  
}

class _HomeScreenState extends State<HomeScreen> {
  final String assetPath =
      'assets/images/too_bad.mp3'; // Use your actual asset path

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = getSessionInfo();
    String bgImage;
    switch (session.time) {
      case 'Morning':
        bgImage = 'assets/images/bg-morning.jpg';
        break;
      case 'Afternoon':
        bgImage = 'assets/images/bg-afternoon.jpg';
        break;
      case 'Evening':
      default:
        bgImage = 'assets/images/bg-evening.jpg';
        break;
    }
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            // Swipe left detected
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JournalHomeScreen()),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg-afternoon.jpg'),//changed to evening image. Looks better
              fit: BoxFit.cover,
              opacity: 0.8,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    TopBar(session: session),
                    const SizedBox(height: 20),
                    MainCard(session: session),
                    const SizedBox(height: 30),
                    SectionHeader(),
                    const SizedBox(height: 20),
                    HorizontalCardList(assetPath: assetPath),
                    const SizedBox(height: 100), // Space for the bottom nav bar
                  ],
                ),
                _buildBottomNavBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return NavBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
        switch (index) {
          case 0:
            // Already on home, do nothing
            break;
          case 1:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JournalHomeScreen()),
            );
            break;
          case 2:
            // Navigate to bookmarks
            break;
          case 3:
            // Navigate to profile (implement if needed)
            break;
        }
      },
    );
  }
}

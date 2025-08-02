import 'package:flutter/material.dart';
import 'package:mirei/components/top_bar.dart';
import 'package:mirei/components/main_card.dart';
import 'package:mirei/components/section_header.dart';
import 'package:mirei/components/horizontal_card_list.dart';
import 'package:mirei/models/session_info.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final session = getSessionInfo();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/gradient-2.png',
            ), //changed to evening image. Looks better
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: [
              TopBar(session: session),
              const SizedBox(height: 20),
              MainCard(session: session),
              const SizedBox(height: 30),
              SectionHeader(),
              const SizedBox(height: 20),
              const HorizontalCardList(),
              const SizedBox(height: 100), // Space for the bottom nav bar
            ],
          ),
        ),
      ),
    );
  }
}

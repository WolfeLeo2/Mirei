import 'package:flutter/material.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
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
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  _buildMainCard(),
                  const SizedBox(height: 30),
                  _buildSectionHeader(),
                  const SizedBox(height: 20),
                  _buildHorizontalCardList(),
                  const SizedBox(height: 100), // Space for the bottom nav bar
                ],
              ),
              _buildBottomNavBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(60.0, 20.0, 20.0, 0),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(50.0),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wb_sunny_outlined,
                          color: const Color(0xFF1a237e),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'GOOD MORNING',
                          style: TextStyle(
                            color: const Color(0xFF1a237e),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: IconButton(
              icon: Icon(Icons.menu, color: const Color(0xFF1a237e), size: 24),
              onPressed: () {
                // TODO: Add menu functionality
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'SERENITY',
            style: TextStyle(
              color: Color.fromARGB(255, 20, 50, 81),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Morning\nAwakening',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color.fromARGB(255, 20, 50, 81),
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1.2,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow, size: 20),
            label: const Text(
              '9 Minutes',
              style: TextStyle(
                color: Color.fromARGB(255, 20, 50, 81),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: const Color.fromARGB(255, 20, 50, 81),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25,
              height: 5,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 20, 50, 81),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  20,
                  50,
                  81,
                ).withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF1a237e).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        const Text(
          'Relax Mode',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 20, 50, 81),
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'For rest and recuperation',
          style: TextStyle(
            color: const Color.fromARGB(255, 20, 50, 81).withValues(alpha: 0.7),
            fontSize: 16,
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCardList() {
    return SizedBox(
      height: 270,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 16),
        children: [
          _buildRelaxCard(
            gradient: const LinearGradient(
              colors: [Color(0xFFfce5e7), Color(0xFFe8e0f9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            title: 'Relax Mode',
            subtitle: 'A soothing atmosphere for rest',
          ),
          _buildRelaxCard(
            gradient: const LinearGradient(
              colors: [Color(0xFFd9f0ff), Color(0xFFcde5fe)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            title: 'Relax Mode',
            subtitle: 'A soothing atmosphere for rest',
            imagePath: 'assets/images/image2.jpg',
          ),
          _buildMediaPlayerCard(isPlaying: _isPlaying),
        ],
      ),
    );
  }

  Widget _buildMediaPlayerCard({bool isPlaying = false}) {
    if (!isPlaying) {
      // Idle state
      return Container(
        width: 265,
        height: 265,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 182, 161, 190),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_note,
              color: const Color.fromARGB(255, 20, 50, 81).withOpacity(0.15),
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text(
              'Nothing is being played',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.fromARGB(255, 20, 50, 81),
                fontWeight: FontWeight.w500,
                fontSize: 18,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isPlaying = true;
                  });
                },
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.7),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Color.fromARGB(255, 20, 50, 81),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )
      );
    } else {
      // Playing state
      return Container(
        width: 265,
        height: 265,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Text(
                'Dreamwave',
                style: TextStyle(
                  color: const Color.fromARGB(255, 20, 50, 81).withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Your Body's Wisdom",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color.fromARGB(255, 20, 50, 81),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '04:35',
                style: TextStyle(
                  color: const Color.fromARGB(255, 20, 50, 81).withOpacity(0.55),
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  letterSpacing: -0.5,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  // Rewind 15s
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {},
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.replay_10,
                              color: const Color.fromARGB(255, 20, 50, 81).withOpacity(0.5), size: 24),
                            Text('15', style: TextStyle(
                              color: const Color.fromARGB(255, 20, 50, 81).withOpacity(0.5), fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Pause button (Material 3 filled)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 20, 50, 81),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(0),
                      minimumSize: const Size(64, 64),
                      maximumSize: const Size(64, 64),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPlaying = false;
                      });
                    },
                    child: const Icon(Icons.pause, color: Colors.white, size: 36),
                  ),
                  // Next button
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {},
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(Icons.arrow_forward,
                          color: const Color.fromARGB(255, 20, 50, 81).withOpacity(0.7), size: 28),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildRelaxCard({
    required Gradient gradient,
    required String title,
    required String subtitle,
    String imagePath = 'assets/images/image1.jpg',
  }) {
    return Container(
      width: 265,
      height: 265,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Full card background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/image1.jpg',
                fit: BoxFit.cover,
              ),
            ),
            // Gradient overlay at the bottom for text readability
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 110,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Color.fromARGB(180, 255, 255, 255),
                      Color.fromARGB(60, 255, 255, 255),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Play button (centered, upper third)
            Positioned(
              top: 32,
              left: 0,
              right: 0,
              child: Center(
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.7),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow,
                          color: Color.fromARGB(255, 20, 50, 81),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Title and subtitle at the bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 20, 50, 81),
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      letterSpacing: -1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color.fromARGB(255, 20, 50, 81).withValues(alpha: 0.65),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: 20,
      left: 80,
      right: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30.0),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_filled, isSelected: true),
                _buildNavItem(icon: Icons.bookmark_border),
                _buildNavItem(icon: Icons.calendar_today_outlined),
                _buildNavItem(icon: Icons.person_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, bool isSelected = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? const Color.fromARGB(255, 20, 50, 81) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isSelected
            ? Colors.white
            : const Color(0xFF1a237e).withOpacity(0.7),
        size: 24,
      ),
    );
  }
}

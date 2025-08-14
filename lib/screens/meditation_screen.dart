import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mirei/models/meditation.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  final SwiperController _controller = SwiperController();
  
  final List<Meditation> _meditationData = [
    Meditation(
      title: 'Walking',
      duration: '10 min',
      imagePath: 'assets/icons/meditation.svg', // Changed to SVG icon
      color: const Color(0xFFE49A7A), // Pastel orange
    ),
    Meditation(
      title: 'Calm Music',
      duration: '15 min',
      imagePath: 'assets/icons/meditation.svg', // Changed to SVG icon
      color: const Color(0xFF9E9248), // Pastel olive
    ),
    Meditation(
      title: 'Sleep Well',
      duration: '20 min',
      imagePath: 'assets/icons/meditation.svg', // Changed to SVG icon
      color: const Color(0xFFE1DBCB), // Pastel beige
    ),
    Meditation(
      title: 'Breath Exercise',
      duration: '5 min',
      imagePath: 'assets/icons/meditation.svg', // Changed to SVG icon
      color: const Color(0xFFC6BEEA), // Pastel purple
    ),
    Meditation(
      title: 'Breathe Easy',
      duration: '45 min',
      imagePath: 'assets/icons/meditation.svg', // Changed to SVG icon
      color: const Color(0xFF8B7355), // Pastel brown
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFfaf6f1),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.05, 
                    screenHeight * 0.025, 
                    screenWidth * 0.05, 
                    screenHeight * 0.015
                  ),
                  child: const Text(
                    'Popular Meditation',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                    child: _buildStackedCards(),
                  ),
                ),
                // Extra space for bottom nav
                SizedBox(height: screenHeight * 0.12),
              ],
            ),
          ),
          
          // White container with filter chips positioned above floating nav
          Positioned(
            bottom: screenHeight * 0.08,
            left: screenWidth * 0.05,
            right: screenWidth * 0.05,
            child: const _BottomNavBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedCards() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Center(
      child: SizedBox(
        height: screenHeight * 0.7,
        child: Swiper(
          controller: _controller,
          itemCount: _meditationData.length,
          layout: SwiperLayout.STACK,
          itemWidth: screenWidth * 0.9,
          itemHeight: screenHeight * 0.5,
          loop: true,
          scrollDirection: Axis.vertical,
          itemBuilder: (BuildContext context, int index) {
            return _buildCard(_meditationData[index]);
          },
        ),
      ),
    );
  }

  Widget _buildCard(Meditation meditation) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Solid pastel color background (no image)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: meditation.color, // Pure solid color
                ),
              ),
            ),
            
            // SVG/Image overlay on top of the card (centered)
            Center(
              child: SvgPicture.asset(
                meditation.imagePath,
                width: 80,
                height: 80,
                colorFilter: ColorFilter.mode(
                  _getTextColor(meditation.color).withOpacity(0.3),
                  BlendMode.srcIn,
                ),
              ),
            ),
            
            // Glass heart icon (top-right)
            Positioned(
              top: 25,
              right: 25,
              child: GlassmorphicContainer(
                width: 44,
                height: 44,
                borderRadius: 22,
                blur: 20,
                alignment: Alignment.center,
                border: 2,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.2),
                  ],
                ),
                child: const Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            
            // Title at top-left
            Positioned(
              left: 25,
              top: 25,
              child: Text(
                meditation.title,
                style: TextStyle(
                  color: _getTextColor(meditation.color),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            // Glass timer widget at bottom-left
            Positioned(
              bottom: 25,
              left: 25,
              child: GlassmorphicContainer(
                width: 85,
                height: 34,
                borderRadius: 17,
                blur: 20,
                alignment: Alignment.center,
                border: 1.5,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.6),
                    Colors.white.withOpacity(0.3),
                  ],
                ),
                child: _buildTimerWidget(
                  meditation.duration, 
                  _getTextColor(meditation.color)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerWidget(String duration, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          color: textColor,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          duration,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate relative luminance to determine text color
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive sizing
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Search icon with white background
          Container(
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.search, color: Colors.black54, size: 20),
          ),
          const SizedBox(width: 8),
          _buildFilterChip('Favorites'),
          const SizedBox(width: 8),
          _buildFilterChip('Daily meditation'),
          const SizedBox(width: 8),
          _buildFilterChip('New releases'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mirei/models/meditation.dart';
import 'package:animations/animations.dart';
import 'meditation_player_screen.dart';

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
      imagePath: 'assets/images/meditation.svg', // Changed to SVG icon
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
      backgroundColor: const Color(0xFFd7dfe5),
      appBar: AppBar(
            backgroundColor: const Color(0xFFd7dfe5),
            elevation: 0,
            title: Text(
              'Meditation',
              style: TextStyle(
                color: const Color(0xFF115e5a),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF115e5a)),
                onPressed: () {
                  // TODO: Implement search functionality
                },
              ),
            ],
          ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Title section
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenWidth * 0.05, 
                screenHeight * 0.025, 
                screenWidth * 0.05, 
                screenHeight * 0.015
              ),

            ),
            
            // Filter chips section - moved to top for better UX
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.005, // Reduced from 0.01 to 0.005 to move cards higher
              ),
              child: _BottomNavBar(screenWidth: screenWidth),
            ),
            
            // Main content with cards
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  screenWidth * 0.05,
                  screenHeight * 0.04, // Changed from screenHeight * 0.01 to 0 to move cards higher
                  screenWidth * 0.05,
                  screenHeight * 0.02,
                ),
                child: _buildStackedCards(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStackedCards() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Align(
      alignment: Alignment.topCenter, // Changed from Center to topCenter to move cards higher
      child: SizedBox(
        height: screenHeight * 0.65, // Slightly reduced from 0.7 to make room at top
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
    // Pre-calculate text color once
    final textColor = _getTextColor(meditation.color);
    
    return OpenContainer(
      transitionType: ContainerTransitionType.fade,
      transitionDuration: const Duration(milliseconds: 500),
      closedElevation: 0,
      openElevation: 0,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      openShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      closedColor: meditation.color,
      openColor: meditation.color,
      middleColor: meditation.color,
      closedBuilder: (context, openContainer) => RepaintBoundary( // Add RepaintBoundary for better performance
        child: Container(
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
                  child: RepaintBoundary(
                    child: SvgPicture.asset(
                      meditation.imagePath,
                      width: 80,
                      height: 80,
                      colorFilter: ColorFilter.mode(
                        textColor.withOpacity(0.3),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                
                // Glass heart icon (top-right)
                Positioned(
                  top: 25,
                  right: 25,
                  child: RepaintBoundary(
                    child: _GlassHeartIcon(),
                  ),
                ),
                
                // Title at top-left
                Positioned(
                  left: 25,
                  top: 25,
                  child: RepaintBoundary(
                    child: Text(
                      meditation.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                // Glass timer widget at bottom-left
                Positioned(
                  bottom: 25,
                  left: 25,
                  child: RepaintBoundary(
                    child: _GlassTimer(
                      duration: meditation.duration,
                      textColor: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      openBuilder: (context, closeContainer) => MeditationPlayerScreen(
        meditation: meditation,
      ),
    );
  }

  Color _getTextColor(Color backgroundColor) {
    // Calculate relative luminance to determine text color
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.screenWidth});
  final double screenWidth;

  // Pre-calculate const styles for better performance
  static const Color _backgroundColor = Colors.white;
  static const Color _iconColor = Colors.black54;
  static const Color _textColor = Colors.black;
  static const FontWeight _fontWeight = FontWeight.bold;
  static const double _fontSize = 13;
  static const BorderRadius _borderRadius = BorderRadius.all(Radius.circular(20));
  static const List<BoxShadow> _boxShadow = [
    BoxShadow(
      color: Color(0x1A000000), // Colors.black.withOpacity(0.1)
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate responsive sizes based on screen width
    final chipPadding = screenWidth * 0.04; // 4% of screen width
    final iconSize = screenWidth * 0.05; // 5% of screen width
    final spacing = screenWidth * 0.02; // 2% of screen width
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: Row(
        children: [
          _FilterChip(label: 'Favorites', padding: chipPadding),
          SizedBox(width: spacing),
          _FilterChip(label: 'Daily meditation', padding: chipPadding),
          SizedBox(width: spacing),
          _FilterChip(label: 'New releases', padding: chipPadding),
          SizedBox(width: spacing), // Extra spacing at the end
        ],
      ),
    );
  }
}

// Extract filter chip as const widget
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.padding,
  });
  
  final String label;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: padding,
        vertical: padding * 0.3,
      ),
      decoration: const BoxDecoration(
        color: _BottomNavBar._backgroundColor,
        borderRadius: _BottomNavBar._borderRadius,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _BottomNavBar._textColor,
          fontWeight: _BottomNavBar._fontWeight,
          fontSize: _BottomNavBar._fontSize,
        ),
      ),
    );
  }
}

// Extract glass components as const widgets for better performance
class _GlassHeartIcon extends StatelessWidget {
  const _GlassHeartIcon();

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
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
    );
  }
}

class _GlassTimer extends StatelessWidget {
  const _GlassTimer({
    required this.duration,
    required this.textColor,
  });
  
  final String duration;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
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
      child: Row(
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
      ),
    );
  }
}


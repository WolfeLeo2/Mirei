import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mirei/components/nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

class JournalHomeScreen extends StatefulWidget {
  const JournalHomeScreen({Key? key}) : super(key: key);

  @override
  _JournalHomeScreenState createState() => _JournalHomeScreenState();
}

class _JournalHomeScreenState extends State<JournalHomeScreen> {
  int _currentIndex = 1; // Set initial index to 'journal'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF115e5a), // Deep Teal Background
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 16), // Adjust top padding for status bar
                child: _buildTopBar(),
              ),
              const SizedBox(height: 10),
              _buildGreeting(),
              const SizedBox(height: 20),
              _buildMoodSelector(),
              const SizedBox(height: 20),
              Expanded(
                child: _buildInfoCard(),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: NavBar(
                currentIndex: _currentIndex,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                  if (index == 0) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 32, // Larger avatar
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=12'), // Placeholder image
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Alexandra', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('alexndr@gmail.com', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 34),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    // Using a Stack to layer decorative images over the text.
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none, // Allows positioned items to be visible outside the Stack's bounds
      children: [
        // 1. The main text content
        Column(
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontFamily: GoogleFonts.manrope().fontFamily, color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700, height: 1.3),
                children: const [
                  TextSpan(text: 'Hi, How do you\nfeel '),
                  TextSpan(text: 'today?'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text('Select your current emotion', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),

        // 2. Decorative elements (place your Image.asset widgets here)
        // TODO: Replace these Icon placeholders with your actual Image.asset widgets.
        
        // Apostrophes over 'Hi'
        Positioned(
          top: -10,
          left: -20,
          child: SvgPicture.asset('assets/icons/emphasis.svg', width: 20, height: 20, color: Colors.white), // Placeholder
        ),

        // Underline for 'today?'
        Positioned(
          bottom: 40,
          right: 70,
          child: SvgPicture.asset('assets/icons/speech.svg', width: 24, height: 24, color: Colors.white), // Placeholder
        ),
      ],
    );
  }

  Widget _buildMoodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _moodButton('Excited', true),
          _moodButton('Happy', false),
          _moodButton('Calm', false),
          _moodButton('Worry', false),
          _moodButton('Sad', false),
        ],
      ),
    );
  }

  Widget _moodButton(String mood, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF246b67).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24), // Pill shape
        ),
        child: Text(
          mood,
          style: TextStyle(
            color: isSelected ? const Color(0xFF246b67) : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 120), // Add bottom padding for nav bar
      decoration: const BoxDecoration(
        color: Color(0xfffaf6f1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold, height: 1.4),
                children: [
                  const TextSpan(text: 'Do You know?\n3 Days Your'),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/icons/circle.svg',
                          width: 100, // Adjust as needed for your SVG
                          height: 38,
                          color: const Color(0xFF4CAF50),
                        ),
                        Text(
                          'Happiness',
                          style: TextStyle(
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Some things you might be\ninterested in doing', style: TextStyle(color: Colors.black54, fontSize: 14)),
                const Text('View More', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _activityIcon(Icons.chat_bubble_outline, 'Sharing', const Color(0xFF4CAF50), shape: 2), // Octagon
                _activityIcon(Icons.pie_chart_outline, 'My Progress', const Color(0xFFFFC107), shape: 0), // Circle
                _activityIcon(Icons.self_improvement_outlined, 'Self-Serenity', const Color(0xFF00BCD4), shape: 1), // Hexagon
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityIcon(IconData icon, String label, Color color, {required int shape}) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(60, 60),
            painter: _ShapePainter(
              color: color.withOpacity(0.2),
              borderColor: color,
              shape: shape, // 0: circle, 1: hexagon, 2: octagon
            ),
            child: Container(
              alignment: Alignment.center,
              child: Icon(icon, size: 28, color: color.darker(0.3)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ShapePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final int shape; // 0: circle, 1: hexagon, 2: octagon

  _ShapePainter({
    required this.color,
    required this.borderColor,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;

    switch (shape) {
      case 0: // Circle
        canvas.drawCircle(center, radius, paint);
        canvas.drawCircle(center, radius, borderPaint);
        break;
      case 1: // Hexagon
        _drawHexagon(canvas, center, radius, paint, borderPaint);
        break;
      case 2: // Octagon
        _drawOctagon(canvas, center, radius, paint, borderPaint);
        break;
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint, Paint borderPaint) {
    final path = Path();
    for (int i = 0; i < 7; i++) {
      double x = center.dx + radius * cos(i * 2.0 * 3.14159 / 7 + 3.14159 / 7);
      double y = center.dy + radius * sin(i * 2.0 * 3.14159 / 7 + 3.14159 / 7);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  void _drawOctagon(Canvas canvas, Offset center, double radius, Paint paint, Paint borderPaint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      double x = center.dx + radius * cos(i * 2.0 * 3.14159 / 8 + 3.14159 / 8);
      double y = center.dy + radius * sin(i * 2.0 * 3.14159 / 8 + 3.14159 / 8);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Helper to darken color for icons
extension ColorUtil on Color {
  Color darker(double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

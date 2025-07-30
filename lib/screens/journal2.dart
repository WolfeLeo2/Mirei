import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'progress.dart';

class Journal2Screen extends StatefulWidget {
  const Journal2Screen({super.key});

  @override
  _Journal2ScreenState createState() => _Journal2ScreenState();
}

class _Journal2ScreenState extends State<Journal2Screen> {
  int selectedEmotionIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF115e5a),
      body: Column(
            children: [
              Container(
                color: const Color(0xFF115e5a),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                backgroundImage: NetworkImage(
                                  'https://i.pravatar.cc/150?img=12',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alexandra',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: '.SF Pro Display',
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'alexndr@gmail.com',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      fontFamily: '.SF Pro Text',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Container(height: 2, color: Colors.white),
                                Container(height: 2, color: Colors.white),
                                Container(height: 2, color: Colors.white),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          Text(
                            'Hi, How do you\nfeel today?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                              fontFamily: GoogleFonts.inter().fontFamily,
                            ),
                          ),
                          Positioned(
                            top: -10,
                            left: -20,
                            child: SvgPicture.asset(
                              'assets/icons/emphasis.svg',
                              width: 20,
                              height: 20,
                              color: Colors.white,
                            ),
                          ),
                          Positioned(
                            bottom: -10,
                            right: 50,
                            child: SvgPicture.asset(
                              'assets/icons/underline.svg',
                              width: 17,
                              height: 17,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Select your current emotion',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          fontFamily: '.SF Pro Text',
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                color: const Color(0xFF115e5a),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      _buildEmotionButton('Sorry', '😔', 0),
                      _buildEmotionButton('Excited', '😊', 1),
                      _buildEmotionButton('Happy', '😊', 2),
                      _buildEmotionButton('Worry', '😟', 3),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFfaf6f1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Hook/Handle component
                      Container(
                        margin: const EdgeInsets.only(top: 8, bottom: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF115e5a).withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              20,
                              12,
                              18,
                              100,
                            ), // Added bottom padding for nav bar
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      height: 1.3,
                                      fontFamily:
                                          GoogleFonts.inter().fontFamily,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Do You know?\n3 Days Your',
                                      ),
                                      WidgetSpan(
                                        alignment: PlaceholderAlignment.middle,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/circle.svg',
                                              width: 50,
                                              height: 35,
                                              color: const Color.fromARGB(
                                                255,
                                                180,
                                                235,
                                                117,
                                              ),
                                            ),
                                            Text(
                                              'Happiness',
                                              style: TextStyle(
                                                color: const Color.fromARGB(
                                                  255,
                                                  17,
                                                  84,
                                                  70,
                                                ),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 22,
                                                fontFamily: GoogleFonts.inter()
                                                    .fontFamily,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Some things you might be\ninterested in doing',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                          height: 1.4,
                                          fontFamily:
                                              GoogleFonts.inter().fontFamily,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'View More',
                                      style: TextStyle(
                                        color: const Color(0xFF115e5a),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: '.SF Pro Text',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildActivityIcon(
                                      'Sharing',
                                      const Color(0XFFc6e99f),
                                      'assets/icons/message.svg', // Replace with your actual SVG icon path
                                      'assets/icons/octagon.svg', // Replace with your actual SVG shape path
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const ProgressScreen(),
                                          ),
                                        );
                                      },
                                      child: _buildActivityIcon(
                                        'My Progress',
                                        const Color(0xFFECE9A5),
                                        'assets/icons/pie-chart.svg', // Replace with your actual SVG icon path
                                        'assets/icons/b-circle.svg', // Replace with your actual SVG shape path
                                      ),
                                    ),
                                    _buildActivityIcon(
                                      'Self-Serenity',
                                      const Color(0xFFC1DFDF),
                                      'assets/icons/message.svg', // Replace with your actual SVG icon path
                                      'assets/icons/heptagon.svg', // Replace with your actual SVG shape path
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
      ),
    );
  }

  Widget _buildEmotionButton(String emotion, String emoji, int index) {
    final isSelected = selectedEmotionIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedEmotionIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1a6b67),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              emotion,
              style: TextStyle(
                color: isSelected ? const Color(0xFF115e5a) : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF Pro Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityIcon(
    String label,
    Color backgroundColor,
    String svgIcon,
    String svgShape, {
    double size = 100,
    Color? iconColor, // Optional: custom icon color
    Color? shapeColor, // Optional: custom shape color
  }) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(left: 0, right: 17),
          color: Colors.transparent, // Let SVG shape show through
          child: Stack(
            alignment: Alignment.center,
            children: [
              SvgPicture.asset(
                svgShape,
                width: size,
                height: size,
                color: shapeColor ?? backgroundColor, // shape color
              ),
              SvgPicture.asset(
                svgIcon,
                width: size * 0.4,
                height: size * 0.4,
                color: iconColor ?? Colors.black,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: GoogleFonts.inter().fontFamily,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

}

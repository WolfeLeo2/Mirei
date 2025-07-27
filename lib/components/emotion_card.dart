import 'package:flutter/material.dart';
import 'dart:ui';

class EmotionCard extends StatelessWidget {
  final Gradient gradient;
  final String title;
  final String subtitle;
  final String imagePath;

  const EmotionCard({
    Key? key,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.imagePath = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            // Dynamic image background
            Positioned.fill(
              child: Image.asset(imagePath, fit: BoxFit.cover),
            ),

            // Gradient overlay
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

            // Play button
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

            // Title and subtitle
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
                      color: const Color.fromARGB(255, 20, 50, 81).withAlpha(165),
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
}
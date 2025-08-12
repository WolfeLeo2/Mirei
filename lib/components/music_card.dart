import 'package:flutter/material.dart';

class MusicCard extends StatelessWidget {
  final Gradient gradient;
  final String title;
  final String subtitle;
  final String imagePath;

  const MusicCard({
    super.key,
    required this.gradient,
    required this.title,
    required this.subtitle,
    this.imagePath = '',
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: 265,
        height: 265,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            const BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05), // Reduced opacity
              blurRadius: 12, // Reduced blur radius
              offset: Offset(0, 6), // Reduced offset
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Dynamic image background with caching
              Positioned.fill(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  cacheWidth: 265, // Cache at display size
                  cacheHeight: 265,
                ),
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

              // Play button - simplified for better performance
              Positioned(
                top: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.85), // Increased opacity for visibility
                      shape: BoxShape.circle,
                      boxShadow: [
                        const BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
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
                      style: const TextStyle(
                        color: Color.fromRGBO(20, 50, 81, 0.65),
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
      ),
    );
  }
}

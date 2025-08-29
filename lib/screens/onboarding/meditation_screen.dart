import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class MeditationOnboardingScreen extends StatelessWidget {
  const MeditationOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Meditation illustration
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.primaryLight.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background meditation image
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/meditation.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                ),
                // Floating meditation elements
                Positioned(
                  top: 30,
                  left: 30,
                  child: _buildFloatingElement(Icons.self_improvement, 0),
                ),
                Positioned(
                  top: 50,
                  right: 40,
                  child: _buildFloatingElement(Icons.spa, 1),
                ),
                Positioned(
                  bottom: 60,
                  left: 50,
                  child: _buildFloatingElement(Icons.favorite, 2),
                ),
                Positioned(
                  bottom: 40,
                  right: 30,
                  child: _buildFloatingElement(Icons.psychology, 3),
                ),
                // Center play button
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            'Find Your Inner\nPeace & Balance',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Guided meditations, breathing exercises, and mindfulness practices tailored to your needs.',
            style: GoogleFonts.inter(
              fontSize: 18,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildFloatingElement(IconData icon, int index) {
    final delays = [0, 500, 1000, 1500];

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 2000 + delays[index]),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -10 * value),
          child: Opacity(
            opacity: 0.6 + (0.4 * value),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
          ),
        );
      },
    );
  }
}

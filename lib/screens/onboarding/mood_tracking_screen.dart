import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../core/constants/app_colors.dart';
import 'package:mirei/core/theme/typography.dart';

class MoodTrackingOnboardingScreen extends StatelessWidget {
  const MoodTrackingOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Mood tracking illustration
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
                // Background pattern
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/gradient-2.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Mood icons arranged in a circle
                ...List.generate(6, (index) {
                  final angle = (index * 60.0) * (3.14159 / 180);
                  final radius = 80.0;
                  final x = radius * math.cos(angle);
                  final y = radius * math.sin(angle);

                  final emotions = [
                    'happy',
                    'cutesy',
                    'neutral',
                    'sad',
                    'angry',
                    'worried',
                  ];

                  return Positioned(
                    left: 140 + x - 20,
                    top: 140 + y - 20,
                    child: _buildMoodIcon(emotions[index]),
                  );
                }),
                // Center analytics icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.analytics_outlined,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // Title
          Text(
            'Track Your\nEmotional Journey',
            style: Theme.of(context).textTheme.displaySmall
                ?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                )
                .apply(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          Text(
            'Understand your emotional patterns with beautiful analytics and insights that help you grow.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(fontSize: 18, height: 1.5)
                .apply(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildMoodIcon(String emotion) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/emotion-icons/$emotion.svg',
        width: 24,
        height: 24,
      ),
    );
  }
}

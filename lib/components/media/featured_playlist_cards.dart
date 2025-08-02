import 'package:flutter/material.dart';

class FeaturedPlaylistCards extends StatelessWidget {
  const FeaturedPlaylistCards({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildFeaturedCard(
            title: 'Anxiety Relief',
            subtitle:
                'Guided meditations and calming sounds for anxiety management.',
            colors: [
              const Color(0xFF6366f1),
              const Color(0xFF4f46e5),
              const Color(0xFF3730a3),
            ],
            logoText: 'Mirei Originals',
          ),
          const SizedBox(width: 10),
          _buildFeaturedCard(
            title: 'Sleep Stories',
            subtitle:
                'Peaceful bedtime stories and soundscapes for better sleep.',
            colors: [
              const Color(0xFF8b5cf6),
              const Color(0xFF7c3aed),
              const Color(0xFF5b21b6),
            ],
            logoText: 'Mirei Originals',
          ),
          const SizedBox(width: 10),
          _buildFeaturedCard(
            title: 'Focus Flow',
            subtitle:
                'Concentration music and ambient sounds for productivity.',
            colors: [
              const Color(0xFF06b6d4),
              const Color(0xFF0891b2),
              const Color(0xFF0e7490),
            ],
            logoText: 'Mirei Originals',
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedCard({
    required String title,
    required String subtitle,
    required List<Color> colors,
    required String logoText,
  }) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mirei Originals logo
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.self_improvement,
                    color: Color(0xFF6366f1),
                    size: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  logoText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Title
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Subtitle
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

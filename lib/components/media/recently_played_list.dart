import 'package:flutter/material.dart';

class RecentlyPlayedList extends StatelessWidget {
  const RecentlyPlayedList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildRecentlyPlayedItem(
            title: 'Mindful Breathing',
            colors: [const Color(0xFF4F7CAC), const Color(0xFF9B59B6)],
            logoText: 'Mirei Originals',
          ),
          const SizedBox(width: 12),
          _buildRecentlyPlayedItem(
            title: 'Nature Sounds',
            colors: [const Color(0xFF2ECC71), const Color(0xFF27AE60)],
            logoText: 'Mirei Originals',
          ),
          const SizedBox(width: 12),
          _buildRecentlyPlayedItem(
            title: 'Stress Relief',
            colors: [const Color(0xFFE74C3C), const Color(0xFFFF6B35)],
            logoText: 'Mirei Originals',
          ),
          const SizedBox(width: 12),
          _buildRecentlyPlayedItem(
            title: 'Morning Energy',
            colors: [const Color(0xFFF39C12), const Color(0xFFE67E22)],
            logoText: 'Mirei Originals',
          ),
          const SizedBox(width: 12),
          _buildRecentlyPlayedItem(
            title: 'Deep Sleep',
            colors: [const Color(0xFF8E44AD), const Color(0xFF9B59B6)],
            logoText: 'Mirei Originals',
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyPlayedItem({
    required String title,
    required List<Color> colors,
    required String logoText,
  }) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mirei Originals logo
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.self_improvement,
                    color: Color(0xFF6366f1),
                    size: 8,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  logoText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Play icon
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class RecommendationsGrid extends StatelessWidget {
  const RecommendationsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recommended for You',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) {
              final recommendations = [
                {
                  'title': 'Mood Boost Mix',
                  'subtitle': 'Uplifting wellness tracks',
                  'icon': Icons.sentiment_very_satisfied,
                  'color': const Color(0xFFf59e0b),
                },
                {
                  'title': 'Deep Focus',
                  'subtitle': 'Concentration enhancers',
                  'icon': Icons.psychology,
                  'color': const Color(0xFF3b82f6),
                },
                {
                  'title': 'Stress Away',
                  'subtitle': 'Calming soundscapes',
                  'icon': Icons.spa,
                  'color': const Color(0xFF10b981),
                },
                {
                  'title': 'Night Wind Down',
                  'subtitle': 'Evening relaxation',
                  'icon': Icons.bedtime,
                  'color': const Color(0xFF8b5cf6),
                },
              ];

              final recommendation = recommendations[index];

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (recommendation['color'] as Color).withOpacity(0.8),
                      (recommendation['color'] as Color),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (recommendation['color'] as Color).withOpacity(
                        0.3,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          recommendation['icon'] as IconData,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        recommendation['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation['subtitle'] as String,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class ContinueListeningSection extends StatelessWidget {
  const ContinueListeningSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Continue Listening',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            itemBuilder: (context, index) {
              final tracks = [
                {
                  'title': 'Morning Meditation',
                  'artist': 'Dr. Sarah Chen',
                  'progress': 0.6,
                  'color': const Color(0xFF6366f1),
                },
                {
                  'title': 'Sleep Story: Forest',
                  'artist': 'Nature Sounds',
                  'progress': 0.3,
                  'color': const Color(0xFF059669),
                },
                {
                  'title': 'Anxiety Relief Session',
                  'artist': 'Mindful Moments',
                  'progress': 0.8,
                  'color': const Color(0xFF7c3aed),
                },
                {
                  'title': 'Focus Boost',
                  'artist': 'Productivity Pro',
                  'progress': 0.15,
                  'color': const Color(0xFF0891b2),
                },
              ];

              final track = tracks[index];

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: track['color'] as Color,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            track['title'] as String,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            track['artist'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: track['progress'] as double,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              track['color'] as Color,
                            ),
                            minHeight: 2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

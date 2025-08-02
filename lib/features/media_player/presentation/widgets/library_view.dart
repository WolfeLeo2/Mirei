import 'package:flutter/material.dart';
import 'package:mirei/components/media/featured_playlist_cards.dart';
import 'package:mirei/components/media/recently_played_list.dart';
import 'package:mirei/components/media/continue_listening_section.dart';
import 'package:mirei/components/media/recommendations_grid.dart';

class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildListDelegate([
        // Continue Listening Section
        const SizedBox(height: 20),
        const ContinueListeningSection(),

        // Mirei Originals Section
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mirei Originals',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        
        // Featured Playlists
        const FeaturedPlaylistCards(),

        // Recommendations Grid
        const SizedBox(height: 40),
        const RecommendationsGrid(),

        // Recently Played Section
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Explore',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey[600], size: 24),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        
        // Recently Played List
        const RecentlyPlayedList(),

        // Bottom spacing for mini player and navigation
        const SizedBox(height: 220),
      ]),
    );
  }
}

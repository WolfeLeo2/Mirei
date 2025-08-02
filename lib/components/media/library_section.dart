import 'package:flutter/material.dart';

class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Library',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Vertical library items
        _buildLibraryItem(
          icon: Icons.favorite,
          title: 'Favorites',
          subtitle: '12 tracks',
          color: const Color(0xFFe11d48),
        ),
        _buildLibraryItem(
          icon: Icons.download_done,
          title: 'Downloaded',
          subtitle: '8 tracks',
          color: const Color(0xFF059669),
        ),
        _buildLibraryItem(
          icon: Icons.history,
          title: 'Recently Played',
          subtitle: '25 tracks',
          color: const Color(0xFF7c3aed),
        ),
        _buildLibraryItem(
          icon: Icons.queue_music,
          title: 'My Playlists',
          subtitle: '5 playlists',
          color: const Color(0xFF0891b2),
        ),
        _buildLibraryItem(
          icon: Icons.album,
          title: 'Albums',
          subtitle: '15 albums',
          color: const Color(0xFFf59e0b),
        ),
        _buildLibraryItem(
          icon: Icons.person,
          title: 'Artists',
          subtitle: '32 artists',
          color: const Color(0xFF06b6d4),
        ),
        _buildLibraryItem(
          icon: Icons.podcasts,
          title: 'Podcasts',
          subtitle: '3 shows',
          color: const Color(0xFF8b5cf6),
        ),
        _buildLibraryItem(
          icon: Icons.radio,
          title: 'Stations',
          subtitle: '7 stations',
          color: const Color(0xFF10b981),
        ),
      ],
    );
  }

  Widget _buildLibraryItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }
}

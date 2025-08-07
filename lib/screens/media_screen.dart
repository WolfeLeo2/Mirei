import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/media_player_modal.dart';
import 'playlist_screen.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  _MediaScreenState createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  // Static data for better performance
  static const List<Map<String, String>> _albumData = [
    {
      'title': 'Lofi Mix',
      'subtitle': 'Kick back and relax',
      'image': 'assets/images/lofi.png',
    },
    {
      'title': 'Ocean Waves',
      'subtitle': 'Nature Sounds',
      'image': 'assets/images/bg-afternoon.jpg',
    },
    {
      'title': 'Morning Jazz',
      'subtitle': 'Relaxing Vibes',
      'image': 'assets/images/bg-evening.jpg',
    },
  ];

  static const List<Map<String, String>> _mixData = [
    {
      'title': 'Bedroom Pop',
      'subtitle': 'Dreamy bedroom pop vibes',
      'image': 'assets/images/color.jpg',
    },
    {
      'title': 'Soul Mix',
      'subtitle': 'Deep soul vibes',
      'image': 'assets/images/bg-morning.jpg',
    },
    {
      'title': 'R&B Mix',
      'subtitle': 'Smooth R&B classics',
      'image': 'assets/images/bg-afternoon.jpg',
    },
    {
      'title': 'Chill Mix',
      'subtitle': 'Relaxing chill beats',
      'image': 'assets/images/bg-evening.jpg',
    },
    {
      'title': 'Moody Mix',
      'subtitle': 'Moody atmosphere',
      'image': 'assets/images/gradient.png',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfaf6f1),
      appBar: const _OptimizedAppBar(),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: 'Top Picks'),
          SizedBox(height: 16),
          _AlbumCardsSection(),
          SizedBox(height: 32),
          _SectionHeader(title: 'Your top mixes'),
          SizedBox(height: 16),
          _MixCardsSection(),
        ],
      ),
    );
  }
}

// Optimized const widgets for better performance
class _OptimizedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _OptimizedAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFfaf6f1),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF115e5a),
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Media Library',
        style: GoogleFonts.inter(
          color: const Color(0xFF115e5a),
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: Color(0xFF115e5a)),
          onPressed: () {
            // TODO: Implement search functionality
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF115e5a),
        ),
      ),
    );
  }
}

class _AlbumCardsSection extends StatelessWidget {
  const _AlbumCardsSection();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 260,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _MediaScreenState._albumData.length,
          cacheExtent: 400, // Pre-cache nearby items
          itemBuilder: (context, index) {
            final album = _MediaScreenState._albumData[index];
            return RepaintBoundary(
              child: _MediaCard(
                title: album['title']!,
                subtitle: album['subtitle']!,
                imagePath: album['image']!,
                width: 200,
                onTap: () {
                  showMediaPlayerModal(
                    context: context,
                    trackTitle: album['title']!,
                    artistName: 'Various Artists',
                    albumArt: album['image']!,
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MixCardsSection extends StatelessWidget {
  const _MixCardsSection();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        height: 260,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _MediaScreenState._mixData.length,
          cacheExtent: 400, // Pre-cache nearby items
          itemBuilder: (context, index) {
            final mix = _MediaScreenState._mixData[index];
            return RepaintBoundary(
              child: _MediaCard(
                title: mix['title']!,
                subtitle: mix['subtitle']!,
                imagePath: mix['image']!,
                width: 200,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlaylistScreen(
                        playlistTitle: mix['title']!,
                        playlistUrl: 'https://wolfeleo2.github.io/audio-cdn/api/bedroompop.json', // Default URL
                        albumArt: mix['image']!,
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.width,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album artwork container with optimized image loading
            Container(
              width: 180,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  cacheWidth: 180, // Cache at display size
                  cacheHeight: 200,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                color: const Color(0xFF115e5a),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: const Color(0xFF115e5a).withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

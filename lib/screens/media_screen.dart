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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFfaf6f1),
      appBar: AppBar(
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header with padding
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Text(
              'Top Picks',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF115e5a),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Edge-to-edge album cards
          _buildAlbumCards(),

          const SizedBox(height: 32),

          // Your top mixes section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Text(
              'Your top mixes',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF115e5a),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Edge-to-edge mix cards
          _buildMixCards(),
        ],
      ),
    );
  }

  Widget _buildAlbumCards() {
    return SizedBox(
      height: 260, // Further increased height to prevent overflow
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ), // Only horizontal padding for first/last items
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) {
          final albumTitles = ['Lofi Mix', 'Ocean Waves', 'Morning Jazz'];
          final albumSubtitles = [
            'Kick back and relax',
            'Nature Sounds',
            'Relaxing Vibes',
          ];
          final albumImages = [
            'assets/images/lofi.png',
            'assets/images/bg-afternoon.jpg',
            'assets/images/bg-evening.jpg',
          ];

          return RepaintBoundary(
            child: GestureDetector(
              onTap: () {
                showMediaPlayerModal(
                  context: context,
                  trackTitle: albumTitles[index],
                  artistName: 'Various Artists',
                  albumArt: albumImages[index],
                );
              },
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Album artwork container
                    Container(
                      width: 180,
                      height:
                          200, // Reduced from 200 to 180 to make room for text
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          albumImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // Text below the image
                    const SizedBox(height: 12),
                    Text(
                      albumTitles[index],
                      style: GoogleFonts.inter(
                        color: const Color(0xFF115e5a),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      albumSubtitles[index],
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildMixCards() {
    return SizedBox(
      height: 260, // Same height as album cards
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
        ), // Only horizontal padding for first/last items
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          final mixTitles = [
            'Bedroom Pop',
            'Soul Mix',
            'R&B Mix',
            'Chill Mix',
            'Moody Mix',
          ];
          final mixSubtitles = [
            'Dreamy bedroom pop vibes',
            'Deep soul vibes',
            'Smooth R&B classics',
            'Relaxing chill beats',
            'Moody atmosphere',
          ];
          final mixImages = [
            'assets/images/color.jpg',
            'assets/images/bg-morning.jpg',
            'assets/images/bg-afternoon.jpg',
            'assets/images/bg-evening.jpg',
            'assets/images/gradient.png',
          ];
          final mixUrls = [
            'https://wolfeleo2.github.io/audio-cdn/bedroompop/',
            'https://wolfeleo2.github.io/audio-cdn/soul/',
            'https://wolfeleo2.github.io/audio-cdn/rnb/',
            'https://wolfeleo2.github.io/audio-cdn/chill/',
            'https://wolfeleo2.github.io/audio-cdn/moody/',
          ];

          return RepaintBoundary(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistScreen(
                      playlistTitle: mixTitles[index],
                      playlistUrl: mixUrls[index],
                      albumArt: mixImages[index],
                    ),
                  ),
                );
              },
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mix artwork container
                    Container(
                      width: 180,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          mixImages[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback gradient if image not found
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF115e5a),
                                    const Color(0xFF115e5a).withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.music_note,
                                  size: 40,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // Text below the image
                    const SizedBox(height: 12),
                    Text(
                      mixTitles[index],
                      style: GoogleFonts.inter(
                        color: const Color(0xFF115e5a),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mixSubtitles[index],
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
            ),
          );
        },
      ),
    );
  }
}

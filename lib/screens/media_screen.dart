import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/media_player_modal.dart';
import 'playlist_screen.dart';

// Static data classes for better performance
class _AlbumData {
  final String title;
  final String subtitle;
  final String imagePath;

  const _AlbumData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });
}

class _MixData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String url;

  const _MixData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.url,
  });
}

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key});

  @override
  _MediaScreenState createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  // Static const data for better performance
  static const List<_AlbumData> _albumData = [
    _AlbumData(
      title: 'Lofi Mix',
      subtitle: 'Kick back and relax',
      imagePath: 'assets/images/lofi.png',
    ),
    _AlbumData(
      title: 'Ocean Waves',
      subtitle: 'Nature Sounds',
      imagePath: 'assets/images/bg-afternoon.jpg',
    ),
    _AlbumData(
      title: 'Morning Jazz',
      subtitle: 'Relaxing Vibes',
      imagePath: 'assets/images/bg-evening.jpg',
    ),
  ];

  static const List<_MixData> _mixData = [
    _MixData(
      title: 'Bedroom Pop',
      subtitle: 'Dreamy bedroom pop vibes',
      imagePath: 'assets/images/color.jpg',
      url: 'https://wolfeleo2.github.io/audio-cdn/bedroompop/',
    ),
    _MixData(
      title: 'Soul Mix',
      subtitle: 'Deep soul vibes',
      imagePath: 'assets/images/bg-morning.jpg',
      url: 'https://wolfeleo2.github.io/audio-cdn/soul/',
    ),
    _MixData(
      title: 'R&B Mix',
      subtitle: 'Smooth R&B classics',
      imagePath: 'assets/images/bg-afternoon.jpg',
      url: 'https://wolfeleo2.github.io/audio-cdn/rnb/',
    ),
    _MixData(
      title: 'Chill Mix',
      subtitle: 'Relaxing chill beats',
      imagePath: 'assets/images/bg-evening.jpg',
      url: 'https://wolfeleo2.github.io/audio-cdn/chill/',
    ),
    _MixData(
      title: 'Moody Mix',
      subtitle: 'Moody atmosphere',
      imagePath: 'assets/images/gradient.png',
      url: 'https://wolfeleo2.github.io/audio-cdn/moody/',
    ),
  ];

  // Const text styles for better performance
  static final TextStyle _sectionHeaderStyle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF115e5a),
  );

  static final TextStyle _cardTitleStyle = GoogleFonts.inter(
    color: const Color(0xFF115e5a),
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: -0.3,
  );

  static final TextStyle _cardSubtitleStyle = GoogleFonts.inter(
    color: const Color(0xFF115e5a).withValues(alpha: 0.6),
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );
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
          // Section header with RepaintBoundary
          RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Top Picks',
                style: _sectionHeaderStyle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Optimized album cards with RepaintBoundary
          _buildAlbumCards(),

          const SizedBox(height: 32),

          // Your top mixes section with RepaintBoundary
          RepaintBoundary(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Text(
                'Your top mixes',
                style: _sectionHeaderStyle,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Optimized mix cards with RepaintBoundary
          _buildMixCards(),
        ],
      ),
    );
  }

  Widget _buildAlbumCards() {
    return RepaintBoundary(
      child: SizedBox(
        height: 260,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _albumData.length,
          itemBuilder: (context, index) {
            final album = _albumData[index];
            return _AlbumCard(
              album: album,
              onTap: () => _handleAlbumTap(album),
            );
          },
        ),
      ),
    );
  }

  void _handleAlbumTap(_AlbumData album) {
    showMediaPlayerModal(
      context: context,
      trackTitle: album.title,
      artistName: 'Various Artists',
      albumArt: album.imagePath,
    );
  }

  Widget _buildMixCards() {
    return RepaintBoundary(
      child: SizedBox(
        height: 260,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _mixData.length,
          itemBuilder: (context, index) {
            final mix = _mixData[index];
            return _MixCard(
              mix: mix,
              onTap: () => _handleMixTap(mix),
            );
          },
        ),
      ),
    );
  }

  void _handleMixTap(_MixData mix) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistScreen(
          playlistTitle: mix.title,
          playlistUrl: mix.url,
          albumArt: mix.imagePath,
        ),
      ),
    );
  }
}

// Optimized Album Card widget with RepaintBoundary
class _AlbumCard extends StatelessWidget {
  final _AlbumData album;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.album,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Album artwork container with RepaintBoundary
              RepaintBoundary(
                child: Container(
                  width: 180,
                  height: 200,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      album.imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              // Text section with RepaintBoundary
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      album.title,
                      style: _MediaScreenState._cardTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      album.subtitle,
                      style: _MediaScreenState._cardSubtitleStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Optimized Mix Card widget with RepaintBoundary
class _MixCard extends StatelessWidget {
  final _MixData mix;
  final VoidCallback onTap;

  const _MixCard({
    required this.mix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mix artwork container with RepaintBoundary
              RepaintBoundary(
                child: Container(
                  width: 180,
                  height: 200,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      mix.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const _FallbackMixImage();
                      },
                    ),
                  ),
                ),
              ),
              // Text section with RepaintBoundary
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      mix.title,
                      style: _MediaScreenState._cardTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mix.subtitle,
                      style: _MediaScreenState._cardSubtitleStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Const fallback image widget
class _FallbackMixImage extends StatelessWidget {
  const _FallbackMixImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF115e5a),
            Color.fromRGBO(17, 94, 90, 0.7),
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note,
          size: 40,
          color: Color.fromRGBO(255, 255, 255, 0.8),
        ),
      ),
    );
  }
}

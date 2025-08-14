import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/media_player_modal.dart';
import 'playlist_screen.dart';
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../bloc/media_player_state.dart';
import '../utils/performance_mixins.dart'; // Add this import

// Static data classes for better performance
class _AlbumData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String? url;

  const _AlbumData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.url,
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

class _LiveRadioData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String url;

  const _LiveRadioData({
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
      title: 'You Need to sleep',
      subtitle: "Nothing's going to change",
      imagePath: 'assets/images/window.jpg',
      url: 'https://wolfeleo2.github.io/audio-cdn/picks/Shiloh.m4a',
    ),
    _AlbumData(
      title: 'Ocean Waves',
      subtitle: 'Nature Sounds',
      imagePath: 'assets/images/bg-afternoon.jpg',
      url: 'https://www.youtube.com/watch?v=5yx6BWlEVcY',
    ),
    _AlbumData(
      title: 'Morning Jazz',
      subtitle: 'Relaxing Vibes',
      imagePath: 'assets/images/bg-evening.jpg',
      url: 'https://www.youtube.com/watch?v=kgx4WGK0oNU',
    ),
  ];

  static const List<_MixData> _mixData = [
    _MixData(
      title: 'Bedroom Pop',
      subtitle: 'Dreamy bedroom pop vibes',
      imagePath: 'assets/images/lofi.png',
      url: 'https://wolfeleo2.github.io/audio-cdn/bedroompop/',
    ),
    _MixData(
      title: 'Moody Mix',
      subtitle: 'Moody atmosphere',
      imagePath: 'assets/images/moody.jpg',
      url: 'https://wolfeleo2.github.io/audio-cdn/moody/',
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
    
  ];

  static const List<_LiveRadioData> _liveRadioData = [
    _LiveRadioData(
      title: 'LoFi Hip Hop Radio',
      subtitle: '24/7 Chill Beats • Live',
      imagePath: 'assets/images/lofi_cover.png',
      url: 'http://manager.dhectar.fr:1480/stream',
    ),
    _LiveRadioData(
      title: 'Chillhop Radio',
      subtitle: 'Jazzy Hip Hop • Live',
      imagePath: 'assets/images/gradient-2.png',
      url: 'http://puma.streemlion.com:3620/stream',
    ),
    _LiveRadioData(
      title: 'Chill R&B',
      subtitle: 'Relaxing R&B Vibes • Live',
      imagePath: 'assets/images/rnb_cover.png',
      url: 'http://216.245.218.194:8010/autodj',
    ),
  ];

  // Const text styles for better performance
  static final TextStyle _sectionHeaderStyle = GoogleFonts.inter(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF115e5a),
  );

  static final TextStyle _cardTitleStyle = GoogleFonts.inter(
    color: Colors.black87,
    fontWeight: FontWeight.bold,
    fontSize: 16,
    letterSpacing: -0.3,
  );

  static final TextStyle _cardSubtitleStyle = GoogleFonts.inter(
    color: Colors.black87.withOpacity(0.6),
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFd7dfe5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFd7dfe5),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF115e5a),
                size: 20,
              ),
              //onPressed: () => Navigator.pop(context)),
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
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            physics: const BouncingScrollPhysics(),
            children: [
              RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text('Live Radio', style: _sectionHeaderStyle),
                ),
              ),
              const SizedBox(height: 16),
              _buildLiveRadioCards(state),
              const SizedBox(height: 32),
              RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text('Top Picks', style: _sectionHeaderStyle),
                ),
              ),
              const SizedBox(height: 16),
              _buildAlbumCards(),
              const SizedBox(height: 32),
              RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text('Your top mixes', style: _sectionHeaderStyle),
                ),
              ),
              const SizedBox(height: 16),
              _buildMixCards(),
              const SizedBox(height: 60), // Space for the bottom nav bar
            ],
          ),
        );
      },
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
      audioUrl: album.url,
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
            return _MixCard(mix: mix, onTap: () => _handleMixTap(mix));
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
          playlistDescription: mix.subtitle,
        ),
      ),
    );
  }

  Widget _buildLiveRadioCards(MediaPlayerState state) {
    return RepaintBoundary(
      child: SizedBox(
        height: 260,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: _liveRadioData.length,
          itemBuilder: (context, index) {
            final station = _liveRadioData[index];
            final isCurrent = state.isLiveStream && state.trackTitle == station.title;
            final isLoading = (state.isLoading || state.isBuffering) && isCurrent;
            final isPlaying = isCurrent && state.isPlaying;
            final isPaused = isCurrent && !isPlaying && !isLoading && !state.hasError;

            return _LiveRadioCard(
              station: station,
              onTap: () => _handleLiveRadioTap(station),
              isPlaying: isPlaying,
              isPaused: isPaused,
              isError: isCurrent && state.hasError,
              isLoading: isLoading,
              onPauseOrResume: isCurrent
                  ? () {
                      if (state.isPlaying) {
                        context.read<MediaPlayerBloc>().add(const Pause());
                      } else {
                        context.read<MediaPlayerBloc>().add(const Play());
                      }
                    }
                  : null,
              onStop: isCurrent
                  ? () => context.read<MediaPlayerBloc>().add(const Pause()) // Using Pause as a Stop
                  : null,
            );
          },
        ),
      ),
    );
  }

  void _handleLiveRadioTap(_LiveRadioData station) {
    context.read<MediaPlayerBloc>().add(
          Initialize(
            trackTitle: station.title,
            artistName: station.subtitle,
            albumArt: station.imagePath,
            audioUrl: station.url,
            autoPlay: true,
          ),
        );
  }
}

// Optimized Album Card widget with RepaintBoundary
class _AlbumCard extends StatelessWidget {
  final _AlbumData album;
  final VoidCallback onTap;

  const _AlbumCard({required this.album, required this.onTap});

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
                    child: Image.asset(album.imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
              // Text section with RepaintBoundary
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(album.title, style: _MediaScreenState._cardTitleStyle),
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

  const _MixCard({required this.mix, required this.onTap});

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
                    child: Image.asset(mix.imagePath, fit: BoxFit.cover),
                  ),
                ),
              ),
              // Text section with RepaintBoundary
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(mix.title, style: _MediaScreenState._cardTitleStyle),
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

// Live Radio Card widget
class _LiveRadioCard extends StatelessWidget {
  final _LiveRadioData station;
  final VoidCallback onTap;
  final bool isPlaying;
  final bool isPaused;
  final bool isError;
  final bool isLoading;
  final VoidCallback? onPauseOrResume;
  final VoidCallback? onStop;

  const _LiveRadioCard({
    required this.station,
    required this.onTap,
    required this.isPlaying,
    required this.isPaused,
    required this.isError,
    required this.isLoading,
    this.onPauseOrResume,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCardTappable = !isPlaying && !isLoading;
    return RepaintBoundary(
      child: GestureDetector(
        onTap: isCardTappable ? onTap : null,
        child: Container(
          width: 200,
          margin: const EdgeInsets.only(right: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Station artwork container
              RepaintBoundary(
                child: Stack(
                  children: [
                    Container(
                      width: 180,
                      height: 200,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          station.imagePath,
                          fit: BoxFit.cover,
                          color: isPlaying
                              ? Colors.black.withOpacity(0.2)
                              : isPaused
                              ? Colors.black.withOpacity(0.08)
                              : Colors.black.withOpacity(0.05),
                          colorBlendMode: BlendMode.darken,
                        ),
                      ),
                    ),
                    // Live indicator
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? Colors.red
                              : isPaused
                              ? Colors.orange
                              : Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'LIVE',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Play/Pause/Error indicator
                    if (isLoading)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF115e5a),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 1,
                                ),
                              ),
                              Icon(
                                Icons.graphic_eq,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (isPlaying || isPaused)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Waveform icon (always shown when playing)
                            if (isPlaying)
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF115e5a),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.graphic_eq,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ), // No GestureDetector here, so no tap action
                            // Pause/Resume button
                            GestureDetector(
                              onTap: onPauseOrResume,
                              child: Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              // Text section
              RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      station.title,
                      style: _MediaScreenState._cardTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      station.subtitle,
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
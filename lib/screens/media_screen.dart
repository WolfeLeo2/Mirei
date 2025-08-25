import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:spotify/spotify.dart' as SpotifyApi;
import 'package:url_launcher/url_launcher.dart';

import '../utils/new_media_player_modal.dart';
import 'playlist_screen.dart';
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../bloc/media_player_state.dart';
import '../services/spotify_service.dart';
import '../widgets/spotify_music_card.dart';

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
  final SpotifyService _spotifyService = SpotifyService();

  // Spotify state
  bool _isSpotifyConnected = false;
  bool _hasSpotifyPremium = false;
  bool _isLoadingSpotify = false;
  List<SpotifyApi.Track> _spotifyTracks = [];
  List<SpotifyApi.PlaylistSimple> _spotifyPlaylists = [];

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
              // Spotify Integration Section
              RepaintBoundary(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesome.spotify_brand,
                        size: 24,
                        color: Colors.green[400],
                      ),
                      const SizedBox(width: 8),
                      Text('Music from Spotify', style: _sectionHeaderStyle),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSpotifySection(),
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
    // NEW SYSTEM: Use unified modal - much cleaner!
    showLocalPlayerModal(
      context,
      title: album.title,
      artist: 'Various Artists',
      audioUrl: album.url ?? '',
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

  Widget _buildSpotifySection() {
    if (!_isSpotifyConnected) {
      return _buildSpotifyConnectButton();
    }

    return Column(
      children: [
        // Search and connect status
        _buildSpotifySearchAndStatus(),
        const SizedBox(height: 16),

        // Spotify tracks
        if (_spotifyTracks.isNotEmpty) ...[
          _buildSpotifyTracksSection(),
          const SizedBox(height: 24),
        ],

        // Spotify playlists
        if (_spotifyPlaylists.isNotEmpty) _buildSpotifyPlaylistsSection(),
      ],
    );
  }

  Widget _buildSpotifyConnectButton() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withOpacity(0.1),
            Colors.green.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoadingSpotify ? null : _connectToSpotify,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Icon(
                    FontAwesome.spotify_brand,
                    color: Colors.green[400],
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Connect to Spotify',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Access millions of meditation and relaxing tracks',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingSpotify)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green[400],
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpotifySearchAndStatus() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            FontAwesome.magnifying_glass_solid,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search meditation music...',
                hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
                border: InputBorder.none,
                isDense: true,
              ),
              style: GoogleFonts.inter(color: Colors.black87),
              cursorColor: Colors.black87,
              onSubmitted: _searchSpotifyTracks,
            ),
          ),
          const SizedBox(width: 16),
          if (_isLoadingSpotify)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green,
              ),
            )
          else
            Icon(FontAwesome.spotify_brand, color: Colors.green[400], size: 20),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Future<void> _connectToSpotify() async {
    setState(() => _isLoadingSpotify = true);

    try {
      print('🎵 Connecting to Spotify...');
      final success = await _spotifyService.authenticateUser();

      if (success) {
        setState(() {
          _isSpotifyConnected = true;
          _hasSpotifyPremium = _spotifyService.hasSpotifyPremium;
          _isLoadingSpotify = false;
        });

        // Load initial meditation tracks
        await _searchSpotifyTracks('meditation music relaxing');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected to Spotify! 🎵'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isLoadingSpotify = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect to Spotify'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingSpotify = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _searchSpotifyTracks(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isLoadingSpotify = true);

    try {
      final tracks = await _spotifyService.searchTracks(query, limit: 10);
      final playlists = await _spotifyService.getMeditationPlaylists();

      setState(() {
        _spotifyTracks = tracks;
        _spotifyPlaylists = playlists;
        _isLoadingSpotify = false;
      });
    } catch (e) {
      setState(() => _isLoadingSpotify = false);
      print('Search error: $e');
    }
  }

  Widget _buildSpotifyTracksSection() {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your Tracks',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF115e5a),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _spotifyTracks.length,
              itemBuilder: (context, index) {
                final track = _spotifyTracks[index];
                return SpotifyMusicCard(
                  track: track,
                  onTap: () => _handleSpotifyTrackTap(track),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotifyPlaylistsSection() {
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Your Playlists',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF115e5a),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 260,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _spotifyPlaylists.length,
              itemBuilder: (context, index) {
                final playlist = _spotifyPlaylists[index];
                return SpotifyMusicCard(
                  playlist: playlist,
                  onTap: () => _handleSpotifyPlaylistTap(playlist),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSpotifyTrackTap(SpotifyApi.Track track) {
    // Only Premium users can play Spotify tracks
    if (!_hasSpotifyPremium) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Spotify Premium required for full track playback',
          ),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'Upgrade',
            textColor: Colors.white,
            onPressed: () {
              // Open Spotify Premium upgrade page
              _openSpotifyUrl('https://www.spotify.com/premium/');
            },
          ),
        ),
      );
      return;
    }

    // NEW SYSTEM: Use unified modal - much cleaner!
    showSpotifyPlayerModal(context, track, _spotifyService);
  }

  void _handleSpotifyPlaylistTap(SpotifyApi.PlaylistSimple playlist) {
    final spotifyUrl = playlist.externalUrls?.spotify;

    if (spotifyUrl != null) {
      // Open playlist directly in Spotify app/web
      _openSpotifyUrl(spotifyUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open playlist'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openSpotifyUrl(String url) async {
    try {
      // Use url_launcher to open Spotify URL
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Opening playlist in Spotify...'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open Spotify URL'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open playlist: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            final isCurrent =
                state.isLiveStream && state.trackTitle == station.title;
            final isLoading =
                (state.isLoading || state.isBuffering) && isCurrent;
            final isPlaying = isCurrent && state.isPlaying;
            final isPaused =
                isCurrent && !isPlaying && !isLoading && !state.hasError;

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
                  ? () => context
                        .read<MediaPlayerBloc>()
                        .add(const Pause()) // Using Pause as a Stop
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

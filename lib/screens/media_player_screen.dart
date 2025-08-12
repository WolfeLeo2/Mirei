import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:just_audio/just_audio.dart';
import 'dart:ui';
import 'dart:convert';
// import 'dart:typed_data';
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../bloc/media_player_state.dart';

ImageProvider? _albumArtProvider;
String? _lastAlbumArt;

class MediaPlayerScreen extends StatefulWidget {
  final String trackTitle;
  final String artistName;
  final String albumArt;
  final String? audioUrl; // Optional custom audio URL
  final List<Map<String, dynamic>>? playlist; // Optional playlist
  final int? currentIndex; // Optional current song index

  const MediaPlayerScreen({
    super.key,
    required this.trackTitle,
    required this.artistName,
    required this.albumArt,
    this.audioUrl,
    this.playlist,
    this.currentIndex,
  });

  @override
  _MediaPlayerScreenState createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen>
    with TickerProviderStateMixin {
  late AnimationController _albumRotationController;
  late AnimationController _waveController;
  ImageProvider? _albumArtProvider;
  String? _lastAlbumArt;

  @override
  void initState() {
    super.initState();

    _albumRotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _updateAlbumArtProvider(widget.albumArt);
    print('\n🎬 MediaPlayerScreen initState called with:');
    print('   - trackTitle: ${widget.trackTitle}');
    print('   - artistName: ${widget.artistName}');
    print('   - audioUrl: ${widget.audioUrl}');
    print('   - playlist length: ${widget.playlist?.length ?? 0}');
    print('   - currentIndex: ${widget.currentIndex}');
    print('   - albumArt: ${widget.albumArt}');

    final initializeEvent = Initialize(
      trackTitle: widget.trackTitle,
      artistName: widget.artistName,
      albumArt: widget.albumArt,
      audioUrl: widget.audioUrl,
      playlist: widget.playlist,
      currentIndex: widget.currentIndex,
      autoPlay: true,
    );

    print('🚀 Adding Initialize event to MediaPlayerBloc with autoPlay: true');
    context.read<MediaPlayerBloc>().add(initializeEvent);
  }

  @override
  void didUpdateWidget(covariant MediaPlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.albumArt != _lastAlbumArt) {
      _updateAlbumArtProvider(widget.albumArt);
    }
  }

  void _updateAlbumArtProvider(String albumArt) {
    _lastAlbumArt = albumArt;
    if (albumArt.startsWith('data:')) {
      try {
        final base64String = albumArt.split(',')[1];
        final bytes = base64Decode(base64String);
        _albumArtProvider = MemoryImage(bytes);
      } catch (e) {
        _albumArtProvider = null;
      }
    } else if (albumArt.startsWith('http')) {
      _albumArtProvider = CachedNetworkImageProvider(albumArt);
    } else if (albumArt.isNotEmpty) {
      _albumArtProvider = AssetImage(albumArt);
    } else {
      _albumArtProvider = null;
    }
  }

  @override
  void dispose() {
    _albumRotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return BlocConsumer<MediaPlayerBloc, MediaPlayerState>(
      listener: (context, state) {
        if (state.isPlaying) {
          _albumRotationController.forward();
          _waveController.repeat(reverse: true);
        } else {
          _albumRotationController.reverse();
          _waveController.stop();
        }
      },
      builder: (context, state) {
        // Update album art provider whenever state.albumArt changes
        if (state.albumArt != _lastAlbumArt) {
          _updateAlbumArtProvider(state.albumArt);
        }
        return Scaffold(
          backgroundColor: Colors.transparent, // Make transparent for modal
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 235, 215, 242), Color(0xFFF0EDF7)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenSize.width * 0.08,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    // Main content centered in available space
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAlbumArt(state),
                          const SizedBox(height: 40),
                          _buildTrackInfo(state),
                          const SizedBox(height: 30),
                          _buildProgressBar(state),
                          const SizedBox(height: 20),
                          _buildPlaybackControls(state),
                        ],
                      ),
                    ),
                    // Bottom actions pinned to bottom
                    _buildBottomActions(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArt(MediaPlayerState state) {
    return AnimatedBuilder(
      animation: _albumRotationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_albumRotationController.value * 0.05),
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _albumArtProvider != null
                  ? Image(image: _albumArtProvider!, fit: BoxFit.cover)
                  : const SizedBox(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArtImage(MediaPlayerState state) {
    if (state.albumArt.startsWith('data:')) {
      try {
        final base64String = state.albumArt.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (e) {
        return const SizedBox(); // Handle error
      }
    } else if (state.albumArt.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: state.albumArt,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(),
        errorWidget: (context, url, error) => const SizedBox(),
      );
    } else if (state.albumArt.isNotEmpty) {
      return Image.asset(state.albumArt, fit: BoxFit.cover);
    }
    return const SizedBox();
  }

  Widget _buildTrackInfo(MediaPlayerState state) {
    return Column(
      children: [
        Text(
          state.trackTitle,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2D2D2D),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          state.artistName,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF7B7B7B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProgressBar(MediaPlayerState state) {
    final position = state.position.inMilliseconds.toDouble();
    final duration = state.duration.inMilliseconds.toDouble();
    final progress = (duration > 0)
        ? (position / duration).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(state.position),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF7B7B7B),
              ),
            ),
            Row(
              children: [
                if (state.isBuffering)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        color: Color(0xFF7B7B7B),
                        strokeWidth: 1,
                      ),
                    ),
                  ),
                Text(
                  _formatDuration(state.duration),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7B7B7B),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 0),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6.0,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            activeTrackColor: Theme.of(context).colorScheme.primary,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Theme.of(context).colorScheme.primary,
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: progress,
            onChanged: (value) {
              if (state.duration.inMilliseconds > 0) {
                final seekPosition = Duration(
                  milliseconds: (state.duration.inMilliseconds * value).round(),
                );
                context.read<MediaPlayerBloc>().add(Seek(seekPosition));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(MediaPlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.skip_previous,
          onTap: () =>
              context.read<MediaPlayerBloc>().add(const SkipToPrevious()),
          size: 32,
        ),
        _buildMainPlayButton(state),
        _buildControlButton(
          icon: Icons.skip_next,
          onTap: () => context.read<MediaPlayerBloc>().add(const SkipToNext()),
          size: 32,
        ),
      ],
    );
  }

  Widget _buildMainPlayButton(MediaPlayerState state) {
    return SizedBox(
      width: 80,
      height: 80,
      child: FilledButton(
        onPressed: state.isLoading
            ? null
            : () {
                if (state.isPlaying) {
                  context.read<MediaPlayerBloc>().add(const Pause());
                } else {
                  context.read<MediaPlayerBloc>().add(const Play());
                }
              },
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Center(
          child: state.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
  }) {
    return SizedBox(
      width: 64,
      height: 64,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 1,
          padding: EdgeInsets.zero,
        ),
        child: Center(child: Icon(icon, size: size)),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildBottomActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBottomButton(icon: Icons.speaker, label: 'Living room'),
        _buildBottomButton(icon: Icons.queue_music, label: 'Queue'),
      ],
    );
  }

  Widget _buildBottomButton({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF7B7B7B), size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7B7B7B),
            ),
          ),
        ],
      ),
    );
  }
}

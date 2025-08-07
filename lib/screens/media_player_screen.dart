import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';

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
  bool isPlaying = false; // Start paused
  bool isMuted = false;
  double currentPosition = 0.0; // Start at beginning
  double volume = 0.7;
  late AnimationController _albumRotationController;
  late AnimationController _waveController;
  late AudioPlayer _audioPlayer;

  // Dynamic audio URL - use provided URL or default
  String get _audioUrl =>
      widget.audioUrl ?? "https://mirei-audio.netlify.app/NujabesLOFI.m4a";
  bool _isLoading = false;
  bool _isBuffering = false;

  // Playlist management
  int _currentPlaylistIndex = 0;
  bool _isDraggingSeeker = false; // Track if user is seeking

  // Current track info (updates when navigating playlist)
  late String _currentTrackTitle;
  late String _currentArtistName;
  late String _currentAlbumArt;

  // Cache for album art to prevent flickering
  String? _cachedAlbumArtData;
  Uint8List? _cachedImageBytes;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _currentPlaylistIndex =
        widget.currentIndex ?? 0; // Initialize playlist index

    // Initialize current track info
    _currentTrackTitle = widget.trackTitle;
    _currentArtistName = widget.artistName;
    _currentAlbumArt = widget.albumArt;

    _albumRotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _initializeAudio();
  }

  @override
  void dispose() {
    _albumRotationController.dispose();
    _waveController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeAudio() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Initialize audio session
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      } catch (e) {
        print("Audio session configuration failed: $e");
      }

      // Set URL and start playback immediately (don't await for full download)
      _audioPlayer
          .setUrl(_audioUrl)
          .then((_) {
            // URL is set, ready to play but don't wait for full download
            setState(() {
              _isLoading = false;
            });
            // Auto-start playback for better UX
            _audioPlayer.play();
          })
          .catchError((e) {
            print("Error loading audio: $e");
            setState(() {
              _isLoading = false;
            });
          });

      // Listen to position changes
      _audioPlayer.positionStream.listen((position) {
        final duration = _audioPlayer.duration;
        if (duration != null && duration.inMilliseconds > 0) {
          setState(() {
            currentPosition = position.inMilliseconds / duration.inMilliseconds;
          });
        }
      });

      // Listen to player state changes
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            isPlaying = state.playing;
          });

          if (isPlaying) {
            _albumRotationController.forward();
            _waveController.repeat(reverse: true);
          } else {
            _albumRotationController.reverse();
            _waveController.stop();
          }
        }
      });

      // Listen to buffering state for better UX
      _audioPlayer.processingStateStream.listen((state) {
        if (mounted) {
          setState(() {
            // Show buffering for buffering state, loading only for initial loading
            _isBuffering = state == ProcessingState.buffering;
            _isLoading =
                state == ProcessingState.loading && !_audioPlayer.playing;
          });
        }
      });
    } catch (e) {
      print("Error initializing audio: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePlayPause() async {
    HapticFeedback.mediumImpact();

    if (_audioPlayer.playing) {
      await _audioPlayer.pause();
    } else {
      // Start playing immediately, even if still loading/buffering
      try {
        await _audioPlayer.play();
      } catch (e) {
        print("Error starting playback: $e");
        // If there's an error, it might be because the URL isn't fully set yet
        // The player will start automatically once the URL is loaded
      }
    }
  }

  void _skipToPrevious() {
    HapticFeedback.lightImpact();
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      // Navigate to previous track in playlist
      if (_currentPlaylistIndex > 0) {
        _playTrackAtIndex(_currentPlaylistIndex - 1);
      }
    } else {
      // Skip backward 10 seconds if no playlist
      _audioPlayer.seek(
        Duration(
          milliseconds: (_audioPlayer.position.inMilliseconds - 10000).clamp(
            0,
            _audioPlayer.duration?.inMilliseconds ?? 0,
          ),
        ),
      );
    }
  }

  void _skipToNext() {
    HapticFeedback.lightImpact();
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      // Navigate to next track in playlist
      if (_currentPlaylistIndex < widget.playlist!.length - 1) {
        _playTrackAtIndex(_currentPlaylistIndex + 1);
      }
    } else {
      // Skip forward 10 seconds if no playlist
      final currentPos = _audioPlayer.position.inMilliseconds;
      final maxPos = _audioPlayer.duration?.inMilliseconds ?? currentPos;
      _audioPlayer.seek(
        Duration(milliseconds: (currentPos + 10000).clamp(0, maxPos)),
      );
    }
  }

  void _playTrackAtIndex(int index) async {
    if (widget.playlist == null ||
        index < 0 ||
        index >= widget.playlist!.length)
      return;

    final track = widget.playlist![index];

    setState(() {
      _currentPlaylistIndex = index;
      _isLoading = true;
      // Update current track info
      _currentTrackTitle = track['title'] ?? 'Unknown Title';
      _currentArtistName = track['artist'] ?? 'Unknown Artist';
      _currentAlbumArt = track['albumArt'] ?? widget.albumArt;

      // Clear album art cache when changing tracks
      _cachedAlbumArtData = null;
      _cachedImageBytes = null;
    });

    final audioUrl = track['url'] as String?;

    if (audioUrl != null) {
      // Set URL and start playback immediately (don't await for full download)
      _audioPlayer
          .setUrl(audioUrl)
          .then((_) {
            setState(() {
              _isLoading = false;
            });

            // Start playing immediately once URL is set
            if (isPlaying) {
              _audioPlayer.play();
            }
          })
          .catchError((e) {
            print('Error loading track: $e');
            setState(() {
              _isLoading = false;
            });
          });
    }
  }

  void _seekFromProgressBar(dynamic details, Duration duration) {
    if (duration.inMilliseconds == 0) return;

    // Get the render box of the gesture detector
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final Offset localPosition = box.globalToLocal(details.globalPosition);

    // Calculate the progress bar's actual position and width within the widget tree
    // The progress bar is inside the GestureDetector container with 24px horizontal padding
    // and the container itself has some internal layout
    final double screenWidth = MediaQuery.of(context).size.width;
    final double progressBarWidth =
        screenWidth - (24 * 2); // Account for screen padding
    final double progressBarLeft = 24; // Left padding

    // Calculate relative position within the progress bar
    final double relativePosition =
        (localPosition.dx - progressBarLeft) / progressBarWidth;
    final double clampedPosition = relativePosition.clamp(0.0, 1.0);

    // Calculate and seek to the new position
    final seekPosition = Duration(
      milliseconds: (duration.inMilliseconds * clampedPosition).round(),
    );

    _audioPlayer.seek(seekPosition);
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Add drag indicator for modal bottom sheet
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _buildAlbumArt(),
                const SizedBox(height: 40),
                _buildTrackInfo(),
                const SizedBox(height: 30),
                _buildProgressBar(),
                const SizedBox(height: 20),
                _buildPlaybackControls(),
                const SizedBox(height: 100),
                _buildBottomActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return AnimatedBuilder(
      animation: _albumRotationController,
      builder: (context, child) {
        return Transform.scale(
          scale:
              1.0 +
              (_albumRotationController.value *
                  0.05), // Scale up by 5% when playing
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1), // Reduced from 0.2
                  blurRadius: 15, // Reduced from 30
                  offset: const Offset(0, 8), // Reduced offset
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFF9A9E),
                      Color(0xFFFECFEF),
                      Color(0xFFFECFEF),
                      Color(0xFFFF9A9E),
                    ],
                  ),
                ),
                child: _buildAlbumArtImage(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArtImage() {
    if (_currentAlbumArt.isEmpty) {
      return _buildDefaultAlbumArt();
    }

    // Check if it's a base64 data URI
    if (_currentAlbumArt.startsWith('data:')) {
      // Use cached image bytes if available and album art hasn't changed
      if (_cachedAlbumArtData == _currentAlbumArt &&
          _cachedImageBytes != null) {
        return Image.memory(
          _cachedImageBytes!,
          fit: BoxFit.cover,
          key: ValueKey(_currentAlbumArt), // Stable key to prevent rebuilds
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAlbumArt();
          },
        );
      }

      try {
        final base64String = _currentAlbumArt.split(
          ',',
        )[1]; // Remove data URI prefix
        final bytes = base64Decode(base64String);

        // Cache the decoded bytes
        _cachedAlbumArtData = _currentAlbumArt;
        _cachedImageBytes = bytes;

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          key: ValueKey(_currentAlbumArt), // Stable key to prevent rebuilds
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultAlbumArt();
          },
        );
      } catch (e) {
        print('Error loading embedded album art: $e');
        return _buildDefaultAlbumArt();
      }
    }
    // Check if it's a network URL
    else if (_currentAlbumArt.startsWith('http://') ||
        _currentAlbumArt.startsWith('https://')) {
      return Image.network(
        _currentAlbumArt,
        fit: BoxFit.cover,
        key: ValueKey(_currentAlbumArt), // Stable key to prevent rebuilds
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAlbumArt();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildDefaultAlbumArt();
        },
      );
    }
    // Otherwise, treat it as an asset
    else {
      return Image.asset(
        _currentAlbumArt,
        fit: BoxFit.cover,
        key: ValueKey(_currentAlbumArt), // Stable key to prevent rebuilds
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultAlbumArt();
        },
      );
    }
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9A9E),
            Color(0xFFFECFEF),
            Color(0xFFFECFEF),
            Color(0xFFFF9A9E),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Abstract shapes similar to the image
          Positioned(
            top: 40,
            right: 60,
            child: Container(
              width: 80,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: 40,
            child: Container(
              width: 120,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF9B59B6).withOpacity(0.4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Center(
            child: Icon(
              Icons.music_note,
              size: 60,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackInfo() {
    return Column(
      children: [
        Text(
          _currentTrackTitle,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF2D2D2D),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _currentArtistName,
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

  Widget _buildProgressBar() {
    return StreamBuilder<Duration?>(
      stream: _audioPlayer.durationStream,
      builder: (context, durationSnapshot) {
        return StreamBuilder<Duration>(
          stream: _audioPlayer.positionStream,
          builder: (context, positionSnapshot) {
            final duration = durationSnapshot.data ?? Duration.zero;
            final position = positionSnapshot.data ?? Duration.zero;

            final progress = duration.inMilliseconds > 0
                ? position.inMilliseconds / duration.inMilliseconds
                : 0.0;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(position),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7B7B7B),
                      ),
                    ),
                    Row(
                      children: [
                        // Show buffering indicator in duration area when buffering
                        if (_isBuffering)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                color: const Color(0xFF7B7B7B),
                                strokeWidth: 1,
                              ),
                            ),
                          ),
                        Text(
                          _formatDuration(duration),
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
                // Interactive Material 3 Linear Progress Indicator
                GestureDetector(
                  onTapDown: (details) {
                    _seekFromProgressBar(details, duration);
                  },
                  onPanStart: (details) {
                    _isDraggingSeeker = true;
                    HapticFeedback.selectionClick();
                  },
                  onPanUpdate: (details) {
                    if (_isDraggingSeeker) {
                      _seekFromProgressBar(details, duration);
                    }
                  },
                  onPanEnd: (details) {
                    _isDraggingSeeker = false;
                  },
                  child: Container(
                    height: 44, // Larger touch target
                    child: Center(
                      child: Container(
                        height: 6,
                        child: LinearProgressIndicator(
                          value: progress, // Always show the actual progress
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlaybackControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.skip_previous,
          onTap: _skipToPrevious,
          size: 32,
        ),
        _buildMainPlayButton(),
        _buildControlButton(
          icon: Icons.skip_next,
          onTap: _skipToNext,
          size: 32,
        ),
      ],
    );
  }

  Widget _buildMainPlayButton() {
    return SizedBox(
      width: 80,
      height: 80,
      child: FilledButton(
        onPressed: _isLoading
            ? null
            : _togglePlayPause, // Only disable during loading, not buffering
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.zero, // Remove default padding
        ),
        child: Center(
          child: _isLoading
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
                    Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 36),
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
          padding: EdgeInsets.zero, // Remove default padding
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
        borderRadius: BorderRadius.circular(20)
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

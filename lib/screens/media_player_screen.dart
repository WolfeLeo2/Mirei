import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:ui';

class MediaPlayerScreen extends StatefulWidget {
  final String trackTitle;
  final String artistName;
  final String albumArt;

  const MediaPlayerScreen({
    super.key,
    required this.trackTitle,
    required this.artistName,
    required this.albumArt,
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
  
  // Your Netlify CDN audio URL
  final String _audioUrl = "https://mirei-audio.netlify.app/NujabesLOFI.m4a";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
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
      
      // Load your Netlify CDN audio
      await _audioPlayer.setUrl(_audioUrl);
      
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
      
      setState(() {
        _isLoading = false;
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
      await _audioPlayer.play();
    }
  }

  void _skipToPrevious() {
    HapticFeedback.lightImpact();
    // Skip backward 10 seconds
    _audioPlayer.seek(Duration(
      milliseconds: (_audioPlayer.position.inMilliseconds - 10000).clamp(0, _audioPlayer.duration?.inMilliseconds ?? 0)
    ));
  }

  void _skipToNext() {
    HapticFeedback.lightImpact();
    // Skip forward 10 seconds
    final currentPos = _audioPlayer.position.inMilliseconds;
    final maxPos = _audioPlayer.duration?.inMilliseconds ?? currentPos;
    _audioPlayer.seek(Duration(
      milliseconds: (currentPos + 10000).clamp(0, maxPos)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 231, 218, 239), // Light purple background
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 235, 215, 242),
              Color(0xFFF0EDF7),
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onPanUpdate: (details) {
              // Detect downward swipe
              if (details.delta.dy > 3) {
                Navigator.pop(context);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildAlbumArt(),
                  const SizedBox(height: 40),
                  _buildTrackInfo(),
                  const SizedBox(height: 30),
                  _buildProgressBar(),
                  const SizedBox(height: 40),
                  _buildPlaybackControls(),
                  const SizedBox(height: 40),
                  _buildBottomActions(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArt() {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _albumRotationController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (_albumRotationController.value * 0.05), // Scale up by 5% when playing
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
                child: widget.albumArt.isNotEmpty
                    ? Image.asset(
                        widget.albumArt,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildDefaultAlbumArt();
                        },
                      )
                    : _buildDefaultAlbumArt(),
              ),
            );
          },
        ),
      ),
    );
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
          widget.trackTitle,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D2D2D),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          widget.artistName,
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
                const SizedBox(height: 16),
                // Material 3 Linear Progress Indicator
                Container(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),
                // Interactive slider for seeking
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.transparent,
                    inactiveTrackColor: Colors.transparent,
                    thumbColor: Colors.transparent,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                    trackHeight: 20,
                  ),
                  child: Slider(
                    value: progress.clamp(0.0, 1.0),
                    onChanged: (value) {
                      final seekPosition = Duration(
                        milliseconds: (duration.inMilliseconds * value).round(),
                      );
                      _audioPlayer.seek(seekPosition);
                    },
                    onChangeEnd: (value) {
                      HapticFeedback.selectionClick();
                    },
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
        onPressed: _isLoading ? null : _togglePlayPause,
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
            : Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 36,
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
        child: Center(
          child: Icon(
            icon,
            size: size,
          ),
        ),
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
        _buildBottomButton(
          icon: Icons.speaker,
          label: 'Living room',
        ),
        _buildBottomButton(
          icon: Icons.queue_music,
          label: 'Queue',
        ),
      ],
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF7B7B7B),
            size: 18,
          ),
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

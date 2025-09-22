import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/meditation.dart';
import 'package:flutter/cupertino.dart';
import 'package:just_audio/just_audio.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final Meditation meditation;

  const MeditationPlayerScreen({super.key, required this.meditation});

  @override
  State<MeditationPlayerScreen> createState() => _MeditationPlayerScreenState();
}

class _MeditationPlayerScreenState extends State<MeditationPlayerScreen>
    with TickerProviderStateMixin {
  bool isPlaying = false;
  double currentPosition = 0.0;
  late Duration totalDuration;
  late AnimationController _waveAnimationController;
  late AnimationController _playButtonController;

  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // Parse duration from string (e.g., "10 min" -> Duration(minutes: 10))
    totalDuration = _parseDuration(widget.meditation.duration);

    _waveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await _player.setUrl(widget.meditation.audioUrl);
      _player.durationStream.listen((duration) {
        if (!mounted || duration == null) return;
        setState(() {
          totalDuration = duration;
        });
      });
      _player.positionStream.listen((pos) {
        if (!mounted) return;
        setState(() {
          currentPosition = pos.inSeconds.toDouble();
        });
      });
      _player.playerStateStream.listen((state) {
        if (!mounted) return;
        final playing =
            state.playing && state.processingState != ProcessingState.completed;
        setState(() {
          isPlaying = playing;
        });
        if (playing) {
          if (!_waveAnimationController.isAnimating) {
            _waveAnimationController.repeat();
          }
          if (_playButtonController.status != AnimationStatus.forward &&
              _playButtonController.value < 1.0) {
            _playButtonController.forward();
          }
        } else {
          if (_waveAnimationController.isAnimating) {
            _waveAnimationController.stop();
          }
          if (_playButtonController.status != AnimationStatus.reverse &&
              _playButtonController.value > 0.0) {
            _playButtonController.reverse();
          }
        }
      });
    } catch (_) {
      // Silently ignore for now; UI remains usable
    }
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _playButtonController.dispose();
    _player.dispose();
    super.dispose();
  }

  Duration _parseDuration(String durationString) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(durationString);
    if (match != null) {
      final minutes = int.parse(match.group(1)!);
      return Duration(minutes: minutes);
    }
    return const Duration(minutes: 10); // Default
  }

  Color _getTextColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  Color _getSecondaryColor(Color primaryColor) {
    final textColor = _getTextColor(primaryColor);
    return textColor == Colors.black87
        ? const Color.fromARGB(130, 0, 0, 0)
        : const Color.fromARGB(207, 255, 255, 255);
  }

  void _togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  void _skipBackward() async {
    final target = (currentPosition - 15).clamp(
      0.0,
      totalDuration.inSeconds.toDouble(),
    );
    await _player.seek(Duration(seconds: target.toInt()));
  }

  void _skipForward() async {
    final target = (currentPosition + 15).clamp(
      0.0,
      totalDuration.inSeconds.toDouble(),
    );
    await _player.seek(Duration(seconds: target.toInt()));
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textColor = _getTextColor(widget.meditation.color);
    final secondaryColor = _getSecondaryColor(widget.meditation.color);

    return Scaffold(
      backgroundColor: widget.meditation.color,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Top Bar
              SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: textColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: textColor,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    'Now Playing',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.more_horiz, color: textColor, size: 24),
                  ),
                ],
              ),

              SizedBox(height: screenHeight * 0.08),

              // Meditation Visual
              Container(
                width: screenWidth * 0.7,
                height: screenWidth * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: textColor.withValues(alpha: 0.1),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Animated waves
                    AnimatedBuilder(
                      animation: _waveAnimationController,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(screenWidth * 0.7, screenWidth * 0.7),
                          painter: WavePainter(
                            animation: _waveAnimationController,
                            color: textColor.withValues(alpha: 0.2),
                          ),
                        );
                      },
                    ),
                    // Center icon
                    SvgPicture.asset(
                      widget.meditation.imagePath,
                      width: 80,
                      height: 80,
                      colorFilter: ColorFilter.mode(
                        textColor.withValues(alpha: 0.7),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.06),

              // Title and duration
              Text(
                widget.meditation.title,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenHeight * 0.01),

              Text(
                widget.meditation.duration,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: secondaryColor,
                ),
              ),

              SizedBox(height: screenHeight * 0.06),

              // Progress bar with times (simple design)
              Column(
                children: [
                  // Time, Progress Bar, and Duration in one row
                  Row(
                    children: [
                      // Current time
                      Text(
                        _formatDuration(
                          Duration(seconds: currentPosition.toInt()),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),

                      // Progress bar (expanded)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: textColor == Colors.white
                                  ? Colors.white
                                  : Colors.black,
                              inactiveTrackColor: textColor == Colors.white
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.3),
                              thumbColor: textColor == Colors.white
                                  ? Colors.white
                                  : Colors.black,
                              overlayColor: textColor != Colors.white
                                  ? Colors.black.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.2),
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                            ),
                            child: Slider(
                              value: currentPosition.clamp(
                                0.0,
                                totalDuration.inSeconds.toDouble(),
                              ),
                              max: totalDuration.inSeconds.toDouble(),
                              onChanged: (value) async {
                                setState(() => currentPosition = value);
                                await _player.seek(
                                  Duration(seconds: value.toInt()),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Total duration
                      Text(
                        _formatDuration(totalDuration),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.02),

                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.gobackward_15,
                          color: textColor,
                        ),
                        iconSize: 28,
                        onPressed: _skipBackward,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: AnimatedIcon(
                          icon: AnimatedIcons.play_pause,
                          progress: _playButtonController,
                          color: textColor,
                          size: 44,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          CupertinoIcons.goforward_15,
                          color: textColor,
                        ),
                        iconSize: 28,
                        onPressed: _skipForward,
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  WavePainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.35;

    for (int i = 0; i < 3; i++) {
      final progress = (animation.value + i / 3) % 1.0;
      final radius = maxRadius * progress;
      paint.color = color.withValues(alpha: (1 - progress) * 0.5);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}

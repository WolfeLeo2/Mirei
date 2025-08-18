import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/meditation.dart';

class MeditationPlayerScreen extends StatefulWidget {
  final Meditation meditation;

  const MeditationPlayerScreen({
    super.key,
    required this.meditation,
  });

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
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _playButtonController.dispose();
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

  void _togglePlayPause() {
    setState(() {
      isPlaying = !isPlaying;
    });

    if (isPlaying) {
      _waveAnimationController.repeat();
      _playButtonController.forward();
    } else {
      _waveAnimationController.stop();
      _playButtonController.reverse();
    }
  }

  void _skipBackward() {
    setState(() {
      currentPosition = (currentPosition - 15).clamp(0.0, totalDuration.inSeconds.toDouble());
    });
  }

  void _skipForward() {
    setState(() {
      currentPosition = (currentPosition + 15).clamp(0.0, totalDuration.inSeconds.toDouble());
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textColor = _getTextColor(widget.meditation.color);
    final secondaryColor = _getSecondaryColor(widget.meditation.color);

    // Generate Material You color scheme from meditation color (only for buttons and progress bar)
    final colorScheme = ColorScheme.fromSeed(
      seedColor: widget.meditation.color,
      brightness: textColor == Colors.white ? Brightness.dark : Brightness.light,
    );

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
                        color: textColor.withOpacity(0.1),
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
                      color: textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.more_horiz,
                      color: textColor,
                      size: 24,
                    ),
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
                  color: textColor.withOpacity(0.1),
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
                            color: textColor.withOpacity(0.2),
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
                        textColor.withOpacity(0.7),
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

              // Progress bar with times (Material You progress bar only)
              Column(
                children: [
                  // Time, Progress Bar, and Duration in one row
                  Row(
                    children: [
                      // Current time
                      Text(
                        _formatDuration(Duration(seconds: currentPosition.toInt())),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                      
                      // Progress bar (expanded) - Material You design
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: colorScheme.primary,
                              inactiveTrackColor: colorScheme.surfaceContainer.withOpacity(0.5),
                              thumbColor: colorScheme.primary,
                              overlayColor: colorScheme.primary.withOpacity(0.2),
                              trackHeight: 6,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                                elevation: 2,
                                pressedElevation: 4,
                              ),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                            ),
                            child: Slider(
                              value: currentPosition,
                              max: totalDuration.inSeconds.toDouble(),
                              onChanged: (value) {
                                setState(() {
                                  currentPosition = value;
                                });
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
                  
                  const SizedBox(height: 32),
                  
                  // Control buttons - Material You design only
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Skip backward button
                      _Controls(
                        onPressed: _skipBackward,
                        icon: Icons.replay_10,
                        colorScheme: colorScheme,
                        isSecondary: true,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Play/Pause button (styled like in image)
                      _Controls(
                        onPressed: _togglePlayPause,
                        icon: isPlaying ? Icons.pause : Icons.play_arrow,
                        colorScheme: colorScheme,
                        isSecondary: false,
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Skip forward button
                      _Controls(
                        onPressed: _skipForward,
                        icon: Icons.forward_10,
                        colorScheme: colorScheme,
                        isSecondary: true,
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class _Controls extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final ColorScheme colorScheme;
  final bool isSecondary;

  const _Controls({
    required this.onPressed,
    required this.icon,
    required this.colorScheme,
    required this.isSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashColor: colorScheme.primary.withOpacity(0.2),
        highlightColor: colorScheme.primary.withOpacity(0.1),
        child: Container(
          width: isSecondary ? 80 : 100,
          height: isSecondary ? 60 : 70,
          decoration: BoxDecoration(
            color: isSecondary 
                ? colorScheme.surfaceContainerHighest.withOpacity(0.7)
                : colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isSecondary 
                ? colorScheme.onSurface
                : colorScheme.onPrimaryContainer,
            size: isSecondary ? 32 : 40,
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
    final radius = size.width / 2;

    // Draw multiple concentric circles with animation
    for (int i = 0; i < 3; i++) {
      final animatedRadius = (radius * 0.3) + 
          (radius * 0.4 * animation.value) + 
          (i * 20);
      
      final opacity = (1.0 - animation.value) * (1.0 - i * 0.3);
      
      canvas.drawCircle(
        center,
        animatedRadius,
        paint..color = color.withOpacity(opacity.clamp(0.0, 1.0)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 
import 'package:flutter/material.dart';
import '../models/meditation.dart';

/// Hero meditation card component for the main PageView section
/// Displays full-bleed gradient image with centered content overlay
class HeroMeditationCard extends StatefulWidget {
  final Meditation meditation;
  final VoidCallback onTap;
  final VoidCallback? onPlayPressed;
  final bool isPlaying;

  const HeroMeditationCard({
    super.key,
    required this.meditation,
    required this.onTap,
    this.onPlayPressed,
    this.isPlaying = false,
  });

  @override
  State<HeroMeditationCard> createState() => _HeroMeditationCardState();
}

class _HeroMeditationCardState extends State<HeroMeditationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _playButtonController;

  @override
  void initState() {
    super.initState();
    _playButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    if (widget.isPlaying) {
      _playButtonController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(HeroMeditationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _playButtonController.forward();
      } else {
        _playButtonController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _playButtonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category label
            if (widget.meditation.category != null)
              Text(
                widget.meditation.category!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: 8),

            // Title
            Text(
              widget.meditation.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                height: 1.2,
                letterSpacing: -1.0,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 25),

            // Play button with duration
            ElevatedButton.icon(
              onPressed: widget.onPlayPressed,
              icon: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: _playButtonController,
                size: 20,
                color: const Color.fromARGB(255, 20, 50, 81),
              ),
              label: Text(
                widget.meditation.duration,
                style: const TextStyle(
                  color: Color.fromARGB(255, 20, 50, 81),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 20, 50, 81),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

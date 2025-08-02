import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class MiniPlayer extends StatelessWidget {
  final String? currentTrack;
  final String? currentArtist;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onTap;

  const MiniPlayer({
    super.key,
    this.currentTrack,
    this.currentArtist,
    this.isPlaying = false,
    this.onPlayPause,
    this.onNext,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (currentTrack == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70, // Increased height for better visibility above nav bar
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey[200]!, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Album art placeholder
            Container(
              width: 56,
              height: 56,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 24,
              ),
            ),
            // Track info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTrack!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentArtist != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      currentArtist!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Controls
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                isPlaying ? FontAwesome.pause_solid : FontAwesome.play_solid,
                color: Colors.white,
                size: 18,
              ),
            ),
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              child: Icon(Bootstrap.skip_forward_fill, color: Colors.grey[600], size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

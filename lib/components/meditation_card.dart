import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/meditation.dart';

/// Reusable meditation card component with gradient image background
/// Used in both hero section and category sections
class MeditationCard extends StatefulWidget {
  final Meditation meditation;
  final VoidCallback onTap;
  final VoidCallback? onPlayPressed;
  final bool isPlaying;
  final bool isHeroCard;

  const MeditationCard({
    super.key,
    required this.meditation,
    required this.onTap,
    this.onPlayPressed,
    this.isPlaying = false,
    this.isHeroCard = false,
  });

  @override
  State<MeditationCard> createState() => _MeditationCardState();
}

class _MeditationCardState extends State<MeditationCard>
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
  void didUpdateWidget(MeditationCard oldWidget) {
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
    if (widget.isHeroCard) {
      return _buildHeroCard();
    } else {
      return _buildRegularCard();
    }
  }

  Widget _buildHeroCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          // Full-bleed gradient image background
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.meditation.imagePath,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  Container(color: widget.meditation.color),
              errorWidget: (context, url, error) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.meditation.gradientColors,
                  ),
                ),
              ),
            ),
          ),

          // Content overlay
          Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 40.0, 20.0, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category label
                if (widget.meditation.category != null)
                  Text(
                    widget.meditation.category!.toUpperCase(),
                    style: const TextStyle(
                      color: Color.fromARGB(255, 20, 50, 81),
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
                    color: Color.fromARGB(255, 20, 50, 81),
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
        ],
      ),
    );
  }

  Widget _buildRegularCard() {
    return GestureDetector(
      onTap: widget.onTap,
      child: RepaintBoundary(
        child: Container(
          width: 200,
          height: 150,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Gradient image background
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: widget.meditation.imagePath,
                    fit: BoxFit.cover,
                    memCacheWidth: 200,
                    memCacheHeight: 200,
                    placeholder: (context, url) =>
                        Container(color: widget.meditation.color),
                    errorWidget: (context, url, error) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: widget.meditation.gradientColors,
                        ),
                      ),
                    ),
                  ),
                ),

                // Gradient overlay at bottom
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 110,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color.fromARGB(180, 255, 255, 255),
                          Color.fromARGB(60, 255, 255, 255),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Play button
                Positioned(
                  top: 12,
                  left: 0,
                  right: 0,
                  child: Center(

                    child: GestureDetector(
                      onTap: widget.onPlayPressed,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color.fromRGBO(255, 255, 255, 0.709),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedIcon(
                            icon: AnimatedIcons.play_pause,
                            progress: _playButtonController,
                            size: 22,
                            color: const Color.fromARGB(255, 20, 50, 81),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Title and subtitle
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 32,
                  child: Column(
                    children: [
                      Text(
                        widget.meditation.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).primaryTextTheme.bodyLarge?.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: -1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A soothing atmosphere for rest',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color.fromRGBO(20, 50, 81, 0.65),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -1.0,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact meditation card - uses same implementation
class CompactMeditationCard extends StatelessWidget {
  final Meditation meditation;
  final VoidCallback onTap;
  final bool isPlaying;

  const CompactMeditationCard({
    super.key,
    required this.meditation,
    required this.onTap,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return MeditationCard(
      meditation: meditation,
      onTap: onTap,
      isPlaying: isPlaying,
      isHeroCard: false,
    );
  }
}

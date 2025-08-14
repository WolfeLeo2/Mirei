import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../bloc/media_player_state.dart';
import '../utils/media_player_modal.dart';

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _fadeAnimation;
  bool _isExpanded = false;
  
  // Color palette extraction
  Color? _dominantColor;
  Color? _accentColor;
  bool _isExtractingColors = false;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = Tween<double>(
      begin: 69.0, // Collapsed height
      end: 120.0, // Expanded height
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  // Extract color palette from album art
  Future<void> _extractColorsFromAlbumArt(String albumArtUrl) async {
    if (albumArtUrl.isEmpty || _isExtractingColors) return;
    
    setState(() {
      _isExtractingColors = true;
    });

    try {
      // Load the image
      final imageProvider = CachedNetworkImageProvider(albumArtUrl);
      final imageStream = imageProvider.resolve(const ImageConfiguration());
      
      final completer = Completer<ui.Image>();
      imageStream.addListener(ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }));
      
      final image = await completer.future;
      
      // Convert to bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;
      
      final pixels = byteData.buffer.asUint8List();
      
      // Extract colors using material_color_utilities
      final quantizerResult = await QuantizerCelebi().quantize(
        _rgbaToArgb(pixels),
        16, // Number of colors to extract
      );
      
      if (quantizerResult.colorToCount.isNotEmpty) {
        // Get the most prominent colors
        final rankedColors = Score.score(quantizerResult.colorToCount);
        
        if (rankedColors.isNotEmpty) {
          final primaryArgb = rankedColors.first;
          final scheme = SchemeTonalSpot(
            sourceColorHct: Hct.fromInt(primaryArgb),
            isDark: Theme.of(context).brightness == Brightness.dark,
            contrastLevel: 0.0,
          );
          
          setState(() {
            _dominantColor = Color(scheme.primary);
            _accentColor = Color(scheme.secondary);
          });
        }
      }
    } catch (e) {
      print('Error extracting colors from album art: $e');
      // Fallback to default colors on error
      setState(() {
        _dominantColor = const Color(0xFF2A4A3A);
        _accentColor = const Color(0xFF4ADE80);
      });
    } finally {
      setState(() {
        _isExtractingColors = false;
      });
    }
  }

  // Helper function to convert RGBA to ARGB format
  List<int> _rgbaToArgb(Uint8List pixels) {
    final List<int> result = [];
    for (int i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      final a = pixels[i + 3];
      
      // Convert RGBA to ARGB
      final argb = (a << 24) | (r << 16) | (g << 8) | b;
      result.add(argb);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MediaPlayerBloc, MediaPlayerState>(
      builder: (context, state) {
        // Only show mini player if there's a track loaded
        if (state.trackTitle.isEmpty) {
          return const SizedBox.shrink();
        }

        // Extract colors when album art changes
        if (state.albumArt.isNotEmpty && !_isExtractingColors) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _extractColorsFromAlbumArt(state.albumArt);
          });
        }

        // Use extracted colors or fallback to default
        final backgroundColor = _dominantColor ?? const Color(0xFF2A4A3A);
        final accentColor = _accentColor ?? const Color(0xFF4ADE80);

        return AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              height: _expandAnimation.value,
              decoration: BoxDecoration(
                color: backgroundColor, // Dynamic background color from album art
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25),
                  onTap: () => _expandToFullPlayer(context, state),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        // Main mini player row
                        Row(
                          children: [
                            // Album art
                            _buildAlbumArt(state),
                            const SizedBox(width: 12),
                            
                            // Track info and progress
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTrackInfo(state),
                                  const SizedBox(height: 4),
                                  _buildProgressBar(state, accentColor),
                                ],
                              ),
                            ),
                            
                            // Play/pause button
                            _buildPlayPauseButton(context, state),
                            const SizedBox(width: 8),
                            
                            // Expand/Contract FAB
                            _buildExpandFAB(accentColor),
                          ],
                        ),
                        
                        // Expanded content
                        if (_isExpanded)
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildExpandedContent(context, state),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumArt(MediaPlayerState state) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: state.albumArt.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: state.albumArt,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note, color: Colors.grey),
                ),
              )
            : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.music_note, color: Colors.grey),
              ),
      ),
    );
  }

  Widget _buildTrackInfo(MediaPlayerState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Artist name (instead of "Meditation")
        Text(
          state.artistName.isNotEmpty ? state.artistName : 'Unknown Artist',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 2),
        // Track title
        Text(
          state.trackTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar(MediaPlayerState state, Color accentColor) {
    final progress = state.duration.inMilliseconds > 0
        ? state.position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    return Container(
      height: 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1.5),
        color: Colors.white.withOpacity(0.3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1.5),
            color: accentColor, // Dynamic accent color from album art
          ),
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(BuildContext context, MediaPlayerState state) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _togglePlayPause(context, state),
          child: Icon(
            state.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandFAB(Color accentColor) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: accentColor, // Dynamic FAB color from album art
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _toggleExpansion,
          child: AnimatedBuilder(
            animation: _expandController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _expandController.value * 3.14159, // 180 degrees rotation
                child: Icon(
                  _isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                  color: Colors.white,
                  size: 20,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, MediaPlayerState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Previous button
          _buildControlButton(
            icon: Icons.skip_previous,
            onTap: () => context.read<MediaPlayerBloc>().add(const SkipToPrevious()),
          ),
          
          // Volume down
          _buildControlButton(
            icon: Icons.volume_down,
            onTap: () => _adjustVolume(context, state, -0.1),
          ),
          
          // Volume up
          _buildControlButton(
            icon: Icons.volume_up,
            onTap: () => _adjustVolume(context, state, 0.1),
          ),
          
          // Next button
          _buildControlButton(
            icon: Icons.skip_next,
            onTap: () => context.read<MediaPlayerBloc>().add(const SkipToNext()),
          ),
          
          // Full player button
          _buildControlButton(
            icon: Icons.open_in_full,
            onTap: () => _expandToFullPlayer(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }

  void _adjustVolume(BuildContext context, MediaPlayerState state, double delta) {
    final newVolume = (state.volume + delta).clamp(0.0, 1.0);
    context.read<MediaPlayerBloc>().add(SetVolume(newVolume));
  }

  void _togglePlayPause(BuildContext context, MediaPlayerState state) {
    if (state.isPlaying) {
      context.read<MediaPlayerBloc>().add(const Pause());
    } else {
      context.read<MediaPlayerBloc>().add(const Play());
    }
  }

  void _expandToFullPlayer(BuildContext context, MediaPlayerState state) {
    showMediaPlayerModal(
      context: context,
      trackTitle: state.trackTitle,
      artistName: state.artistName,
      albumArt: state.albumArt,
      playlist: state.playlist,
      currentIndex: state.currentIndex,
    );
  }
}

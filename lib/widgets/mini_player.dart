import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_color_utilities/material_color_utilities.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../bloc/media_player_bloc.dart';
import '../bloc/media_player_event.dart';
import '../bloc/media_player_state.dart';
import '../utils/media_player_modal.dart';

// Global color state for sharing between mini player and full player
class MediaPlayerColors {
  static Color? _dominantColor;
  static Color? _accentColor;
  static String? _lastAlbumArt;
  static Map<String, ImageProvider> _imageProviderCache = {};
  static Map<String, _ColorPalette> _colorCache = {};
  
  static Color get dominantColor => _dominantColor ?? const Color(0xFF2A4A3A);
  static Color get accentColor => _accentColor ?? const Color(0xFF4ADE80);
  
  static void updateColors({
    required Color? dominantColor,
    required Color? accentColor,
    required String albumArt,
  }) {
    _dominantColor = dominantColor;
    _accentColor = accentColor;
    _lastAlbumArt = albumArt;
    
    // Cache the color result
    if (albumArt.isNotEmpty && dominantColor != null && accentColor != null) {
      _colorCache[albumArt] = _ColorPalette(dominantColor, accentColor);
    }
  }
  
  static bool shouldExtractColors(String albumArt) {
    return _lastAlbumArt != albumArt;
  }
  
  static bool hasColorsInCache(String albumArt) {
    return _colorCache.containsKey(albumArt);
  }
  
  static void loadColorsFromCache(String albumArt) {
    final cached = _colorCache[albumArt];
    if (cached != null) {
      _dominantColor = cached.dominant;
      _accentColor = cached.accent;
      _lastAlbumArt = albumArt;
    }
  }
  
  static ImageProvider? getCachedImageProvider(String albumArt) {
    return _imageProviderCache[albumArt];
  }
  
  static void cacheImageProvider(String albumArt, ImageProvider provider) {
    _imageProviderCache[albumArt] = provider;
  }
  
  static void clearCache() {
    _imageProviderCache.clear();
    _colorCache.clear();
  }
}

class _ColorPalette {
  final Color dominant;
  final Color accent;
  
  _ColorPalette(this.dominant, this.accent);
}

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
  bool _isExtractingColors = false;
  String _currentAlbumArt = '';

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

  // Create the proper ImageProvider based on album art format with caching
  ImageProvider? _getAlbumArtProvider(String albumArt) {
    if (albumArt.isEmpty) return null;
    
    // Check cache first
    final cached = MediaPlayerColors.getCachedImageProvider(albumArt);
    if (cached != null) {
      return cached;
    }
    
    ImageProvider? provider;
    
    if (albumArt.startsWith('data:')) {
      try {
        final base64String = albumArt.split(',')[1];
        final bytes = base64Decode(base64String);
        provider = MemoryImage(bytes);
      } catch (e) {
        return null;
      }
    } else if (albumArt.startsWith('http')) {
      provider = CachedNetworkImageProvider(albumArt);
    } else {
      provider = AssetImage(albumArt);
    }
    
    // Cache the provider
    if (provider != null) {
      MediaPlayerColors.cacheImageProvider(albumArt, provider);
    }
    
    return provider;
  }

  // Fast color extraction with caching and optimization
  Future<void> _extractColorsFromAlbumArt(String albumArtUrl) async {
    if (albumArtUrl.isEmpty || _isExtractingColors) {
      return;
    }
    
    // Check if colors are already cached
    if (MediaPlayerColors.hasColorsInCache(albumArtUrl)) {
      MediaPlayerColors.loadColorsFromCache(albumArtUrl);
      if (mounted) setState(() {});
      return;
    }
    
    if (!MediaPlayerColors.shouldExtractColors(albumArtUrl)) {
      return;
    }
    
    setState(() {
      _isExtractingColors = true;
    });

    try {
      ui.Image? image;
      
      if (albumArtUrl.startsWith('data:')) {
        // Handle base64 data URI
        final base64String = albumArtUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 100, // Reduce image size for faster processing
          targetHeight: 100,
        );
        final frame = await codec.getNextFrame();
        image = frame.image;
      } else if (albumArtUrl.startsWith('http')) {
        // Handle network image
        final imageProvider = CachedNetworkImageProvider(albumArtUrl);
        final imageStream = imageProvider.resolve(const ImageConfiguration(
          size: const Size(100, 100), // Smaller size for faster processing
        ));
        
        final completer = Completer<ui.Image>();
        late ImageStreamListener listener;
        listener = ImageStreamListener((ImageInfo info, bool _) {
          imageStream.removeListener(listener);
          completer.complete(info.image);
        });
        imageStream.addListener(listener);
        
        image = await completer.future.timeout(
          const Duration(seconds: 2), // Add timeout to prevent hanging
          onTimeout: () => throw TimeoutException('Image loading timeout'),
        );
      } else if (albumArtUrl.isNotEmpty) {
        // Handle asset image
        final imageProvider = AssetImage(albumArtUrl);
        final imageStream = imageProvider.resolve(const ImageConfiguration(
          size: const Size(100, 100),
        ));
        
        final completer = Completer<ui.Image>();
        late ImageStreamListener listener;
        listener = ImageStreamListener((ImageInfo info, bool _) {
          imageStream.removeListener(listener);
          completer.complete(info.image);
        });
        imageStream.addListener(listener);
        
        image = await completer.future;
      }
      
      if (image == null || !mounted) return;
      
      // Convert to bytes with reduced quality for faster processing
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;
      
      final pixels = byteData.buffer.asUint8List();
      
      // Extract colors using material_color_utilities with reduced color count
      final quantizerResult = await QuantizerCelebi().quantize(
        _rgbaToArgb(pixels),
        8, // Reduced from 16 to 8 for faster processing
      );
      
      if (quantizerResult.colorToCount.isNotEmpty && mounted) {
        // Get the most prominent colors
        final rankedColors = Score.score(quantizerResult.colorToCount);
        
        if (rankedColors.isNotEmpty) {
          final primaryArgb = rankedColors.first;
          final scheme = SchemeTonalSpot(
            sourceColorHct: Hct.fromInt(primaryArgb),
            isDark: Theme.of(context).brightness == Brightness.dark,
            contrastLevel: 0.0,
          );
          
          final dominantColor = Color(scheme.primary);
          final accentColor = Color(scheme.secondary);
          
          // Update global color state
          MediaPlayerColors.updateColors(
            dominantColor: dominantColor,
            accentColor: accentColor,
            albumArt: albumArtUrl,
          );
          
          if (mounted) {
            setState(() {
              // This will trigger a rebuild with new colors
            });
          }
        }
      }
    } catch (e) {
      print('Error extracting colors from album art: $e');
      // Fallback to default colors on error
      if (mounted) {
        MediaPlayerColors.updateColors(
          dominantColor: const Color(0xFF2A4A3A),
          accentColor: const Color(0xFF4ADE80),
          albumArt: albumArtUrl,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExtractingColors = false;
        });
      }
    }
  }

  // Helper function to convert RGBA to ARGB format
  List<int> _rgbaToArgb(Uint8List pixels) {
    final List<int> result = [];
    // Process every 4th pixel for faster processing
    for (int i = 0; i < pixels.length; i += 16) { // Skip more pixels for speed
      if (i + 3 < pixels.length) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        final a = pixels[i + 3];
        
        // Convert RGBA to ARGB
        final argb = (a << 24) | (r << 16) | (g << 8) | b;
        result.add(argb);
      }
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

        // Check if album art changed and handle color extraction
        if (state.albumArt != _currentAlbumArt) {
          _currentAlbumArt = state.albumArt;
          if (state.albumArt.isNotEmpty && !_isExtractingColors) {
            // Use microtask to avoid calling setState during build
            Future.microtask(() => _extractColorsFromAlbumArt(state.albumArt));
          }
        }

        // Use extracted colors or fallback to default
        final backgroundColor = MediaPlayerColors.dominantColor;
        final accentColor = MediaPlayerColors.accentColor;

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
    final albumArtProvider = _getAlbumArtProvider(state.albumArt);
    
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: albumArtProvider != null
            ? Image(
                image: albumArtProvider,
                fit: BoxFit.cover,
                gaplessPlayback: true, // Prevent flickering during image changes
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.music_note, color: Colors.grey),
                  );
                },
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
            color: Colors.white, // Dynamic accent color from album art
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
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_up,
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

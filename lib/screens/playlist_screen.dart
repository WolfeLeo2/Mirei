import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../utils/new_media_player_modal.dart';
import '../services/audio_cache_service.dart';
import '../services/network_optimizer.dart';
import '../utils/performance_mixins.dart'; // Add performance mixins

class PlaylistScreen extends StatefulWidget {
  final String playlistTitle;
  final String playlistUrl;
  final String albumArt;
  final String? playlistDescription;

  const PlaylistScreen({
    super.key,
    required this.playlistTitle,
    required this.playlistUrl,
    required this.albumArt,
    this.playlistDescription,
  });

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen>
    with PerformanceOptimizedStateMixin {
  // Add performance mixin
  List<Map<String, dynamic>> songs = [];
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  bool isLoadingFromCache = false;
  String? error;

  // Simplified caching with existing services only
  late final AudioCacheService _cacheService;
  late final NetworkOptimizer _networkOptimizer;

  // Remove temporary cache - use persistent database cache instead

  // Static const styles for better performance
  static final TextStyle _songTitleStyle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black87,
  );

  static final TextStyle _songArtistStyle = GoogleFonts.inter(
    fontSize: 14,
    color: Colors.black87.withOpacity(0.7),
  );

  static final TextStyle _errorTextStyle = GoogleFonts.inter(fontSize: 16);

  // Const colors for better performance
  static const Color primaryColor = Colors.black87;
  static const Color backgroundColor = Color(0xFFd7dfe5);
  static const Color primaryColorLight = Color.fromRGBO(17, 94, 90, 0.7);
  static const Color primaryColorVeryLight = Color.fromRGBO(17, 94, 90, 0.2);
  static const Color primaryColorUltraLight = Color.fromRGBO(17, 94, 90, 0.1);
  static const Color primaryColorSuperLight = Color.fromRGBO(17, 94, 90, 0.05);

  @override
  void initState() {
    super.initState();

    // Initialize services
    _cacheService = AudioCacheService();
    _networkOptimizer = NetworkOptimizer();

    // Start loading asynchronously after UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize services before using them
      await _initializeServices();

      // Start loading playlist (cache-first via AudioCacheService)
      _loadPlaylist();
    });
  }

  /// Initialize all caching services
  Future<void> _initializeServices() async {
    try {
      await _cacheService.ensureInitialized();
      await _networkOptimizer.ensureInitialized();
    } catch (e) {
      // Silently handle initialization errors
    }
  }

  Future<void> _loadPlaylist() async {
    try {
      safeSetState(() {
        isLoadingMore = true;
        isLoadingFromCache = true;
        error = null;
      });

      // Extract playlist name from URL for API endpoint
      final playlistName = _getPlaylistNameFromUrl(widget.playlistUrl);
      final apiUrl =
          'https://wolfeleo2.github.io/audio-cdn/api/$playlistName.json';

      // Use persistent database caching via AudioCacheService
      final jsonData = await _cacheService.getPlaylistWithCache(apiUrl);

      if (jsonData != null) {
        safeSetState(() {
          isLoadingFromCache = false;
        });

        await _parseApiResponse(jsonData);

        // Pre-cache audio files for smooth playback
        await _preloadPlaylistAudio();
      } else {
        throw Exception('Failed to load playlist data from cache or network');
      }
    } catch (e) {
      if (mounted) {
        safeSetState(() {
          error = 'Failed to load playlist: $e';
        });
      }
    } finally {
      if (mounted) {
        safeSetState(() {
          isInitialLoading = false;
          isLoadingMore = false;
          isLoadingFromCache = false;
        });
      }
    }
  }

  // Preload audio files for smooth playback with adaptive strategy
  Future<void> _preloadPlaylistAudio({int currentIndex = 0}) async {
    if (songs.isEmpty) return;

    try {
      // Get all URLs for adaptive preloading
      final allUrls = songs.map((song) => song['url'] as String).toList();

      // Use adaptive preloading with current index
      await _cacheService.preloadPlaylistItems(
        widget.playlistUrl, // Use consistent playlistUrl as key
        allUrls,
        maxPreload: 3,
        currentIndex: currentIndex,
      );
    } catch (e) {
      // Silently handle preloading errors
    }
  }

  String _getPlaylistNameFromUrl(String url) {
    // Extract playlist name from URL
    // e.g., "https://wolfeleo2.github.io/audio-cdn/bedroompop/" -> "bedroompop"
    final uri = Uri.parse(url);
    final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return pathSegments.isNotEmpty ? pathSegments.last : 'bedroompop';
  }

  Future<void> _parseApiResponse(Map<String, dynamic> jsonData) async {
    final List<Map<String, dynamic>> parsedSongs = [];

    if (jsonData['tracks'] != null) {
      // Process tracks in batches for better perceived performance
      final tracks = jsonData['tracks'] as List;
      const batchSize = 5;

      for (int i = 0; i < tracks.length; i += batchSize) {
        final batch = tracks.skip(i).take(batchSize);

        for (var track in batch) {
          // Extract album art data from metadata
          String? albumArtData;
          bool hasEmbeddedArt = false;

          if (track['metadata'] != null &&
              track['metadata']['albumArt'] != null) {
            final albumArt = track['metadata']['albumArt'];
            if (albumArt['data'] != null &&
                albumArt['data'].toString().isNotEmpty) {
              // Convert base64 data to data URI for display
              final base64Data = albumArt['data'].toString();
              final format = albumArt['format'] ?? 'image/jpeg';
              albumArtData = 'data:$format;base64,$base64Data';
              hasEmbeddedArt = true;
            }
          }

          parsedSongs.add({
            'title':
                track['metadata']?['title'] ??
                track['title'] ??
                'Unknown Title',
            'artist':
                track['metadata']?['artist'] ??
                track['artist'] ??
                'Unknown Artist',
            'duration': track['metadata']?['duration']?.toString() ?? '0:00',
            'filename': track['filename'] ?? '',
            'url': '${widget.playlistUrl}${track['filename']}',
            'albumArt':
                albumArtData ??
                widget.albumArt, // Use embedded album art or fallback
            'hasEmbeddedArt': hasEmbeddedArt,
          });
        }

        // Update UI with each batch for progressive loading
        if (mounted) {
          setState(() {
            songs = List.from(parsedSongs);
          });
          // Allow UI to update between batches
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }
    }

    if (mounted) {
      setState(() {
        songs = parsedSongs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Loading indicator with RepaintBoundary
          if (isLoadingMore)
            RepaintBoundary(
              child: LinearProgressIndicator(
                color: primaryColor,
                backgroundColor: primaryColorVeryLight,
              ),
            ),

          // Content area with RepaintBoundary
          Expanded(
            child: RepaintBoundary(
              child: isInitialLoading && songs.isEmpty
                  ? const _LoadingWidget()
                  : error != null && songs.isEmpty
                  ? _ErrorWidget(error: error!, onRetry: _loadPlaylist)
                  : _buildSliverContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverContent() {
    return CustomScrollView(
      slivers: [
        // Playlist header as SliverAppBar
        _buildSliverAppBarHeader(),

        // Play controls section
        _buildPlayControlsSection(),

        // Songs list as sliver
        songs.isEmpty && isLoadingMore
            ? const _SliverSkeletonList()
            : _buildSliverSongsList(),
      ],
    );
  }

  Widget _buildPlayControlsSection() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Description and song count
            if (widget.playlistDescription != null) ...[
              Text(
                widget.playlistDescription!,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: primaryColor.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],

            Text(
              '${songs.length} songs',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: primaryColor.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            // Play and Shuffle buttons
            Row(
              children: [
                // Play button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: songs.isNotEmpty ? () => _playAllSongs() : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Shuffle button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: songs.isNotEmpty
                        ? () => _shuffleAllSongs()
                        : null,
                    icon: const Icon(Icons.shuffle),
                    label: const Text('Shuffle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: primaryColor,
                      side: const BorderSide(color: primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBarHeader() {
    return SliverAppBar(
      expandedHeight: 300.0,
      floating: false,
      pinned: true,
      backgroundColor: backgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: primaryColor, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.playlistTitle,
          style: GoogleFonts.inter(
            color: primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        collapseMode: CollapseMode.parallax,
        background: Container(
          color: backgroundColor,
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 60), // Space for title
                child: RepaintBoundary(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        widget.albumArt,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [primaryColor, primaryColorLight],
                              ),
                            ),
                            child: const Icon(
                              Icons.music_note,
                              size: 60,
                              color: Color.fromRGBO(255, 255, 255, 0.8),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverSongsList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final song = songs[index];
          return _SongListItem(
            song: song,
            onTap: () => _playSong(song, index),
            fallbackAlbumArt: widget.albumArt,
          );
        }, childCount: songs.length),
      ),
    );
  }

  void _playAllSongs() {
    if (songs.isNotEmpty) {
      _playSong(songs[0], 0);
    }
  }

  void _shuffleAllSongs() {
    if (songs.isNotEmpty) {
      // Create a shuffled copy of the songs list
      final shuffledSongs = List<Map<String, dynamic>>.from(songs);
      shuffledSongs.shuffle();

      // Play the first song from the shuffled list
      final firstShuffledSong = shuffledSongs[0];

      // NEW SYSTEM: Use unified modal with FULL playlist for skip functionality!
      showLocalPlayerModal(
        context,
        title: firstShuffledSong['title'] ?? 'Unknown Title',
        artist: firstShuffledSong['artist'] ?? 'Unknown Artist',
        audioUrl: firstShuffledSong['url'] ?? '',
        albumArt: firstShuffledSong['albumArt'] ?? widget.albumArt,
        playlist: shuffledSongs, // Pass the FULL shuffled playlist
        currentIndex: 0, // Start at first position
      );
    }
  }

  void _playSong(Map<String, dynamic> song, int index) {
    // NEW SYSTEM: Use unified modal with FULL playlist for skip functionality!
    showLocalPlayerModal(
      context,
      title: song['title'] ?? 'Unknown Title',
      artist: song['artist'] ?? 'Unknown Artist',
      audioUrl: song['url'] ?? '',
      albumArt: song['albumArt'] ?? widget.albumArt,
      playlist: songs, // Pass the FULL playlist
      currentIndex: index, // Pass the current song index
    );
  }
}

// Optimized const loading widget
class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: _PlaylistScreenState.primaryColor,
      ),
    );
  }
}

// Optimized error widget
class _ErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RepaintBoundary(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              error,
              style: _PlaylistScreenState._errorTextStyle.copyWith(
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// Optimized sliver skeleton list widget
class _SliverSkeletonList extends StatelessWidget {
  const _SliverSkeletonList();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return const _SkeletonListItem();
        }, childCount: 8),
      ),
    );
  }
}

// Optimized skeleton list item
class _SkeletonListItem extends StatelessWidget {
  const _SkeletonListItem();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 0,
          ),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _PlaylistScreenState.primaryColorUltraLight,
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _PlaylistScreenState.primaryColorVeryLight,
                ),
              ),
            ),
          ),
          title: Container(
            height: 16,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _PlaylistScreenState.primaryColorUltraLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Container(
            height: 12,
            width: 120,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: _PlaylistScreenState.primaryColorSuperLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          trailing: Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              color: _PlaylistScreenState.primaryColorSuperLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

// Optimized song list item widget
class _SongListItem extends StatelessWidget {
  final Map<String, dynamic> song;
  final VoidCallback onTap;
  final String fallbackAlbumArt;

  const _SongListItem({
    required this.song,
    required this.onTap,
    required this.fallbackAlbumArt,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 0,
          ),
          leading: RepaintBoundary(
            child: Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _AlbumArtWidget(
                  song: song,
                  fallbackAlbumArt: fallbackAlbumArt,
                ),
              ),
            ),
          ),
          title: Text(
            song['title'] ?? 'Unknown Title',
            style: _PlaylistScreenState._songTitleStyle,
          ),
          subtitle: Text(
            song['artist'] ?? 'Unknown Artist',
            style: _PlaylistScreenState._songArtistStyle,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

// Optimized album art widget
class _AlbumArtWidget extends StatelessWidget {
  final Map<String, dynamic> song;
  final String fallbackAlbumArt;

  const _AlbumArtWidget({required this.song, required this.fallbackAlbumArt});

  @override
  Widget build(BuildContext context) {
    final albumArtData = song['albumArt'] as String?;
    final hasEmbeddedArt = song['hasEmbeddedArt'] == true;

    if (hasEmbeddedArt &&
        albumArtData != null &&
        albumArtData.startsWith('data:')) {
      return _EmbeddedAlbumArt(albumArtData: albumArtData);
    } else if (albumArtData != null &&
        albumArtData != fallbackAlbumArt &&
        !albumArtData.startsWith('data:')) {
      return _NetworkAlbumArt(albumArtUrl: albumArtData);
    } else {
      return _AssetAlbumArt(assetPath: fallbackAlbumArt);
    }
  }
}

// Optimized embedded album art widget
class _EmbeddedAlbumArt extends StatelessWidget {
  final String albumArtData;

  const _EmbeddedAlbumArt({required this.albumArtData});

  @override
  Widget build(BuildContext context) {
    try {
      final base64String = albumArtData.split(',')[1];
      final bytes = base64Decode(base64String);

      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const _FallbackAlbumArt();
        },
      );
    } catch (e) {
      return const _FallbackAlbumArt();
    }
  }
}

// Optimized network album art widget
class _NetworkAlbumArt extends StatelessWidget {
  final String albumArtUrl;

  const _NetworkAlbumArt({required this.albumArtUrl});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      albumArtUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const _FallbackAlbumArt();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const _FallbackAlbumArt();
      },
    );
  }
}

// Optimized asset album art widget
class _AssetAlbumArt extends StatelessWidget {
  final String assetPath;

  const _AssetAlbumArt({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const _FallbackAlbumArt();
      },
    );
  }
}

// Optimized fallback album art widget
class _FallbackAlbumArt extends StatelessWidget {
  const _FallbackAlbumArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        color: _PlaylistScreenState.primaryColorVeryLight,
      ),
      child: const Icon(
        Icons.music_note,
        color: _PlaylistScreenState.primaryColor,
        size: 24,
      ),
    );
  }
}

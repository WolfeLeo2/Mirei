import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../utils/media_player_modal.dart';
import '../services/audio_cache_service.dart';
import '../services/network_optimizer.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistTitle;
  final String playlistUrl;
  final String albumArt;

  const PlaylistScreen({
    super.key,
    required this.playlistTitle,
    required this.playlistUrl,
    required this.albumArt,
  });

  @override
  _PlaylistScreenState createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  List<Map<String, dynamic>> songs = [];
  bool isInitialLoading = true;
  bool isLoadingMore = false;
  String? error;

  // Simplified caching with existing services only
  late final AudioCacheService _cacheService;
  late final NetworkOptimizer _networkOptimizer;

  // Cache for playlist data to avoid repeated fetches
  static final Map<String, List<Map<String, dynamic>>> _playlistCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Static const styles for better performance
  static final TextStyle _appBarTitleStyle = GoogleFonts.inter(
    color: const Color(0xFF115e5a),
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle _playlistTitleStyle = GoogleFonts.inter(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF115e5a),
  );

  static final TextStyle _songCountStyle = GoogleFonts.inter(
    fontSize: 16,
    color: const Color(0xFF115e5a).withValues(alpha: 0.7),
  );

  static final TextStyle _songTitleStyle = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF115e5a),
  );

  static final TextStyle _songArtistStyle = GoogleFonts.inter(
    fontSize: 14,
    color: const Color(0xFF115e5a).withValues(alpha: 0.7),
  );

  static final TextStyle _errorTextStyle = GoogleFonts.inter(fontSize: 16);

  // Const colors for better performance
  static const Color primaryColor = Color(0xFF115e5a);
  static const Color backgroundColor = Color(0xFFfaf6f1);
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
      
      setState(() {
        isInitialLoading = false; // Show UI immediately
      });
      _loadPlaylist(); // Start loading in background
    });
  }

  /// Initialize all caching services
  Future<void> _initializeServices() async {
    try {
      await _cacheService.ensureInitialized();
      await _networkOptimizer.ensureInitialized();
      print('Caching services initialized successfully');
    } catch (e) {
      print('Failed to initialize caching services: $e');
    }
  }  /// Simple playlist data caching
  List<Map<String, dynamic>>? _getCachedPlaylistData(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return null;

    // Cache expires after 30 minutes
    if (DateTime.now().difference(timestamp) > const Duration(minutes: 30)) {
      _playlistCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      return null;
    }

    return _playlistCache[cacheKey];
  }

  /// Cache playlist data
  void _cachePlaylistData(String cacheKey, List<Map<String, dynamic>> data) {
    _playlistCache[cacheKey] = List.from(data);
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  Future<void> _loadPlaylist() async {
    try {
      setState(() {
        isLoadingMore = true;
        error = null;
      });

      // Extract playlist name from URL for API endpoint
      final playlistName = _getPlaylistNameFromUrl(widget.playlistUrl);
      final apiUrl =
          'https://wolfeleo2.github.io/audio-cdn/api/$playlistName.json';

      // Check for cached playlist data first
      final cacheKey = widget.playlistUrl;
      final cachedData = _getCachedPlaylistData(cacheKey);
      if (cachedData != null) {
        print('Loading playlist from cache: ${cachedData.length} songs');
        setState(() {
          songs = cachedData;
          isInitialLoading = false;
          isLoadingMore = false;
        });

        // Pre-cache audio files for smooth playback
        await _preloadPlaylistAudio();
        return;
      }

      print('Fetching from API: $apiUrl'); // Debug log

      // Use the network optimizer for API requests
      final response = await _networkOptimizer.apiClient.get(apiUrl);

      if (response.statusCode == 200) {
        final jsonData = response.data;
        await _parseApiResponse(jsonData);

        // Cache the playlist data for future loads
        _cachePlaylistData(cacheKey, songs);

        // Pre-cache next few songs for smooth playback
        await _preloadPlaylistAudio();
      } else {
        throw Exception('API not available: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading playlist: $e'); // Debug log
      setState(() {
        error = 'Failed to load playlist: $e';
      });
    } finally {
      setState(() {
        isInitialLoading = false;
        isLoadingMore = false;
      });
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

      print('Adaptively preloaded playlist from index $currentIndex');
    } catch (e) {
      print('Failed to preload playlist audio: $e');
      // Don't show error to user for preloading failures
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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.playlistTitle, style: _appBarTitleStyle),
        centerTitle: true,
      ),
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
                  : Column(
                      children: [
                        _buildPlaylistHeader(),
                        Expanded(
                          child: songs.isEmpty && isLoadingMore
                              ? const _SkeletonListWidget()
                              : _buildSongsList(),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader() {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Playlist artwork with RepaintBoundary
            RepaintBoundary(
              child: Container(
                width: 120,
                height: 120,
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
                      return const _PlaylistFallbackArt();
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),

            // Playlist info with RepaintBoundary
            Expanded(
              child: RepaintBoundary(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.playlistTitle, style: _playlistTitleStyle),
                    const SizedBox(height: 8),
                    Text('${songs.length} songs', style: _songCountStyle),
                    const SizedBox(height: 16),

                    // Play all button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: songs.isNotEmpty
                            ? () => _playAllSongs()
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play All'),
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return _SongListItem(
          song: song,
          onTap: () => _playSong(song, index),
          fallbackAlbumArt: widget.albumArt,
        );
      },
    );
  }

  void _playAllSongs() {
    if (songs.isNotEmpty) {
      _playSong(songs[0], 0);
    }
  }

  void _playSong(Map<String, dynamic> song, int index) {
    showMediaPlayerModal(
      context: context,
      trackTitle: song['title'] ?? 'Unknown Title',
      artistName: song['artist'] ?? 'Unknown Artist',
      albumArt: song['albumArt'] ?? widget.albumArt,
      audioUrl: song['url'], // Pass the direct URL
      playlist: songs, // Pass the entire playlist
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

// Optimized skeleton list widget
class _SkeletonListWidget extends StatelessWidget {
  const _SkeletonListWidget();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 8,
      itemBuilder: (context, index) {
        return const _SkeletonListItem();
      },
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

// Optimized playlist fallback art
class _PlaylistFallbackArt extends StatelessWidget {
  const _PlaylistFallbackArt();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _PlaylistScreenState.primaryColor,
            _PlaylistScreenState.primaryColorLight,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note,
          size: 40,
          color: Color.fromRGBO(255, 255, 255, 0.8),
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

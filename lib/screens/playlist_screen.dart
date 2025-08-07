import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/media_player_modal.dart';

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
  bool isInitialLoading = true; // Only for the very first load
  bool isLoadingMore = false; // For additional data loading
  String? error;

  @override
  void initState() {
    super.initState();
    // Start loading asynchronously after UI is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        isInitialLoading = false; // Show UI immediately
      });
      _loadPlaylist(); // Start loading in background
    });
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

      print('Fetching from API: $apiUrl'); // Debug log

      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        await _parseApiResponse(jsonData);
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
      backgroundColor: const Color(0xFFfaf6f1),
      appBar: AppBar(
        backgroundColor: const Color(0xFFfaf6f1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF115e5a),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.playlistTitle,
          style: GoogleFonts.inter(
            color: const Color(0xFF115e5a),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Show loading indicator at top if still loading more content
          if (isLoadingMore)
            LinearProgressIndicator(
              color: const Color(0xFF115e5a),
              backgroundColor: const Color(0xFF115e5a).withOpacity(0.2),
            ),

          // Always show the content area, even if loading
          Expanded(
            child: isInitialLoading && songs.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF115e5a)),
                  )
                : error != null && songs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          error!,
                          style: GoogleFonts.inter(
                            color: Colors.red.shade600,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPlaylist,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _buildPlaylistHeader(),
                      Expanded(
                        child: songs.isEmpty && isLoadingMore
                            ? _buildSkeletonList() // Show skeleton while loading
                            : _buildSongsList(),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Playlist artwork
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF115e5a),
                          const Color(0xFF115e5a).withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.music_note,
                        size: 40,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Playlist info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.playlistTitle,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF115e5a),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${songs.length} songs',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFF115e5a).withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),

                // Play all button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: songs.isNotEmpty ? () => _playAllSongs() : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF115e5a),
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
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 0,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildAlbumArtWidget(song),
              ),
            ),
            title: Text(
              song['title'] ?? 'Unknown Title',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF115e5a),
              ),
            ),
            subtitle: Text(
              song['artist'] ?? 'Unknown Artist',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF115e5a).withOpacity(0.7),
              ),
            ),
            onTap: () => _playSong(song, index),
          ),
        );
      },
    );
  }

  Widget _buildAlbumArtWidget(Map<String, dynamic> song) {
    final albumArtData = song['albumArt'] as String?;
    final hasEmbeddedArt = song['hasEmbeddedArt'] == true;

    if (hasEmbeddedArt &&
        albumArtData != null &&
        albumArtData.startsWith('data:')) {
      // Display embedded album art from base64 data URI
      try {
        final base64String = albumArtData.split(
          ',',
        )[1]; // Remove data URI prefix
        final bytes = base64Decode(base64String);

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAlbumArt();
          },
        );
      } catch (e) {
        print('Error loading embedded album art: $e');
        return _buildFallbackAlbumArt();
      }
    } else if (albumArtData != null &&
        albumArtData != widget.albumArt &&
        !albumArtData.startsWith('data:')) {
      // Try to load album art from URL (if provided as external URL)
      return Image.network(
        albumArtData,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAlbumArt();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallbackAlbumArt();
        },
      );
    } else {
      // Use fallback playlist artwork
      return Image.asset(
        widget.albumArt,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackAlbumArt();
        },
      );
    }
  }

  Widget _buildFallbackAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF115e5a).withOpacity(0.2),
      ),
      child: Icon(Icons.music_note, color: const Color(0xFF115e5a), size: 24),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 8, // Show 8 skeleton items
      itemBuilder: (context, index) {
        return Container(
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
                color: const Color(0xFF115e5a).withOpacity(0.1),
              ),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF115e5a).withOpacity(0.3),
                  ),
                ),
              ),
            ),
            title: Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF115e5a).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            subtitle: Container(
              height: 12,
              width: 120,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF115e5a).withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            trailing: Container(
              width: 40,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF115e5a).withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
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

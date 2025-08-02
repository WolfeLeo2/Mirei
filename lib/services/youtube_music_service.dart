import 'package:ytmusicapi_dart/ytmusicapi_dart.dart';
import '../models/youtube_music_models.dart';

class YouTubeMusicService {
  late YTMusic _ytMusic;
  bool _isAuthenticated = false;

  YouTubeMusicService() {
    _ytMusic = YTMusic();
  }

  /// Initialize with authentication cookies/headers
  /// NOTE: Full authentication is not yet supported in ytmusicapi_dart
  /// This is a placeholder for future implementation
  void initializeWithAuth({
    Map<String, String>? cookies,
    Map<String, String>? headers,
  }) {
    // TODO: Implement when ytmusicapi_dart supports authentication
    // For now, we can only access public content
    print('Authentication not yet supported in ytmusicapi_dart');
    print('Only public search and browsing is available');
    
    if (cookies != null) {
      // Store cookies for future use when the library supports it
      print('Cookies received but not yet usable: ${cookies.keys}');
    }
    
    _isAuthenticated = false; // Set to false until proper auth is implemented
  }

  /// Check if user is authenticated
  /// Currently always returns false as auth is not implemented
  bool get isAuthenticated => _isAuthenticated;

  /// Get authentication status message
  String get authenticationStatus {
    return _isAuthenticated 
        ? 'Authenticated with YouTube Music' 
        : 'Authentication not available - using public access only';
  }

  /// Search for music with optional filters
  Future<List<YouTubeSong>> search(
    String query, {
    Filter? filter,
    int limit = 20,
  }) async {
    try {
      final results = await _ytMusic.search(
        query,
        filter: filter ?? Filter.SONGS,
        limit: limit,
      );

      return results.map((result) => YouTubeSong.fromYTMusicResult(result)).toList();
    } catch (e) {
      throw Exception('Failed to search YouTube Music: $e');
    }
  }

  /// Search specifically for songs
  Future<List<YouTubeSong>> searchSongs(String query, {int limit = 20}) async {
    return search(query, filter: Filter.SONGS, limit: limit);
  }

  /// Search specifically for albums
  Future<List<YouTubeAlbum>> searchAlbums(String query, {int limit = 20}) async {
    try {
      final results = await _ytMusic.search(
        query,
        filter: Filter.ALBUMS,
        limit: limit,
      );

      return results.map((result) => YouTubeAlbum.fromYTMusicResult(result)).toList();
    } catch (e) {
      throw Exception('Failed to search albums: $e');
    }
  }

  /// Search specifically for artists
  Future<List<YouTubeArtist>> searchArtists(String query, {int limit = 20}) async {
    try {
      final results = await _ytMusic.search(
        query,
        filter: Filter.ARTISTS,
        limit: limit,
      );

      return results.map((result) => YouTubeArtist.fromYTMusicResult(result)).toList();
    } catch (e) {
      throw Exception('Failed to search artists: $e');
    }
  }

  /// Search specifically for playlists
  Future<List<YouTubePlaylist>> searchPlaylists(String query, {int limit = 20}) async {
    try {
      final results = await _ytMusic.search(
        query,
        filter: Filter.PLAYLISTS,
        limit: limit,
      );

      return results.map((result) => YouTubePlaylist.fromYTMusicResult(result)).toList();
    } catch (e) {
      throw Exception('Failed to search playlists: $e');
    }
  }

  // Search all content types
  Future<YouTubeSearchResult> searchAll(String query, {int limit = 20}) async {
    try {
      final results = await _ytMusic.search(query, limit: limit);
      return YouTubeSearchResult.fromMixedResults(
        results: results,
        query: query,
      );
    } catch (e) {
      print('Error searching YouTube Music: $e');
      rethrow;
    }
  }

  /// Check if service is authenticated for personal library access
  bool get isAuthenticated => _isAuthenticated;

  /// Dispose resources
  void dispose() {
    // Clean up if needed
  }
}

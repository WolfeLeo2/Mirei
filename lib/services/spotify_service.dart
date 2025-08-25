import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:spotify/spotify.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:url_launcher/url_launcher.dart';

class SpotifyService {
  // Load credentials from environment variables
  static String get clientId {
    final id = dotenv.env['SPOTIFY_CLIENT_ID'];
    if (id == null || id.isEmpty || id == 'your_spotify_client_id_here') {
      throw Exception(
        'SPOTIFY_CLIENT_ID not found in .env file. Please add your Spotify Client ID to the .env file.',
      );
    }
    return id;
  }

  static String get clientSecret {
    final secret = dotenv.env['SPOTIFY_CLIENT_SECRET'];
    if (secret == null ||
        secret.isEmpty ||
        secret == 'your_spotify_client_secret_here') {
      throw Exception(
        'SPOTIFY_CLIENT_SECRET not found in .env file. Please add your Spotify Client Secret to the .env file.',
      );
    }
    return secret;
  }

  static String get redirectUrl {
    return dotenv.env['SPOTIFY_REDIRECT_URL'] ?? 'spotify-sdk://auth';
  }

  // Spotify Web API instance (works for both free and premium)
  SpotifyApi? _spotifyApi;

  // User's premium status
  bool _hasSpotifyPremium = false;
  bool _isConnectedToSdk = false;
  String? _accessToken;

  // Player state
  bool _isPlaying = false;
  String? _currentTrackName;
  String? _currentArtistName;

  // Singleton pattern
  static final SpotifyService _instance = SpotifyService._internal();
  factory SpotifyService() => _instance;
  SpotifyService._internal();

  // Getters
  bool get hasSpotifyPremium => _hasSpotifyPremium;
  bool get isConnectedToSdk => _isConnectedToSdk;
  bool get isConnectedToSpotify => _accessToken != null;
  bool get isInitialized => _accessToken != null && _spotifyApi != null;

  // Player state getters
  bool get isPlaying => _isPlaying;
  String? get currentTrackName => _currentTrackName;
  String? get currentArtistName => _currentArtistName;
  bool get hasActiveTrack => _currentTrackName != null;

  /// Get current Spotify playback info
  Future<void> updateCurrentPlayback() async {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return;

    try {
      final playerState = await SpotifySdk.getPlayerState();
      if (playerState != null) {
        _currentTrackName = playerState.track?.name;
        _currentArtistName = playerState.track?.artist?.name;
        _isPlaying = !playerState.isPaused;

        print(
          '🎵 Current Spotify track: $_currentTrackName by $_currentArtistName (Playing: $_isPlaying)',
        );
      }
    } catch (e) {
      print('❌ Failed to get current playback: $e');
    }
  }

  /// Subscribe to Spotify playback changes
  Stream<PlayerState>? subscribeToPlaybackChanges() {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return null;

    return SpotifySdk.subscribePlayerState();
  }

  /// Initialize Spotify Web API (works for all users)
  Future<bool> initialize() async {
    try {
      // Test credentials first
      final id = clientId;
      final secret = clientSecret;
      final url = redirectUrl;

      developer.log('Spotify credentials validated');
      developer.log('Client ID: ${id.substring(0, 8)}...');
      developer.log('Redirect URL: $url');

      // Initialize with client credentials (for public data)
      final credentials = SpotifyApiCredentials(id, secret);
      _spotifyApi = SpotifyApi(credentials);

      developer.log('Spotify Web API initialized successfully');
      return true;
    } catch (e) {
      developer.log('Failed to initialize Spotify Web API: $e');
      return false;
    }
  }

  /// Authenticate user and check premium status
  Future<bool> authenticateUser() async {
    try {
      print('🎵 Starting Spotify authentication...');

      // Get access token from Spotify SDK (this will show login if needed)
      _accessToken = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: redirectUrl,
        scope:
            'user-read-private,user-read-email,user-modify-playback-state,user-read-playback-state,streaming',
      );

      print('🔑 Access token received: ${_accessToken != null}');

      if (_accessToken != null) {
        print(
          '✅ Authentication successful! Token: ${_accessToken!.substring(0, 20)}...',
        );

        // Set up Web API for search functionality
        final credentials = SpotifyApiCredentials(clientId, clientSecret);
        credentials.accessToken = _accessToken;
        _spotifyApi = SpotifyApi(credentials);
        print('🌐 Web API initialized for search');

        // Try to connect SDK (this will determine if user has Premium)
        print('🔗 Attempting SDK connection...');
        await _connectToSdk();

        // Premium status is determined by successful SDK connection
        _hasSpotifyPremium = _isConnectedToSdk;

        print(
          '👑 Premium status: $_hasSpotifyPremium (based on SDK connection: $_isConnectedToSdk)',
        );
        print(
          '🎯 Final state - Premium: $_hasSpotifyPremium, SDK Connected: $_isConnectedToSdk',
        );
        return true;
      } else {
        print('❌ No access token received');
        return false;
      }
    } catch (e) {
      print('💥 Authentication failed: $e');
      return false;
    }
  }

  /// Check if user has Spotify Premium
  Future<void> _checkPremiumStatus() async {
    try {
      if (_spotifyApi == null) return;

      final user = await _spotifyApi!.me.get();
      final product = user.product?.toLowerCase();

      developer.log('User product type: "$product"');
      developer.log('User country: ${user.country}');
      developer.log('User display name: ${user.displayName}');

      // Check for premium variants
      _hasSpotifyPremium =
          product == 'premium' ||
          product == 'premium_plus' ||
          product == 'premium_family' ||
          product == 'premium_student';

      developer.log('User premium status: $_hasSpotifyPremium');
    } catch (e) {
      developer.log('Failed to check premium status: $e');
      _hasSpotifyPremium = false;
    }
  }

  /// Connect to Spotify SDK (Premium only)
  Future<bool> _connectToSdk() async {
    try {
      print('🎮 Connecting to Spotify SDK...');
      _isConnectedToSdk = await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );

      print('🔗 SDK connection result: $_isConnectedToSdk');
      return _isConnectedToSdk;
    } catch (e) {
      print('❌ Failed to connect to SDK: $e');
      _isConnectedToSdk = false;
      return false;
    }
  }

  /// Search for tracks (works for all users)
  Future<List<Track>> searchTracks(String query, {int limit = 20}) async {
    try {
      print('🔍 Searching tracks: $query');

      if (_spotifyApi == null) {
        print('❌ Web API not initialized');
        return [];
      }

      // Search with a larger limit to find tracks with previews
      final results = await _spotifyApi!.search
          .get(query, types: [SearchType.track])
          .first(50);

      List<Track> tracks = [];
      for (var page in results) {
        if (page.items != null) {
          for (var item in page.items!) {
            if (item is Track) {
              tracks.add(item);
            }
          }
        }
      }

      // Debug preview availability
      int previewCount = tracks.where((t) => t.previewUrl != null).length;
      print('🎵 Found ${tracks.length} tracks, $previewCount with previews');

      // Prioritize tracks with previews
      tracks.sort((a, b) {
        if (a.previewUrl != null && b.previewUrl == null) return -1;
        if (a.previewUrl == null && b.previewUrl != null) return 1;
        return 0;
      });

      return tracks.take(limit).toList();
    } catch (e) {
      print('❌ Search failed: $e');
      return [];
    }
  }

  /// Get meditation/wellness playlists
  Future<List<PlaylistSimple>> getMeditationPlaylists() async {
    try {
      print('📋 Loading meditation playlists...');

      if (_spotifyApi == null) {
        print('❌ Web API not initialized');
        return [];
      }

      final results = await _spotifyApi!.search
          .get(
            'meditation mindfulness wellness relaxation',
            types: [SearchType.playlist],
          )
          .first(20);

      List<PlaylistSimple> playlists = [];
      for (var page in results) {
        if (page.items != null) {
          for (var item in page.items!) {
            if (item is PlaylistSimple) {
              playlists.add(item);
            }
          }
        }
      }

      print('📋 Found ${playlists.length} meditation playlists');
      return playlists;
    } catch (e) {
      print('❌ Failed to load playlists: $e');
      return [];
    }
  }

  /// Play track - Premium users: in-app, Free users: open Spotify
  Future<bool> playTrack(Track track) async {
    if (_hasSpotifyPremium && _isConnectedToSdk) {
      // Premium: Play in app using SDK
      return await _playTrackInApp(track);
    } else {
      // Free: Open in Spotify app/web
      return await _openTrackInSpotify(track);
    }
  }

  /// Play track in app (Premium only)
  Future<bool> _playTrackInApp(Track track) async {
    try {
      if (track.uri == null) return false;

      await SpotifySdk.play(spotifyUri: track.uri!);

      // Update current track info
      _currentTrackName = track.name;
      _currentArtistName = track.artists?.map((a) => a.name).join(', ');
      _isPlaying = true;

      print('🎵 Playing in app: ${track.name} by $_currentArtistName');
      return true;
    } catch (e) {
      print('❌ Failed to play track in app: $e');
      return false;
    }
  }

  /// Open track in Spotify app/web (Free users)
  Future<bool> _openTrackInSpotify(Track track) async {
    try {
      final spotifyUrl = track.externalUrls?.spotify;
      if (spotifyUrl == null) return false;

      final uri = Uri.parse(spotifyUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        developer.log('Opened track in Spotify: ${track.name}');
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Failed to open track in Spotify: $e');
      return false;
    }
  }

  /// Open playlist in Spotify
  Future<bool> openPlaylist(PlaylistSimple playlist) async {
    try {
      final spotifyUrl = playlist.externalUrls?.spotify;
      if (spotifyUrl == null) return false;

      final uri = Uri.parse(spotifyUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        developer.log('Opened playlist in Spotify: ${playlist.name}');
        return true;
      }
      return false;
    } catch (e) {
      developer.log('Failed to open playlist in Spotify: $e');
      return false;
    }
  }

  /// Pause playback (Premium only)
  Future<bool> pause() async {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return false;

    try {
      await SpotifySdk.pause();
      _isPlaying = false;
      print('⏸️ Playback paused');
      return true;
    } catch (e) {
      print('❌ Failed to pause: $e');
      return false;
    }
  }

  /// Resume playback (Premium only)
  Future<bool> resume() async {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return false;

    try {
      await SpotifySdk.resume();
      _isPlaying = true;
      print('▶️ Playback resumed');
      return true;
    } catch (e) {
      print('❌ Failed to resume: $e');
      return false;
    }
  }

  /// Skip to next track (Premium only)
  Future<bool> skipNext() async {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return false;

    try {
      await SpotifySdk.skipNext();
      return true;
    } catch (e) {
      developer.log('Failed to skip next: $e');
      return false;
    }
  }

  /// Skip to previous track (Premium only)
  Future<bool> skipPrevious() async {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return false;

    try {
      await SpotifySdk.skipPrevious();
      return true;
    } catch (e) {
      developer.log('Failed to skip previous: $e');
      return false;
    }
  }

  /// Seek to position in current track (Premium only)
  Future<bool> seekTo(Duration position) async {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return false;

    try {
      await SpotifySdk.seekTo(positionedMilliseconds: position.inMilliseconds);
      print('🎯 Sought to position: ${position.inMilliseconds}ms');
      return true;
    } catch (e) {
      print('❌ Failed to seek: $e');
      return false;
    }
  }

  /// Get current player state (Premium only)
  Future<PlayerState?> getPlayerState() async {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return null;

    try {
      return await SpotifySdk.getPlayerState();
    } catch (e) {
      developer.log('Failed to get player state: $e');
      return null;
    }
  }

  /// Subscribe to player state changes (Premium only)
  Stream<PlayerState>? subscribeToPlayerState() {
    if (!_hasSpotifyPremium || !_isConnectedToSdk) return null;

    return SpotifySdk.subscribePlayerState();
  }

  /// Disconnect from Spotify
  Future<void> disconnect() async {
    try {
      if (_isConnectedToSdk) {
        await SpotifySdk.disconnect();
        _isConnectedToSdk = false;
      }
      _accessToken = null;
      _hasSpotifyPremium = false; // Reset premium status
      developer.log('Disconnected from Spotify');
    } catch (e) {
      developer.log('Failed to disconnect: $e');
    }
  }

  /// Force re-check premium status (for debugging)
  Future<void> recheckPremiumStatus() async {
    if (_accessToken != null && _spotifyApi != null) {
      developer.log('Force rechecking premium status...');
      await _checkPremiumStatus();

      // Try SDK connection if premium
      if (_hasSpotifyPremium && !_isConnectedToSdk) {
        await _connectToSdk();
      }
    }
  }

  /// Get track preview URL (30 second snippet - works for all users)
  String? getPreviewUrl(Track track) {
    return track.previewUrl;
  }

  /// Test method to find tracks with previews
  Future<List<Track>> getTracksWithPreviews() async {
    try {
      // Search for popular tracks that typically have previews
      final queries = [
        'shape of you ed sheeran',
        'billie eilish bad guy',
        'dua lipa levitating',
        'the weeknd blinding lights',
      ];
      List<Track> allTracks = [];

      for (String query in queries) {
        final tracks = await searchTracks(query, limit: 5);
        allTracks.addAll(tracks);
      }

      // Filter only tracks with previews
      final tracksWithPreviews = allTracks
          .where((t) => t.previewUrl != null)
          .toList();
      developer.log(
        'Found ${tracksWithPreviews.length} tracks with previews out of ${allTracks.length} total',
      );

      return tracksWithPreviews;
    } catch (e) {
      developer.log('Failed to get tracks with previews: $e');
      return [];
    }
  }

  /// Convert Spotify image URI to HTTP URL (for basic image URI support)
  static String? convertSpotifyImageUri(String? spotifyImageUri) {
    if (spotifyImageUri == null ||
        !spotifyImageUri.startsWith('spotify:image:')) {
      return spotifyImageUri;
    }

    // For now, return null as we need the actual Spotify SDK getImage method
    // to properly convert image URIs to actual image data
    return null;
  }
}

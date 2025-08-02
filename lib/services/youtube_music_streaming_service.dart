import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

import 'innertube/innertube_service.dart';
import 'innertube/models/innertube_models.dart';
import '../models/youtube_music_models.dart';

/// Service for handling YouTube Music streaming with InnerTube API
class YouTubeMusicStreamingService {
  final InnerTubeService _innerTubeService;
  final AudioPlayer _audioPlayer;
  bool _isInitialized = false;

  YouTubeMusicStreamingService({InnerTubeService? innerTubeService})
      : _innerTubeService = innerTubeService ?? InnerTubeService(),
        _audioPlayer = AudioPlayer();

  /// Initialize the streaming service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _innerTubeService.initialize();
      _isInitialized = true;
      print('[YouTubeMusicStreaming] Service initialized successfully');
    } catch (e) {
      print('[YouTubeMusicStreaming] Failed to initialize: $e');
      throw Exception('Failed to initialize streaming service: $e');
    }
  }

  /// Test method to check service functionality with a known public video
  Future<bool> testConnection() async {
    try {
      await initialize();
      
      // Test with multiple known public videos (rickroll and others are often geo-blocked)
      final testVideos = [
        'dQw4w9WgXcQ', // Rick Roll (classic test)
        'kJQP7kiw5Fk', // Despacito (very popular)
        'JGwWNGJdvx8', // Shape of You
        'pRpeEdMmmQ0', // Shake It Off
        'YQHsXMglC9A', // Hello - Adele
      ];
      
      for (final videoId in testVideos) {
        print('[YouTubeMusicStreaming] Testing connection with video: $videoId');
        
        final streamingData = await _innerTubeService.getStreamingData(videoId);
        if (streamingData != null && streamingData.adaptiveFormats.isNotEmpty) {
          print('[YouTubeMusicStreaming] Connection test successful with $videoId!');
          print('[YouTubeMusicStreaming] Available formats: ${streamingData.adaptiveFormats.length}');
          
          // Test audio format quality
          final audioFormats = streamingData.adaptiveFormats.where((f) => f.isAudioOnly).toList();
          print('[YouTubeMusicStreaming] Audio formats: ${audioFormats.length}');
          
          if (audioFormats.isNotEmpty) {
            final bestAudio = audioFormats.first;
            print('[YouTubeMusicStreaming] Best audio format: ${bestAudio.mimeType}, ${bestAudio.audioQuality}');
            return true;
          }
        }
        
        print('[YouTubeMusicStreaming] Video $videoId failed, trying next...');
        await Future.delayed(const Duration(milliseconds: 1000)); // Delay between tests
      }
      
      print('[YouTubeMusicStreaming] All test videos failed');
      return false;
    } catch (e) {
      print('[YouTubeMusicStreaming] Connection test failed: $e');
      return false;
    }
  }

  /// Test Piped instances accessibility
  Future<Map<String, bool>> testPipedInstances() async {
    try {
      await initialize();
      return await _innerTubeService.testPipedInstances();
    } catch (e) {
      print('[YouTubeMusicStreaming] Failed to test instances: $e');
      return {};
    }
  }

  /// Play a YouTube song by video ID
  Future<bool> playSong(String videoId, {String? title}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('[YouTubeMusicStreaming] Getting streaming data for: $videoId');
      
      // Get streaming data from InnerTube
      final streamingData = await _innerTubeService.getStreamingData(videoId);
      if (streamingData == null) {
        print('[YouTubeMusicStreaming] No streaming data available for: $videoId');
        print('[YouTubeMusicStreaming] This could be due to:');
        print('[YouTubeMusicStreaming] - Video is geo-blocked or unavailable');
        print('[YouTubeMusicStreaming] - All API endpoints are down');
        print('[YouTubeMusicStreaming] - Video requires authentication');
        return false;
      }

      // Get the best audio format
      final audioFormat = streamingData.bestAudioFormat;
      if (audioFormat == null || audioFormat.url?.isEmpty != false) {
        print('[YouTubeMusicStreaming] No audio URL available for: $videoId');
        return false;
      }

      print('[YouTubeMusicStreaming] Found audio URL: ${audioFormat.url!.substring(0, 50)}...');
      print('[YouTubeMusicStreaming] Audio quality: ${audioFormat.audioQuality ?? 'unknown'}');
      print('[YouTubeMusicStreaming] Audio codec: ${audioFormat.mimeType}');

      // Set up audio source with headers
      final audioSource = AudioSource.uri(
        Uri.parse(audioFormat.url!),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': 'https://music.youtube.com/',
          'Origin': 'https://music.youtube.com',
        },
      );

      // Load and play the audio
      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.play();

      print('[YouTubeMusicStreaming] Successfully started playback for: $videoId');
      return true;

    } catch (e) {
      print('[YouTubeMusicStreaming] Failed to play song $videoId: $e');
      return false;
    }
  }

  /// Play a YouTube song object
  Future<bool> playYouTubeSong(YouTubeSong song) async {
    return await playSong(song.videoId, title: song.title);
  }

  /// Search for songs and return results
  Future<List<YouTubeSong>> searchSongs(String query) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final searchResult = await _innerTubeService.search(query);
      return searchResult.songs;
    } catch (e) {
      print('[YouTubeMusicStreaming] Search failed: $e');
      return [];
    }
  }

  /// Search for all content types
  Future<Map<String, List<dynamic>>> searchAll(String query) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final searchResult = await _innerTubeService.search(query);
      return {
        'songs': searchResult.songs,
        'artists': searchResult.artists,
        'albums': searchResult.albums,
        'playlists': searchResult.playlists,
      };
    } catch (e) {
      print('[YouTubeMusicStreaming] Search failed: $e');
      return {
        'songs': <YouTubeSong>[],
        'artists': <YouTubeArtist>[],
        'albums': <YouTubeAlbum>[],
        'playlists': <YouTubePlaylist>[],
      };
    }
  }

  /// Get streaming URL for a video ID (for external use)
  Future<String?> getStreamingUrl(String videoId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final streamingData = await _innerTubeService.getStreamingData(videoId);
      return streamingData?.bestAudioFormat?.url;
    } catch (e) {
      print('[YouTubeMusicStreaming] Failed to get streaming URL: $e');
      return null;
    }
  }

  /// Get detailed streaming information
  Future<StreamingInfo?> getStreamingInfo(String videoId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final streamingData = await _innerTubeService.getStreamingData(videoId);
      if (streamingData == null) return null;

      final bestAudio = streamingData.bestAudioFormat;
      final bestVideo = streamingData.bestVideoFormat;

      return StreamingInfo(
        videoId: videoId,
        audioUrl: bestAudio?.url,
        videoUrl: bestVideo?.url,
        audioQuality: bestAudio?.audioQuality,
        videoQuality: bestVideo?.qualityLabel,
        audioCodec: bestAudio?.mimeType,
        videoCodec: bestVideo?.mimeType,
        audioBitrate: bestAudio?.bitrate,
        videoBitrate: bestVideo?.bitrate,
        duration: streamingData.adaptiveFormats.isNotEmpty 
            ? Duration(milliseconds: int.tryParse(streamingData.adaptiveFormats.first.approxDurationMs ?? '0') ?? 0)
            : null,
        availableQualities: streamingData.adaptiveFormats
            .where((f) => f.isAudioOnly)
            .map((f) => f.audioQuality ?? 'unknown')
            .toSet()
            .cast<String>()
            .toList(),
      );
    } catch (e) {
      print('[YouTubeMusicStreaming] Failed to get streaming info: $e');
      return null;
    }
  }

  /// Get suggested/recommended songs
  Future<List<YouTubeSong>> getSuggestions() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _innerTubeService.getSuggestions();
    } catch (e) {
      print('[YouTubeMusicStreaming] Failed to get suggestions: $e');
      return [];
    }
  }

  /// Get album details
  Future<YouTubeAlbum?> getAlbum(String albumId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _innerTubeService.getAlbum(albumId);
    } catch (e) {
      print('[YouTubeMusicStreaming] Failed to get album: $e');
      return null;
    }
  }

  /// Get playlist details
  Future<YouTubePlaylist?> getPlaylist(String playlistId) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      return await _innerTubeService.getPlaylist(playlistId);
    } catch (e) {
      print('[YouTubeMusicStreaming] Failed to get playlist: $e');
      return null;
    }
  }

  /// Audio player controls
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    await _audioPlayer.play();
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  /// Audio player state streams
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<double> get volumeStream => _audioPlayer.volumeStream;

  /// Audio player properties
  PlayerState get playerState => _audioPlayer.playerState;
  Duration get position => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;
  bool get playing => _audioPlayer.playing;
  double get volume => _audioPlayer.volume;

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Check if service has network connection
  Future<bool> hasConnection() async {
    return await _innerTubeService.hasConnection();
  }

  /// Clear caches
  void clearCache() {
    _innerTubeService.clearCache();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
    _innerTubeService.dispose();
    _isInitialized = false;
  }
}

/// Detailed streaming information for a video
class StreamingInfo {
  final String videoId;
  final String? audioUrl;
  final String? videoUrl;
  final String? audioQuality;
  final String? videoQuality;
  final String? audioCodec;
  final String? videoCodec;
  final int? audioBitrate;
  final int? videoBitrate;
  final Duration? duration;
  final List<String> availableQualities;

  StreamingInfo({
    required this.videoId,
    this.audioUrl,
    this.videoUrl,
    this.audioQuality,
    this.videoQuality,
    this.audioCodec,
    this.videoCodec,
    this.audioBitrate,
    this.videoBitrate,
    this.duration,
    this.availableQualities = const [],
  });

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'audioUrl': audioUrl,
    'videoUrl': videoUrl,
    'audioQuality': audioQuality,
    'videoQuality': videoQuality,
    'audioCodec': audioCodec,
    'videoCodec': videoCodec,
    'audioBitrate': audioBitrate,
    'videoBitrate': videoBitrate,
    'durationMs': duration?.inMilliseconds,
    'availableQualities': availableQualities,
  };

  @override
  String toString() {
    return 'StreamingInfo(videoId: $videoId, audioQuality: $audioQuality, audioCodec: $audioCodec, duration: $duration)';
  }
}

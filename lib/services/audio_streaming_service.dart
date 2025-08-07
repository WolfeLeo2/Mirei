import 'dart:async';
import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'audio_cache_service.dart';
import 'enhanced_http_service.dart';

class AudioStreamingService {
  static final AudioStreamingService _instance = AudioStreamingService._internal();
  factory AudioStreamingService() => _instance;
  AudioStreamingService._internal();

  late AudioCacheService _cacheService;
  late EnhancedHttpService _httpService;
  late AudioPlayer _audioPlayer;

  // Stream controllers for real-time updates
  final StreamController<AudioStreamingState> _stateController = 
      StreamController<AudioStreamingState>.broadcast();
  final StreamController<PlaybackProgress> _progressController = 
      StreamController<PlaybackProgress>.broadcast();
  final StreamController<CacheStatus> _cacheStatusController = 
      StreamController<CacheStatus>.broadcast();

  // Current playback state
  String? _currentTrackId;
  String? _currentPlaylistId;
  int _currentTrackIndex = 0;
  List<String> _currentPlaylist = [];
  bool _isInitialized = false;
  
  // Predictive caching state
  Timer? _predictiveCacheTimer;
  final Set<String> _cachingInProgress = {};

  // Public streams
  Stream<AudioStreamingState> get stateStream => _stateController.stream;
  Stream<PlaybackProgress> get progressStream => _progressController.stream;
  Stream<CacheStatus> get cacheStatusStream => _cacheStatusController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _cacheService = AudioCacheService();
    _httpService = EnhancedHttpService();
    _audioPlayer = AudioPlayer();

    await _httpService.initialize();
    await _cacheService.initialize();

    // Set up audio player event listeners
    _setupAudioPlayerListeners();

    _isInitialized = true;
    _emitState(AudioStreamingState.initialized);
  }

  void _setupAudioPlayerListeners() {
    // Position updates for progress tracking
    _audioPlayer.positionStream.listen((position) {
      _progressController.add(PlaybackProgress(
        position: position,
        duration: _audioPlayer.duration ?? Duration.zero,
        bufferedPosition: _audioPlayer.bufferedPosition,
      ));
    });

    // Player state changes
    _audioPlayer.playerStateStream.listen((state) {
      switch (state.processingState) {
        case ProcessingState.idle:
          _emitState(AudioStreamingState.idle);
          break;
        case ProcessingState.loading:
          _emitState(AudioStreamingState.loading);
          break;
        case ProcessingState.buffering:
          _emitState(AudioStreamingState.buffering);
          break;
        case ProcessingState.ready:
          if (state.playing) {
            _emitState(AudioStreamingState.playing);
          } else {
            _emitState(AudioStreamingState.paused);
          }
          break;
        case ProcessingState.completed:
          _emitState(AudioStreamingState.completed);
          _handleTrackCompletion();
          break;
      }
    });

    // Buffer progress for cache optimization
    _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      _optimizeBufferManagement(bufferedPosition);
    });
  }

  // Main playback methods

  Future<void> playTrack(String trackId, {
    String? playlistId,
    List<String>? playlist,
    int trackIndex = 0,
  }) async {
    await initialize();

    _currentTrackId = trackId;
    _currentPlaylistId = playlistId;
    _currentPlaylist = playlist ?? [trackId];
    _currentTrackIndex = trackIndex;

    try {
      _emitState(AudioStreamingState.loading);

      // Get audio source (cached or stream)
      final audioSource = await _getAudioSource(trackId);
      
      // Set the audio source
      await _audioPlayer.setAudioSource(audioSource);
      
      // Start playback
      await _audioPlayer.play();

      // Start predictive caching for next tracks
      _startPredictiveCaching();

      // Update playback history
      await _updatePlaybackHistory(trackId);

    } catch (e) {
      _emitState(AudioStreamingState.error);
      print('Error playing track $trackId: $e');
      rethrow;
    }
  }

  Future<AudioSource> _getAudioSource(String trackId) async {
    // Try to get from cache first using the URL
    final trackData = await _getTrackMetadata(trackId);
    final streamingUrl = trackData['streamingUrl'] as String;
    
    final cachedFile = await _cacheService.getAudioFile(streamingUrl);
    
    if (cachedFile != null) {
      // Use cached file
      return AudioSource.file(cachedFile.path);
    } else {
      // Create progressive download source
      return ProgressiveAudioSource(
        Uri.parse(streamingUrl),
        tag: AudioMetadata(
          trackId: trackId,
          title: trackData['title'] as String?,
          artist: trackData['artist'] as String?,
          duration: trackData['duration'] != null 
              ? Duration(seconds: trackData['duration'] as int)
              : null,
        ),
        cacheService: _cacheService,
      );
    }
  }

  Future<Map<String, dynamic>> _getTrackMetadata(String trackId) async {
    // This would typically fetch from your music service API
    // For now, return dummy data
    return {
      'streamingUrl': 'https://example.com/track/$trackId.mp3',
      'title': 'Track $trackId',
      'artist': 'Unknown Artist',
      'duration': 180, // 3 minutes
    };
  }

  // Predictive caching implementation
  void _startPredictiveCaching() {
    _predictiveCacheTimer?.cancel();
    
    _predictiveCacheTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _performPredictiveCaching();
    });
  }

  Future<void> _performPredictiveCaching() async {
    if (_currentPlaylist.isEmpty) return;

    final nextTracks = _getNextTracksForCaching();
    
    for (final trackId in nextTracks) {
      if (!_cachingInProgress.contains(trackId)) {
        _cachingInProgress.add(trackId);
        _cacheTrackInBackground(trackId);
      }
    }
  }

  List<String> _getNextTracksForCaching() {
    final tracks = <String>[];
    
    // Get next 2-3 tracks in playlist
    for (int i = 1; i <= 3; i++) {
      final nextIndex = _currentTrackIndex + i;
      if (nextIndex < _currentPlaylist.length) {
        tracks.add(_currentPlaylist[nextIndex]);
      }
    }
    
    return tracks;
  }

  Future<void> _cacheTrackInBackground(String trackId) async {
    try {
      final trackData = await _getTrackMetadata(trackId);
      final streamingUrl = trackData['streamingUrl'] as String;
      
      // Use the existing getAudioFile method which handles caching
      await _cacheService.getAudioFile(
        streamingUrl,
        onProgress: (progress) {
          _cacheStatusController.add(CacheStatus(
            trackId: trackId,
            progress: progress,
            status: CacheStatusType.downloading,
          ));
        },
      );

      _cacheStatusController.add(CacheStatus(
        trackId: trackId,
        progress: 1.0,
        status: CacheStatusType.completed,
      ));
      
    } catch (e) {
      _cacheStatusController.add(CacheStatus(
        trackId: trackId,
        progress: 0.0,
        status: CacheStatusType.failed,
      ));
      print('Failed to cache track $trackId: $e');
    } finally {
      _cachingInProgress.remove(trackId);
    }
  }

  // Playback control methods
  Future<void> play() async => await _audioPlayer.play();
  Future<void> pause() async => await _audioPlayer.pause();
  Future<void> stop() async => await _audioPlayer.stop();
  
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed.clamp(0.5, 2.0));
  }

  // Playlist navigation
  Future<void> skipToNext() async {
    if (_currentTrackIndex < _currentPlaylist.length - 1) {
      _currentTrackIndex++;
      final nextTrackId = _currentPlaylist[_currentTrackIndex];
      await playTrack(
        nextTrackId,
        playlistId: _currentPlaylistId,
        playlist: _currentPlaylist,
        trackIndex: _currentTrackIndex,
      );
    }
  }

  Future<void> skipToPrevious() async {
    if (_currentTrackIndex > 0) {
      _currentTrackIndex--;
      final prevTrackId = _currentPlaylist[_currentTrackIndex];
      await playTrack(
        prevTrackId,
        playlistId: _currentPlaylistId,
        playlist: _currentPlaylist,
        trackIndex: _currentTrackIndex,
      );
    }
  }

  // Buffer management
  void _optimizeBufferManagement(Duration bufferedPosition) {
    final currentPosition = _audioPlayer.position;
    final bufferAhead = bufferedPosition - currentPosition;
    
    // If we have enough buffer ahead, we can optimize caching for other tracks
    if (bufferAhead > const Duration(seconds: 30)) {
      _performPredictiveCaching();
    }
  }

  void _handleTrackCompletion() {
    // Auto-advance to next track
    skipToNext();
  }

  // History and analytics
  Future<void> _updatePlaybackHistory(String trackId) async {
    try {
      // This would typically update listening history in your database
      print('Updated playback history for track: $trackId');
    } catch (e) {
      print('Failed to update playback history: $e');
    }
  }

  // Cache management
  Future<void> clearCache() async {
    await _cacheService.clearCache();
    _cacheStatusController.add(CacheStatus(
      trackId: '',
      progress: 0.0,
      status: CacheStatusType.cleared,
    ));
  }

  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheService.getCacheStats();
  }

  // State management
  void _emitState(AudioStreamingState state) {
    _stateController.add(state);
  }

  // Getters for current state
  String? get currentTrackId => _currentTrackId;
  String? get currentPlaylistId => _currentPlaylistId;
  int get currentTrackIndex => _currentTrackIndex;
  List<String> get currentPlaylist => List.unmodifiable(_currentPlaylist);
  bool get isPlaying => _audioPlayer.playing;
  Duration get currentPosition => _audioPlayer.position;
  Duration? get duration => _audioPlayer.duration;

  // Cleanup
  Future<void> dispose() async {
    _predictiveCacheTimer?.cancel();
    _stateController.close();
    _progressController.close();
    _cacheStatusController.close();
    await _audioPlayer.dispose();
    await _httpService.dispose();
    _isInitialized = false;
  }
}

// Custom audio source for progressive downloading
class ProgressiveAudioSource extends StreamAudioSource {
  final Uri uri;
  @override
  final AudioMetadata? tag;
  final AudioCacheService cacheService;

  ProgressiveAudioSource(
    this.uri, {
    this.tag,
    required this.cacheService,
  }) : super(tag: tag);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final trackId = tag?.trackId;
    
    if (trackId != null) {
      // Try to serve from cache if available
      final cachedStream = await cacheService.getAudioStream(
        uri.toString(),
        startByte: start,
        endByte: end,
      );
      if (cachedStream != null) {
        return StreamAudioResponse(
          sourceLength: null, // Will be determined from stream
          contentLength: end != null ? end - (start ?? 0) + 1 : null,
          offset: start ?? 0,
          stream: cachedStream,
          contentType: 'audio/mpeg',
        );
      }
    }

    // Fallback to direct streaming
    final httpService = EnhancedHttpService();
    final response = await httpService.getAudioContent(
      uri.toString(),
      startByte: start,
      endByte: end,
    );

    final data = response.data as Uint8List;
    return StreamAudioResponse(
      sourceLength: response.headers.value('content-length') != null
          ? int.parse(response.headers.value('content-length')!)
          : null,
      contentLength: data.length,
      offset: start ?? 0,
      stream: Stream.value(data),
      contentType: response.headers.value('content-type') ?? 'audio/mpeg',
    );
  }
}

// Data classes for state management
enum AudioStreamingState {
  idle,
  initialized,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

class PlaybackProgress {
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;

  PlaybackProgress({
    required this.position,
    required this.duration,
    required this.bufferedPosition,
  });

  double get progressPercent => duration.inMilliseconds > 0
      ? position.inMilliseconds / duration.inMilliseconds
      : 0.0;

  double get bufferedPercent => duration.inMilliseconds > 0
      ? bufferedPosition.inMilliseconds / duration.inMilliseconds
      : 0.0;
}

class CacheStatus {
  final String trackId;
  final double progress;
  final CacheStatusType status;

  CacheStatus({
    required this.trackId,
    required this.progress,
    required this.status,
  });
}

enum CacheStatusType {
  downloading,
  completed,
  failed,
  cleared,
}

class AudioMetadata {
  final String trackId;
  final String? title;
  final String? artist;
  final Duration? duration;

  AudioMetadata({
    required this.trackId,
    this.title,
    this.artist,
    this.duration,
  });
}

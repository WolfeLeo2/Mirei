import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'audio_cache_service.dart';

/// Production-ready background audio service with caching and media controls
class BackgroundAudioService extends BaseAudioHandler with SeekHandler {
  static BackgroundAudioService? _instance;
  static BackgroundAudioService get instance =>
      _instance ??= BackgroundAudioService._();

  BackgroundAudioService._();

  // Core services
  late final AudioPlayer _audioPlayer;
  AudioCacheService? _cacheService; // nullable, initialize once

  // Initialization state
  bool _initialized = false;
  Future<void>? _initFuture;
  bool _playerCreated = false;
  bool _listenersAttached = false;
  bool _audioServiceInited = false;

  // Playback state
  final _playbackState = PlaybackState(
    controls: [
      MediaControl.skipToPrevious,
      MediaControl.play,
      MediaControl.pause,
      MediaControl.stop,
      MediaControl.skipToNext,
    ],
    systemActions: const {
      MediaAction.seek,
      MediaAction.seekForward,
      MediaAction.seekBackward,
    },
    androidCompactActionIndices: const [0, 1, 4],
    processingState: AudioProcessingState.idle,
    playing: false,
  );

  // Playlist management
  List<MediaItem> _playlist = [];
  int _currentIndex = 0;
  bool _shuffleEnabled = false;
  AudioServiceRepeatMode _repeatMode = AudioServiceRepeatMode.none;

  // Stream subscriptions
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _playbackEventSubscription;
  late final StreamSubscription _playerStateSubscription;

  // Cache and preloading
  final Set<String> _preloadingUrls = {};
  Timer? _preloadTimer;

  /// Initialize the background audio service
  Future<void> initialize() async {
    if (_initialized) return;
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    _initFuture = _doInitialize();
    try {
      await _initFuture;
    } finally {
      _initFuture = null;
    }
  }

  Future<void> _doInitialize() async {
    try {
      if (!_playerCreated) {
        _audioPlayer = AudioPlayer(
          audioPipeline: AudioPipeline(
            androidAudioEffects: [AndroidLoudnessEnhancer()],
          ),
        );
        _playerCreated = true;
      }

      // Initialize cache service once
      _cacheService ??= AudioCacheService();
      await _cacheService!.ensureInitialized();

      if (!_audioServiceInited) {
        await AudioService.init(
          builder: () => this,
          config: const AudioServiceConfig(
            androidNotificationChannelId: 'com.mirei.audio',
            androidNotificationChannelName: 'Mirei Audio',
            androidNotificationChannelDescription:
                'Background audio playback for Mirei wellness app',
            androidNotificationOngoing: true,
            androidShowNotificationBadge: true,
            androidStopForegroundOnPause: true,
            artDownscaleWidth: 200,
            artDownscaleHeight: 200,
            fastForwardInterval: Duration(seconds: 10),
            rewindInterval: Duration(seconds: 10),
          ),
        );
        _audioServiceInited = true;
      }

      if (!_listenersAttached) {
        _setupAudioPlayerListeners();
        _listenersAttached = true;
      }

      _initialized = true;
      debugPrint('Background audio service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing background audio service: $e');
      rethrow;
    }
  }

  void _setupAudioPlayerListeners() {
    // Position updates
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      playbackState.add(
        _playbackState.copyWith(
          updatePosition: position,
          bufferedPosition: _audioPlayer.bufferedPosition,
        ),
      );
    });

    // Playback events
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen((
      event,
    ) {
      final playing = _audioPlayer.playing;
      playbackState.add(
        _playbackState.copyWith(
          controls: playing
              ? [
                  MediaControl.skipToPrevious,
                  MediaControl.pause,
                  MediaControl.stop,
                  MediaControl.skipToNext,
                ]
              : [
                  MediaControl.skipToPrevious,
                  MediaControl.play,
                  MediaControl.stop,
                  MediaControl.skipToNext,
                ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: _mapProcessingState(event.processingState),
          playing: playing,
          updatePosition: event.updatePosition,
          bufferedPosition: event.bufferedPosition,
          speed: _audioPlayer.speed,
          queueIndex: _currentIndex,
        ),
      );
    });

    // Player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((
      playerState,
    ) {
      // Handle track completion
      if (playerState.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });
  }

  /// Load and play a playlist
  Future<void> loadPlaylist(
    List<Map<String, dynamic>> playlist, {
    int startIndex = 0,
  }) async {
    try {
      _playlist = playlist
          .map(
            (track) => MediaItem(
              id: track['url'] ?? track['id'] ?? '',
              album: track['album'] ?? '',
              title: track['title'] ?? 'Unknown Title',
              artist: track['artist'] ?? 'Unknown Artist',
              duration: track['duration'] != null
                  ? Duration(milliseconds: track['duration'])
                  : null,
              artUri: track['albumArt'] != null
                  ? Uri.parse(track['albumArt'])
                  : null,
              extras: track,
            ),
          )
          .toList();

      _currentIndex = startIndex.clamp(0, _playlist.length - 1);

      // Update queue
      queue.add(_playlist);

      // Start preloading
      _startPreloading();

      // Load current track
      await _loadTrack(_currentIndex);

      debugPrint(
        'Playlist loaded: ${_playlist.length} tracks, starting at index $_currentIndex',
      );
    } catch (e) {
      debugPrint('Error loading playlist: $e');
      rethrow;
    }
  }

  /// Load a specific track
  Future<void> _loadTrack(int index) async {
    if (index < 0 || index >= _playlist.length) return;

    final mediaItem = _playlist[index];
    final audioUrl = mediaItem.id;

    try {
      // Update current media item
      this.mediaItem.add(mediaItem);

      // Try to get cached file first
      final cachedFile = await _cacheService?.getAudioFile(audioUrl);

      AudioSource audioSource;
      if (cachedFile != null) {
        // Use cached file
        audioSource = AudioSource.file(cachedFile.path);
        debugPrint('Playing from cache: ${cachedFile.path}');
      } else {
        // Stream directly with background caching
        audioSource = ProgressiveAudioSource(Uri.parse(audioUrl));
        debugPrint('Streaming: $audioUrl');

        // Start background caching
        _cacheService?.getAudioFile(audioUrl).then((file) {
          if (file != null) {
            debugPrint('Background cached: $audioUrl');
          }
        });
      }

      await _audioPlayer.setAudioSource(audioSource);
      _currentIndex = index;

      // Update playback state
      playbackState.add(_playbackState.copyWith(queueIndex: _currentIndex));
    } catch (e) {
      debugPrint('Error loading track: $e');
      // Try next track on error
      if (_currentIndex < _playlist.length - 1) {
        await skipToNext();
      }
    }
  }

  /// Start intelligent preloading
  void _startPreloading() {
    _preloadTimer?.cancel();
    _preloadTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _preloadNextTracks();
    });

    // Initial preload
    _preloadNextTracks();
  }

  /// Preload next tracks based on playback patterns
  void _preloadNextTracks() async {
    if (_playlist.isEmpty) return;

    final tracksToPreload = <String>[];

    // Always preload next track
    final nextIndex = _getNextTrackIndex();
    if (nextIndex != -1 && nextIndex < _playlist.length) {
      tracksToPreload.add(_playlist[nextIndex].id);
    }

    // Preload track after next if shuffle is disabled
    if (!_shuffleEnabled && nextIndex != -1) {
      final nextNextIndex = (nextIndex + 1) % _playlist.length;
      if (nextNextIndex != _currentIndex) {
        tracksToPreload.add(_playlist[nextNextIndex].id);
      }
    }

    // Preload in background
    for (final url in tracksToPreload) {
      if (!_preloadingUrls.contains(url)) {
        _preloadingUrls.add(url);
        _cacheService
            ?.getAudioFile(url)
            .then((file) {
              _preloadingUrls.remove(url);
              if (file != null) {
                debugPrint('Preloaded: $url');
              }
            })
            .catchError((e) {
              _preloadingUrls.remove(url);
              debugPrint('Preload failed: $url - $e');
            });
      }
    }
  }

  /// Get next track index based on shuffle and repeat settings
  int _getNextTrackIndex() {
    if (_playlist.isEmpty) return -1;

    if (_shuffleEnabled) {
      // Random track (excluding current)
      final availableIndices = List.generate(
        _playlist.length,
        (i) => i,
      ).where((i) => i != _currentIndex).toList();
      if (availableIndices.isEmpty) return -1;
      availableIndices.shuffle();
      return availableIndices.first;
    } else {
      // Sequential
      if (_currentIndex < _playlist.length - 1) {
        return _currentIndex + 1;
      } else if (_repeatMode == AudioServiceRepeatMode.all) {
        return 0; // Loop to beginning
      }
      return -1; // End of playlist
    }
  }

  /// Handle track completion
  void _handleTrackCompletion() async {
    if (_repeatMode == AudioServiceRepeatMode.one) {
      // Repeat current track
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
      return;
    }

    final nextIndex = _getNextTrackIndex();
    if (nextIndex != -1) {
      await _loadTrack(nextIndex);
      await _audioPlayer.play();
    } else {
      // End of playlist
      await stop();
    }
  }

  /// Play a live stream (e.g., radio) via background service
  Future<void> playLiveStream({
    required String title,
    required String artist,
    required String artUrl,
    required String streamUrl,
  }) async {
    try {
      // Build media item for live stream
      final media = MediaItem(
        id: streamUrl,
        album: 'Live Radio',
        title: title,
        artist: artist,
        artUri: Uri.tryParse(artUrl),
        extras: {
          'type': 'live',
          'url': streamUrl,
          'title': title,
          'artist': artist,
        },
      );

      // Update current media item and clear any playlist context
      queue.add([media]);
      mediaItem.add(media);

      // Set audio source and play
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(streamUrl)));
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing live stream: $e');
      rethrow;
    }
  }

  // AudioHandler overrides

  @override
  Future<void> play() async {
    await _audioPlayer.play();
  }

  @override
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  @override
  Future<void> stop() async {
    await _audioPlayer.stop();
    playbackState.add(
      _playbackState.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async {
    final nextIndex = _getNextTrackIndex();
    if (nextIndex != -1) {
      await _loadTrack(nextIndex);
      await _audioPlayer.play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    int prevIndex;

    if (_shuffleEnabled) {
      // Random previous track
      final availableIndices = List.generate(
        _playlist.length,
        (i) => i,
      ).where((i) => i != _currentIndex).toList();
      if (availableIndices.isEmpty) return;
      availableIndices.shuffle();
      prevIndex = availableIndices.first;
    } else {
      // Sequential previous
      if (_currentIndex > 0) {
        prevIndex = _currentIndex - 1;
      } else if (_repeatMode == AudioServiceRepeatMode.all) {
        prevIndex = _playlist.length - 1;
      } else {
        return;
      }
    }

    await _loadTrack(prevIndex);
    await _audioPlayer.play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index >= 0 && index < _playlist.length) {
      await _loadTrack(index);
      await _audioPlayer.play();
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    _shuffleEnabled = shuffleMode == AudioServiceShuffleMode.all;
    playbackState.add(_playbackState.copyWith(shuffleMode: shuffleMode));
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    _repeatMode = repeatMode;
    playbackState.add(_playbackState.copyWith(repeatMode: repeatMode));
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioPlayer.setSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume);
  }

  // Utility methods

  AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  /// Get current playback position
  Duration get position => _audioPlayer.position;

  /// Get track duration
  Duration? get duration => _audioPlayer.duration;

  /// Get current track info
  MediaItem? get currentTrack =>
      _playlist.isNotEmpty ? _playlist[_currentIndex] : null;

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    // Ensure service initialized
    await initialize();
    return await _cacheService!.getCacheStats();
  }

  /// Clear cache
  Future<void> clearCache() async {
    await initialize();
    await _cacheService!.clearCache();
  }

  /// Dispose resources
  Future<void> dispose() async {
    _preloadTimer?.cancel();
    await _positionSubscription.cancel();
    await _playbackEventSubscription.cancel();
    await _playerStateSubscription.cancel();
    await _audioPlayer.dispose();
    await super.stop();
  }
}

/// Custom audio source for progressive loading with caching
class ProgressiveAudioSource extends StreamAudioSource {
  final Uri uri;

  ProgressiveAudioSource(this.uri);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final response = await HttpClient().getUrl(uri);

    if (start != null || end != null) {
      response.headers.set('Range', 'bytes=${start ?? 0}-${end ?? ''}');
    }

    final httpResponse = await response.close();

    return StreamAudioResponse(
      sourceLength: httpResponse.contentLength,
      contentLength: httpResponse.contentLength,
      offset: start ?? 0,
      stream: httpResponse,
      contentType: httpResponse.headers.contentType?.toString() ?? 'audio/mpeg',
    );
  }
}

/// Audio cache statistics
class AudioCacheStats {
  final int totalFiles;
  final int totalSize;
  final int hitCount;
  final int missCount;
  final double hitRate;

  AudioCacheStats({
    required this.totalFiles,
    required this.totalSize,
    required this.hitCount,
    required this.missCount,
  }) : hitRate = hitCount + missCount > 0
           ? hitCount / (hitCount + missCount)
           : 0.0;

  Map<String, dynamic> toMap() => {
    'totalFiles': totalFiles,
    'totalSize': totalSize,
    'hitCount': hitCount,
    'missCount': missCount,
    'hitRate': hitRate,
  };
}

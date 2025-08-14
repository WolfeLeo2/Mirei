import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mirei/services/audio_cache_service.dart';
import 'package:mirei/services/youtube_live_audio_service.dart';
import 'media_player_event.dart';
import 'media_player_state.dart';
import 'repeat_mode.dart';

class MediaPlayerBloc extends Bloc<MediaPlayerEvent, MediaPlayerState> {
  final AudioPlayer _audioPlayer;
  final AudioCacheService _cacheService;
  final YouTubeLiveAudioService _youtubeService = YouTubeLiveAudioService();
  double _volumeBeforeMute = 0.7;

  // Stream subscriptions for proper disposal
  late final StreamSubscription _positionSubscription;
  late final StreamSubscription _playerStateSubscription;
  late final StreamSubscription _durationSubscription;
  late final StreamSubscription _processingStateSubscription;

  // Track initialization state to prevent stream override issues
  bool _isInitializing = false;

  // Track current initialization to prevent race conditions
  String? _currentInitializationId;

  // Track when we're actively initializing to filter stream events
  bool _isActivelyInitializing = false;

  // Debounced skip operations to prevent rapid consecutive skips from overwhelming the system
  Timer? _skipDebounceTimer;
  final Duration _skipDebounceDelay = Duration(milliseconds: 150);
  int? _pendingSkipIndex;

  // Removed default fallback URL - tracks should provide their own URLs

  MediaPlayerBloc({
    required AudioPlayer audioPlayer,
    required AudioCacheService cacheService,
  }) : _audioPlayer = audioPlayer,
       _cacheService = cacheService,
       super(MediaPlayerState.initial()) {
    // Event handlers
    on<Initialize>(_onInitialize);
    on<Play>(_onPlay);
    on<Pause>(_onPause);
    on<Seek>(_onSeek);
    on<SkipToNext>(_onSkipToNext);
    on<SkipToPrevious>(_onSkipToPrevious);
    on<SetVolume>(_onSetVolume);
    on<ToggleMute>(_onToggleMute);
    on<ToggleShuffle>(_onToggleShuffle);
    on<SetRepeatMode>(_onSetRepeatMode);
    on<ClearError>(_onClearError);

    // Internal event handlers with enhanced filtering
    on<PositionUpdated>((event, emit) {
      // Only update position if we're not actively initializing
      if (!_isActivelyInitializing && _currentInitializationId != null) {
        emit(state.copyWith(position: event.position));
      }
    });

    on<DurationUpdated>((event, emit) {
      // Only update duration if we're not actively initializing
      if (!_isActivelyInitializing && _currentInitializationId != null) {
        emit(state.copyWith(duration: event.duration));
      }
    });

    on<PlayerStateUpdated>((event, emit) {
      // Only update player state if we're not actively initializing
      if (!_isActivelyInitializing && _currentInitializationId != null) {
        emit(
          state.copyWith(
            isPlaying: event.playerState.playing,
            processingState: event.playerState.processingState,
          ),
        );
      }
    });

    on<ProcessingStateUpdated>((event, emit) {
      // Only update processing state if we're not actively initializing
      if (!_isActivelyInitializing && _currentInitializationId != null) {
        final isBuffering =
            event.processingState == ProcessingState.buffering ||
            event.processingState == ProcessingState.loading;

        emit(
          state.copyWith(
            isBuffering: isBuffering,
            processingState: event.processingState,
          ),
        );

        // Handle track completion
        if (event.processingState == ProcessingState.completed) {
          _handleTrackCompletion();
        }
      }
    });
    on<StreamError>(
      (event, emit) => emit(
        state.copyWith(hasError: true, error: event.error, isLoading: false),
      ),
    );

    _initializeStreamSubscriptions();
  }

  void _initializeStreamSubscriptions() {
    // Position stream - update position regardless of duration
    _positionSubscription = _audioPlayer.positionStream.listen(
      (position) {
        if (!isClosed) {
          add(PositionUpdated(position));
        }
      },
      onError: (error) {
        if (!isClosed) {
          debugPrint('Position stream error: $error');
        }
      },
    );

    // Player state stream
    _playerStateSubscription = _audioPlayer.playerStateStream.listen(
      (playerState) {
        if (!isClosed) {
          add(PlayerStateUpdated(playerState));
        }
      },
      onError: (error) {
        if (!isClosed) {
          debugPrint('Player state stream error: $error');
          add(StreamError('Playback error: ${error.toString()}'));
        }
      },
    );

    // Duration stream
    _durationSubscription = _audioPlayer.durationStream.listen(
      (duration) {
        if (!isClosed) {
          add(DurationUpdated(duration ?? Duration.zero));
        }
      },
      onError: (error) {
        if (!isClosed) {
          debugPrint('Duration stream error: $error');
        }
      },
    );

    // Processing state stream for buffering and completion handling
    _processingStateSubscription = _audioPlayer.processingStateStream.listen(
      (processingState) {
        if (!isClosed) {
          add(ProcessingStateUpdated(processingState));
        }
      },
      onError: (error) {
        if (!isClosed) {
          debugPrint('Processing state stream error: $error');
        }
      },
    );
  }

  Future<void> _onInitialize(
    Initialize event,
    Emitter<MediaPlayerState> emit,
  ) async {
    // Check if we're trying to load the same track that's already loaded
    final isSameTrack = state.trackTitle == event.trackTitle && 
                       state.artistName == event.artistName &&
                       state.albumArt == event.albumArt;
    
    if (isSameTrack && state.trackTitle.isNotEmpty) {
      print('🔄 Same track already loaded, skipping reinitialization');
      // Just show the current state without restarting
      return;
    }

    // Generate unique initialization ID to prevent race conditions
    final initId = DateTime.now().millisecondsSinceEpoch.toString();
    _currentInitializationId = initId;
    _isActivelyInitializing = true; // Block stream events during initialization

    print('🎵 MediaPlayer Initialize called with ID: $initId');
    print('   - currentIndex: ${event.currentIndex}');
    print('   - audioUrl: ${event.audioUrl}');
    print('   - trackTitle: ${event.trackTitle}');
    print('   - artistName: ${event.artistName}');
    print('   - autoPlay: ${event.autoPlay}');
    print('   - playlist length: ${event.playlist?.length ?? 0}');

    // CRITICAL FIX: Stop current audio FIRST to prevent overlap
    try {
      print('⏹️ Stopping current audio player...');
      await _audioPlayer.stop();
      print('✅ Audio player stopped successfully');
    } catch (e) {
      print('⚠️ Warning: Could not stop audio player: $e');
      // Continue anyway - this might happen if no audio is loaded
    }

    // Check if this initialization is still current (not superseded by another)
    if (_currentInitializationId != initId) {
      print(
        '🚫 Initialization $initId cancelled - superseded by ${_currentInitializationId}',
      );
      return;
    }

    // Validate that we have an audio URL - no fallback anymore
    if (event.audioUrl == null || event.audioUrl!.isEmpty) {
      print('❌ No audio URL provided, cannot initialize track');
      emit(state.copyWith(
        hasError: true,
        error: 'No audio URL provided for this track',
        isLoading: false,
        isBuffering: false,
      ));
      return;
    }

    // Determine if the new URL is a live stream (YouTube live or generic)
    final urlForCheck = event.audioUrl!;
    final isYouTubeForCheck = urlForCheck.contains('youtube.com') || urlForCheck.contains('youtu.be');
    final isGenericLiveStreamForCheck = urlForCheck.contains('stream') || urlForCheck.contains('autodj');
    final isLiveStreamInitial = isYouTubeForCheck || isGenericLiveStreamForCheck;

    // Update track info AND loading state together to prevent race condition
    final currentIndex = event.currentIndex ?? 0;
    emit(
      state.copyWith(
        trackTitle: event.trackTitle,
        artistName: event.artistName,
        albumArt: event.albumArt,
        playlist: event.playlist ?? [],
        currentIndex: currentIndex,
        isLoading: true, // Show loading on the NEW track, not the old one
        isBuffering: true, // Also set buffering for the new track
        hasError: false,
        error: null,
        isLiveStream: isLiveStreamInitial, // Set true if this is a live stream
        // Reset playback state for new track
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
      ),
    );

    final loadingStart = DateTime.now();
    try {
      print('🔄 Initializing cache service...');
      await _cacheService.ensureInitialized();

      // Check if still current after async operation
      if (_currentInitializationId != initId) {
        print(
          '🚫 Initialization $initId cancelled after cache init - superseded by ${_currentInitializationId}',
        );
        return;
      }

      final url = event.audioUrl!;
      print('📡 Audio URL to load: $url');

      Duration? newDuration;
      bool isLiveStream = false;
      bool isYouTube = url.contains('youtube.com') || url.contains('youtu.be');

      // Check for common live stream URL patterns
      final isGenericLiveStream =
          url.contains('stream') || url.contains('autodj');

      if (isYouTube) {
        print('🎥 Detected YouTube URL, using YouTubeLiveAudioService');
        final result = await _youtubeService.playLiveAudio(url, _audioPlayer);
        newDuration = result.duration;
        isLiveStream = result.isLive;

        if (isLiveStream) {
          print('📻 It\'s a YouTube live stream, skipping cache.');
        } else {
          print('🎬 It\'s a YouTube VOD, attempting to cache in background.');
          _cacheService.getAudioFile(url); // Fire-and-forget
        }
      } else if (isGenericLiveStream) {
        print('📻 Detected generic live stream, skipping cache.');
        isLiveStream = true;
        newDuration = null; // Live streams don\'t have a fixed duration
        await _audioPlayer.setUrl(url);
      } else {
        // Handle standard, cacheable audio files
        final cachedFile = await _cacheService.getAudioFile(url);
        print(
          '💾 Cached file: ${cachedFile?.path ?? "null"} (${cachedFile != null ? "exists" : "not cached"})',
        );

        if (_currentInitializationId != initId) {
          print(
            '🚫 Initialization $initId cancelled after cache lookup - superseded by ${_currentInitializationId}',
          );
          return;
        }

        if (cachedFile != null) {
          print('📁 Setting file path: ${cachedFile.path}');
          newDuration = await _audioPlayer.setFilePath(cachedFile.path);
        } else {
          print('🌐 Setting URL: $url');
          newDuration = await _audioPlayer.setUrl(url);
        }
      }

      // Final check if still current after setting audio source
      if (_currentInitializationId != initId) {
        print(
          '🚫 Initialization $initId cancelled after audio source set - superseded by ${_currentInitializationId}',
        );
        return;
      }

      // Ensure minimum loading spinner duration (500ms)
      final elapsed = DateTime.now().difference(loadingStart);
      const minLoading = Duration(milliseconds: 500);
      if (elapsed < minLoading) {
        await Future.delayed(minLoading - elapsed);
      }

      print('📍 Track info updated, audio source set. Duration: $newDuration');

      // Update state with new duration and clear loading flags
      emit(
        state.copyWith(
          duration: newDuration ?? Duration.zero,
          isLoading: false,
          isBuffering: false,
          hasError: false,
          error: null,
          isLiveStream: isLiveStream,
        ),
      );

      print('▶️ AutoPlay: ${event.autoPlay}');
      if (event.autoPlay) {
        print('🎶 Adding Play event');
        add(const Play());
      }

      print('✅ MediaPlayer initialization $initId completed successfully');
    } catch (e, stackTrace) {
      // Only handle error if this initialization is still current
      if (_currentInitializationId == initId) {
        print('❌ MediaPlayer initialization $initId error: $e');
        print('Stack trace: $stackTrace');
        debugPrint('MediaPlayer initialization error: $e\n$stackTrace');
        emit(
          state.copyWith(
            isLoading: false,
            isBuffering: false,
            hasError: true,
            error: 'Failed to load audio: ${e.toString()}',
          ),
        );
      } else {
        print('🚫 Ignoring error for superseded initialization $initId: $e');
      }
    } finally {
      // Only clear if this is still the current initialization
      if (_currentInitializationId == initId) {
        _isActivelyInitializing = false;
        print('🏁 Initialization $initId finalized');
      }
    }
  }

  Future<void> _onPlay(Play event, Emitter<MediaPlayerState> emit) async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      emit(
        state.copyWith(
          hasError: true,
          error: 'Failed to start playback: ${e.toString()}',
          isLoading: false,
        ),
      );
    }
  }

  Future<void> _onPause(Pause event, Emitter<MediaPlayerState> emit) async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      emit(
        state.copyWith(
          hasError: true,
          error: 'Failed to pause playback: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onSeek(Seek event, Emitter<MediaPlayerState> emit) async {
    await _audioPlayer.seek(event.position);
  }

  Future<void> _onSkipToNext(
    SkipToNext event,
    Emitter<MediaPlayerState> emit,
  ) async {
    if (state.playlist.isEmpty) return;

    int nextIndex;

    if (state.isShuffleEnabled) {
      // Shuffle mode: pick a random track (excluding current)
      final availableIndices = List.generate(
        state.playlist.length,
        (i) => i,
      ).where((i) => i != state.currentIndex).toList();
      if (availableIndices.isEmpty) return;
      nextIndex = availableIndices[Random().nextInt(availableIndices.length)];
    } else {
      // Sequential mode
      if (state.currentIndex < state.playlist.length - 1) {
        nextIndex = state.currentIndex + 1;
      } else {
        // At end of playlist
        switch (state.repeatMode) {
          case RepeatMode.all:
            nextIndex = 0; // Loop back to beginning
            break;
          case RepeatMode.one:
          case RepeatMode.none:
            return; // Don't skip
        }
      }
    }

    // Use debounced skip for better performance during rapid skipping
    _debouncedSkipToIndex(nextIndex);
  }

  Future<void> _onSkipToPrevious(
    SkipToPrevious event,
    Emitter<MediaPlayerState> emit,
  ) async {
    if (state.playlist.isEmpty) return;

    int prevIndex;

    if (state.isShuffleEnabled) {
      // Shuffle mode: pick a random track (excluding current)
      final availableIndices = List.generate(
        state.playlist.length,
        (i) => i,
      ).where((i) => i != state.currentIndex).toList();
      if (availableIndices.isEmpty) return;
      prevIndex = availableIndices[Random().nextInt(availableIndices.length)];
    } else {
      // Sequential mode
      if (state.currentIndex > 0) {
        prevIndex = state.currentIndex - 1;
      } else {
        // At beginning of playlist
        switch (state.repeatMode) {
          case RepeatMode.all:
            prevIndex = state.playlist.length - 1; // Loop to end
            break;
          case RepeatMode.one:
          case RepeatMode.none:
            return; // Don't skip
        }
      }
    }

    // Use debounced skip for better performance during rapid skipping
    _debouncedSkipToIndex(prevIndex);
  }

  /// Debounced skip to prevent overwhelming the system during rapid consecutive skips
  void _debouncedSkipToIndex(int targetIndex) {
    print('⏭️ Debounced skip requested to index: $targetIndex');

    // Cancel any existing skip timer
    _skipDebounceTimer?.cancel();

    // Set the pending skip index
    _pendingSkipIndex = targetIndex;

    // Start a new timer
    _skipDebounceTimer = Timer(_skipDebounceDelay, () {
      // Only execute if we're not closed and the pending index is still relevant
      if (!isClosed && _pendingSkipIndex == targetIndex) {
        print('✅ Executing debounced skip to index: $targetIndex');
        _executeSkipToIndex(targetIndex);
      } else {
        print(
          '🚫 Skipping execution for stale skip to index: $targetIndex (current pending: $_pendingSkipIndex)',
        );
      }
      _pendingSkipIndex = null;
    });
  }

  /// Executes the actual skip to the specified index
  void _executeSkipToIndex(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= state.playlist.length) {
      print(
        '❌ Invalid skip index: $targetIndex (playlist length: ${state.playlist.length})',
      );
      return;
    }

    final targetTrack = state.playlist[targetIndex];
    add(
      Initialize(
        trackTitle: targetTrack['title'] ?? 'Unknown Title',
        artistName: targetTrack['artist'] ?? 'Unknown Artist',
        albumArt: targetTrack['albumArt'] ?? '',
        audioUrl: targetTrack['url'],
        playlist: state.playlist,
        currentIndex: targetIndex,
        autoPlay: true,
      ),
    );
  }

  Future<void> _onSetVolume(
    SetVolume event,
    Emitter<MediaPlayerState> emit,
  ) async {
    await _audioPlayer.setVolume(event.volume);
    emit(state.copyWith(volume: event.volume));
  }

  Future<void> _onToggleMute(
    ToggleMute event,
    Emitter<MediaPlayerState> emit,
  ) async {
    if (state.isMuted) {
      await _audioPlayer.setVolume(_volumeBeforeMute);
      emit(state.copyWith(isMuted: false, volume: _volumeBeforeMute));
    } else {
      _volumeBeforeMute = state.volume;
      await _audioPlayer.setVolume(0);
      emit(state.copyWith(isMuted: true, volume: 0));
    }
  }

  Future<void> _onToggleShuffle(
    ToggleShuffle event,
    Emitter<MediaPlayerState> emit,
  ) async {
    emit(state.copyWith(isShuffleEnabled: !state.isShuffleEnabled));
  }

  Future<void> _onSetRepeatMode(
    SetRepeatMode event,
    Emitter<MediaPlayerState> emit,
  ) async {
    emit(state.copyWith(repeatMode: event.mode));
  }

  Future<void> _onClearError(
    ClearError event,
    Emitter<MediaPlayerState> emit,
  ) async {
    emit(state.copyWith(hasError: false, error: null));
  }

  void _handleTrackCompletion() {
    switch (state.repeatMode) {
      case RepeatMode.one:
        // Repeat current track
        add(const Play());
        break;
      case RepeatMode.all:
      case RepeatMode.none:
        // Skip to next track (respects repeat all mode)
        add(const SkipToNext());
        break;
    }
  }

  @override
  Future<void> close() async {
    // Cancel debounce timer
    _skipDebounceTimer?.cancel();

    // Cancel all stream subscriptions to prevent memory leaks
    await _positionSubscription.cancel();
    await _playerStateSubscription.cancel();
    await _durationSubscription.cancel();
    await _processingStateSubscription.cancel();

    // Dispose audio player
    await _audioPlayer.dispose();

    return super.close();
  }
}

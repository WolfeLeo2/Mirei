import 'dart:async';
import 'dart:math';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mirei/services/audio_cache_service.dart';
import 'package:mirei/services/youtube_live_audio_service.dart';
import 'package:mirei/services/background_audio_service.dart';
import 'media_player_event.dart';
import 'media_player_state.dart';
import 'repeat_mode.dart';

class MediaPlayerBloc extends Bloc<MediaPlayerEvent, MediaPlayerState> {
  final AudioPlayer _audioPlayer;
  final AudioCacheService _cacheService;
  final YouTubeLiveAudioService _youtubeService = YouTubeLiveAudioService();
  final BackgroundAudioService _backgroundAudioService =
      BackgroundAudioService.instance;
  double _volumeBeforeMute = 0.7;
  bool _useBackgroundService =
      true; // Flag to enable/disable background service

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

  // Default fallback URL - make this configurable if needed
  static const String _defaultAudioUrl =
      "https://mirei-audio.netlify.app/NujabesLOFI.m4a";

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

    // Initialize background audio service if enabled and has playlist
    if (_useBackgroundService &&
        event.playlist != null &&
        event.playlist!.isNotEmpty) {
      try {
        print('🎵 Initializing background audio service...');
        await _backgroundAudioService.initialize();

        // Convert playlist to background service format
        final backgroundPlaylist = event.playlist!
            .map(
              (track) => {
                'title': track['title'] ?? event.trackTitle ?? 'Unknown Title',
                'artist':
                    track['artist'] ?? event.artistName ?? 'Unknown Artist',
                'url': track['url'] ?? event.audioUrl ?? _defaultAudioUrl,
                'albumArt': track['albumArt'] ?? event.albumArt,
                'duration': track['duration'],
              },
            )
            .toList();

        await _backgroundAudioService.loadPlaylist(
          backgroundPlaylist,
          startIndex: event.currentIndex ?? 0,
        );
        print(
          '✅ Background audio service initialized with ${backgroundPlaylist.length} tracks',
        );
      } catch (e) {
        print('⚠️ Background service initialization failed: $e');
        // Continue with regular audio player
        _useBackgroundService = false;
      }
    }

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
        // Reset playback state for new track
        isPlaying: false,
        position: Duration.zero,
        duration: Duration.zero,
      ),
    );

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

      final url = event.audioUrl ?? _defaultAudioUrl;
      print('📡 Audio URL to load: $url');

      Duration? newDuration;
      bool isYouTube = url.contains('youtube.com') || url.contains('youtu.be');
      if (isYouTube) {
        print('🎥 Detected YouTube URL, using YouTubeLiveAudioService');
        newDuration = await _youtubeService.playLiveAudio(url, _audioPlayer);
      } else {
        final cachedFile = await _cacheService.getAudioFile(url);
        print(
          '💾 Cached file: ${cachedFile?.path ?? "null"} (${cachedFile != null ? "exists" : "not cached"})',
        );

        // Check if still current after async operation
        if (_currentInitializationId != initId) {
          print(
            '🚫 Initialization $initId cancelled after cache lookup - superseded by ${_currentInitializationId}',
          );
          return;
        }

        // Set new audio source
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

      print('📍 Track info updated, audio source set. Duration: $newDuration');

      // Update state with new duration and clear loading flags
      emit(
        state.copyWith(
          duration: newDuration ?? Duration.zero,
          isLoading: false,
          isBuffering: false,
          hasError: false,
          error: null,
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
    print('\n🎶 MediaPlayerBloc._onPlay called:');
    print(
      '   - Current audio source: ${_audioPlayer.audioSource?.toString() ?? "null"}',
    );
    print('   - Current position: ${_audioPlayer.position}');
    print('   - Current state: ${_audioPlayer.playerState}');

    try {
      if (_useBackgroundService) {
        print('🎵 Using background audio service for play');
        await _backgroundAudioService.play();
      } else {
      await _audioPlayer.play();
      }
      print('✅ Play completed successfully');
    } catch (e) {
      print('❌ Play failed: $e');
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
      if (_useBackgroundService) {
        print('🎵 Using background audio service for pause');
        await _backgroundAudioService.pause();
      } else {
    await _audioPlayer.pause();
      }
      print('✅ Pause completed successfully');
    } catch (e) {
      print('❌ Pause failed: $e');
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

    // Use background service skip if available
    if (_useBackgroundService) {
      try {
        print('🎵 Using background audio service for skip to next');
        await _backgroundAudioService.skipToNext();
        return;
      } catch (e) {
        print('❌ Background service skip to next failed: $e');
        // Fall back to manual logic
      }
    }

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
          default:
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

    // Use background service skip if available
    if (_useBackgroundService) {
      try {
        print('🎵 Using background audio service for skip to previous');
        await _backgroundAudioService.skipToPrevious();
        return;
      } catch (e) {
        print('❌ Background service skip to previous failed: $e');
        // Fall back to manual logic
      }
    }

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
          default:
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
      default:
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

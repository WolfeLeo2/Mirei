import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../services/music_player_service.dart';
import '../models/youtube_music_models.dart';

// Events
abstract class MusicPlayerEvent extends Equatable {
  const MusicPlayerEvent();

  @override
  List<Object?> get props => [];
}

class InitializePlayer extends MusicPlayerEvent {
  const InitializePlayer();
}

class PlaySong extends MusicPlayerEvent {
  final YouTubeSong song;

  const PlaySong(this.song);

  @override
  List<Object?> get props => [song];
}

class PlayPlaylist extends MusicPlayerEvent {
  final List<YouTubeSong> songs;
  final int startIndex;

  const PlayPlaylist(this.songs, {this.startIndex = 0});

  @override
  List<Object?> get props => [songs, startIndex];
}

class TogglePlayPause extends MusicPlayerEvent {
  const TogglePlayPause();
}

class StopPlayer extends MusicPlayerEvent {
  const StopPlayer();
}

class SkipToNext extends MusicPlayerEvent {
  const SkipToNext();
}

class SkipToPrevious extends MusicPlayerEvent {
  const SkipToPrevious();
}

class SeekToPosition extends MusicPlayerEvent {
  final Duration position;

  const SeekToPosition(this.position);

  @override
  List<Object?> get props => [position];
}

class ToggleShuffle extends MusicPlayerEvent {
  const ToggleShuffle();
}

class ToggleRepeat extends MusicPlayerEvent {
  const ToggleRepeat();
}

class SetVolume extends MusicPlayerEvent {
  final double volume;

  const SetVolume(this.volume);

  @override
  List<Object?> get props => [volume];
}

class AddToQueue extends MusicPlayerEvent {
  final YouTubeSong song;

  const AddToQueue(this.song);

  @override
  List<Object?> get props => [song];
}

class RemoveFromQueue extends MusicPlayerEvent {
  final int index;

  const RemoveFromQueue(this.index);

  @override
  List<Object?> get props => [index];
}

class UpdatePlayerState extends MusicPlayerEvent {
  final PlayerState playerState;
  final Duration? position;
  final Duration? duration;
  final bool isPlaying;

  const UpdatePlayerState({
    required this.playerState,
    this.position,
    this.duration,
    required this.isPlaying,
  });

  @override
  List<Object?> get props => [playerState, position, duration, isPlaying];
}

// States
abstract class MusicPlayerState extends Equatable {
  const MusicPlayerState();

  @override
  List<Object?> get props => [];
}

class MusicPlayerInitial extends MusicPlayerState {}

class MusicPlayerLoading extends MusicPlayerState {}

class MusicPlayerReady extends MusicPlayerState {
  final PlayerState playerState;
  final YouTubeSong? currentSong;
  final List<YouTubeSong> playlist;
  final int currentIndex;
  final Duration position;
  final Duration? duration;
  final bool isPlaying;
  final bool shuffleEnabled;
  final RepeatMode repeatMode;
  final double volume;

  const MusicPlayerReady({
    required this.playerState,
    this.currentSong,
    required this.playlist,
    required this.currentIndex,
    required this.position,
    this.duration,
    required this.isPlaying,
    required this.shuffleEnabled,
    required this.repeatMode,
    this.volume = 1.0,
  });

  @override
  List<Object?> get props => [
    playerState,
    currentSong,
    playlist,
    currentIndex,
    position,
    duration,
    isPlaying,
    shuffleEnabled,
    repeatMode,
    volume,
  ];

  MusicPlayerReady copyWith({
    PlayerState? playerState,
    YouTubeSong? currentSong,
    List<YouTubeSong>? playlist,
    int? currentIndex,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
    bool? shuffleEnabled,
    RepeatMode? repeatMode,
    double? volume,
  }) {
    return MusicPlayerReady(
      playerState: playerState ?? this.playerState,
      currentSong: currentSong ?? this.currentSong,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      volume: volume ?? this.volume,
    );
  }
}

class MusicPlayerError extends MusicPlayerState {
  final String message;

  const MusicPlayerError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class MusicPlayerBloc extends Bloc<MusicPlayerEvent, MusicPlayerState> {
  final MusicPlayerService _playerService = MusicPlayerService();

  MusicPlayerBloc() : super(MusicPlayerInitial()) {
    on<InitializePlayer>(_onInitializePlayer);
    on<PlaySong>(_onPlaySong);
    on<PlayPlaylist>(_onPlayPlaylist);
    on<TogglePlayPause>(_onTogglePlayPause);
    on<StopPlayer>(_onStopPlayer);
    on<SkipToNext>(_onSkipToNext);
    on<SkipToPrevious>(_onSkipToPrevious);
    on<SeekToPosition>(_onSeekToPosition);
    on<ToggleShuffle>(_onToggleShuffle);
    on<ToggleRepeat>(_onToggleRepeat);
    on<SetVolume>(_onSetVolume);
    on<AddToQueue>(_onAddToQueue);
    on<RemoveFromQueue>(_onRemoveFromQueue);
    on<UpdatePlayerState>(_onUpdatePlayerState);

    // Listen to player service streams
    _setupPlayerListeners();
  }

  void _setupPlayerListeners() {
    // Listen to multiple streams and emit combined updates
    _playerService.playerStateStream.listen((playerState) {
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        add(UpdatePlayerState(
          playerState: playerState,
          position: currentState.position,
          duration: currentState.duration,
          isPlaying: currentState.isPlaying,
        ));
      }
    });

    _playerService.playingStream.listen((isPlaying) {
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        add(UpdatePlayerState(
          playerState: currentState.playerState,
          position: currentState.position,
          duration: currentState.duration,
          isPlaying: isPlaying,
        ));
      }
    });
  }

  Future<void> _onInitializePlayer(
    InitializePlayer event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      emit(MusicPlayerLoading());
      await _playerService.initialize();
      emit(const MusicPlayerReady(
        playerState: PlayerState.idle,
        playlist: [],
        currentIndex: 0,
        position: Duration.zero,
        isPlaying: false,
        shuffleEnabled: false,
        repeatMode: RepeatMode.off,
      ));
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onPlaySong(
    PlaySong event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        emit(currentState.copyWith(playerState: PlayerState.loading));
        
        await _playerService.playSong(event.song);
        
        emit(currentState.copyWith(
          playerState: PlayerState.playing,
          currentSong: event.song,
          playlist: [event.song],
          currentIndex: 0,
          isPlaying: true,
        ));
      }
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onPlayPlaylist(
    PlayPlaylist event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      if (state is MusicPlayerReady && event.songs.isNotEmpty) {
        final currentState = state as MusicPlayerReady;
        emit(currentState.copyWith(playerState: PlayerState.loading));
        
        await _playerService.playPlaylist(event.songs, startIndex: event.startIndex);
        
        emit(currentState.copyWith(
          playerState: PlayerState.playing,
          currentSong: event.songs[event.startIndex],
          playlist: event.songs,
          currentIndex: event.startIndex,
          isPlaying: true,
        ));
      }
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onTogglePlayPause(
    TogglePlayPause event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        
        if (currentState.isPlaying) {
          await _playerService.pause();
          emit(currentState.copyWith(
            playerState: PlayerState.paused,
            isPlaying: false,
          ));
        } else {
          await _playerService.play();
          emit(currentState.copyWith(
            playerState: PlayerState.playing,
            isPlaying: true,
          ));
        }
      }
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onStopPlayer(
    StopPlayer event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        await _playerService.stop();
        emit(currentState.copyWith(
          playerState: PlayerState.stopped,
          isPlaying: false,
          position: Duration.zero,
        ));
      }
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onSkipToNext(
    SkipToNext event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        await _playerService.skipToNext();
        
        emit(currentState.copyWith(
          currentSong: _playerService.currentSong,
          currentIndex: _playerService.currentIndex,
        ));
      }
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onSkipToPrevious(
    SkipToPrevious event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        await _playerService.skipToPrevious();
        
        emit(currentState.copyWith(
          currentSong: _playerService.currentSong,
          currentIndex: _playerService.currentIndex,
        ));
      }
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onSeekToPosition(
    SeekToPosition event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      await _playerService.seekTo(event.position);
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        emit(currentState.copyWith(position: event.position));
      }
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onToggleShuffle(
    ToggleShuffle event,
    Emitter<MusicPlayerState> emit,
  ) async {
    if (state is MusicPlayerReady) {
      final currentState = state as MusicPlayerReady;
      _playerService.toggleShuffle();
      emit(currentState.copyWith(shuffleEnabled: _playerService.shuffleEnabled));
    }
  }

  Future<void> _onToggleRepeat(
    ToggleRepeat event,
    Emitter<MusicPlayerState> emit,
  ) async {
    if (state is MusicPlayerReady) {
      final currentState = state as MusicPlayerReady;
      _playerService.toggleRepeat();
      emit(currentState.copyWith(repeatMode: _playerService.repeatMode));
    }
  }

  Future<void> _onSetVolume(
    SetVolume event,
    Emitter<MusicPlayerState> emit,
  ) async {
    try {
      await _playerService.setVolume(event.volume);
      if (state is MusicPlayerReady) {
        final currentState = state as MusicPlayerReady;
        emit(currentState.copyWith(volume: event.volume));
      }
    } catch (e) {
      emit(MusicPlayerError(e.toString()));
    }
  }

  Future<void> _onAddToQueue(
    AddToQueue event,
    Emitter<MusicPlayerState> emit,
  ) async {
    if (state is MusicPlayerReady) {
      final currentState = state as MusicPlayerReady;
      _playerService.addToQueue(event.song);
      
      final updatedPlaylist = List<YouTubeSong>.from(currentState.playlist);
      updatedPlaylist.add(event.song);
      
      emit(currentState.copyWith(playlist: updatedPlaylist));
    }
  }

  Future<void> _onRemoveFromQueue(
    RemoveFromQueue event,
    Emitter<MusicPlayerState> emit,
  ) async {
    if (state is MusicPlayerReady) {
      final currentState = state as MusicPlayerReady;
      
      if (event.index >= 0 && event.index < currentState.playlist.length) {
        _playerService.removeFromQueue(event.index);
        
        final updatedPlaylist = List<YouTubeSong>.from(currentState.playlist);
        updatedPlaylist.removeAt(event.index);
        
        int newCurrentIndex = currentState.currentIndex;
        if (event.index < currentState.currentIndex) {
          newCurrentIndex--;
        } else if (event.index == currentState.currentIndex && newCurrentIndex >= updatedPlaylist.length) {
          newCurrentIndex = updatedPlaylist.isEmpty ? 0 : updatedPlaylist.length - 1;
        }
        
        emit(currentState.copyWith(
          playlist: updatedPlaylist,
          currentIndex: newCurrentIndex,
          currentSong: updatedPlaylist.isNotEmpty ? updatedPlaylist[newCurrentIndex] : null,
        ));
      }
    }
  }

  Future<void> _onUpdatePlayerState(
    UpdatePlayerState event,
    Emitter<MusicPlayerState> emit,
  ) async {
    if (state is MusicPlayerReady) {
      final currentState = state as MusicPlayerReady;
      emit(currentState.copyWith(
        playerState: event.playerState,
        position: event.position ?? currentState.position,
        duration: event.duration ?? currentState.duration,
        isPlaying: event.isPlaying,
      ));
    }
  }

  @override
  Future<void> close() {
    _playerService.dispose();
    return super.close();
  }
}

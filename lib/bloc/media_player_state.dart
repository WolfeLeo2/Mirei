import 'package:just_audio/just_audio.dart';
import 'repeat_mode.dart';

class MediaPlayerState {
  final String trackTitle;
  final String artistName;
  final String albumArt;
  final Duration duration;
  final Duration position;
  final bool isPlaying;
  final bool isBuffering;
  final bool isLoading;
  final bool isMuted;
  final double volume;
  final List<Map<String, dynamic>> playlist;
  final int currentIndex;
  final bool isShuffleEnabled;
  final RepeatMode repeatMode;
  final bool hasError;
  final ProcessingState? processingState;
  final String? error;
  final bool isLiveStream;

  const MediaPlayerState({
    required this.trackTitle,
    required this.artistName,
    required this.albumArt,
    required this.duration,
    required this.position,
    required this.isPlaying,
    required this.isBuffering,
    required this.isLoading,
    required this.isMuted,
    required this.volume,
    required this.playlist,
    required this.currentIndex,
    required this.isShuffleEnabled,
    required this.repeatMode,
    this.hasError = false,
    this.processingState,
    this.error,
    this.isLiveStream = false,
  });

  factory MediaPlayerState.initial() => const MediaPlayerState(
        trackTitle: '',
        artistName: '',
        albumArt: '',
        duration: Duration.zero,
        position: Duration.zero,
        isPlaying: false,
        isBuffering: false,
        isLoading: false,
        isMuted: false,
        volume: 0.7,
        playlist: [],
        currentIndex: 0,
        isShuffleEnabled: false,
        repeatMode: RepeatMode.none,
        hasError: false,
        isLiveStream: false,
      );

  MediaPlayerState copyWith({
    String? trackTitle,
    String? artistName,
    String? albumArt,
    Duration? duration,
    Duration? position,
    bool? isPlaying,
    bool? isBuffering,
    bool? isLoading,
    bool? isMuted,
    double? volume,
    List<Map<String, dynamic>>? playlist,
    int? currentIndex,
    bool? isShuffleEnabled,
    RepeatMode? repeatMode,
    bool? hasError,
    ProcessingState? processingState,
    String? error,
    bool? isLiveStream,
  }) {
    return MediaPlayerState(
      trackTitle: trackTitle ?? this.trackTitle,
      artistName: artistName ?? this.artistName,
      albumArt: albumArt ?? this.albumArt,
      duration: duration ?? this.duration,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isLoading: isLoading ?? this.isLoading,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      playlist: playlist ?? this.playlist,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      hasError: hasError ?? this.hasError,
      processingState: processingState ?? this.processingState,
      error: error ?? this.error,
      isLiveStream: isLiveStream ?? this.isLiveStream,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MediaPlayerState &&
        other.trackTitle == trackTitle &&
        other.artistName == artistName &&
        other.albumArt == albumArt &&
        other.duration == duration &&
        other.position == position &&
        other.isPlaying == isPlaying &&
        other.isBuffering == isBuffering &&
        other.isLoading == isLoading &&
        other.isMuted == isMuted &&
        other.volume == volume &&
        other.currentIndex == currentIndex &&
        other.isShuffleEnabled == isShuffleEnabled &&
        other.repeatMode == repeatMode &&
        other.hasError == hasError &&
        other.processingState == processingState &&
        other.error == error &&
        other.isLiveStream == isLiveStream;
  }

  @override
  int get hashCode {
    return Object.hash(
      trackTitle,
      artistName,
      albumArt,
      duration,
      position,
      isPlaying,
      isBuffering,
      isLoading,
      isMuted,
      volume,
      playlist,
      currentIndex,
      isShuffleEnabled,
      repeatMode,
      hasError,
      processingState,
      error,
      isLiveStream,
    );
  }

  @override
  String toString() {
    return 'MediaPlayerState('
        'trackTitle: $trackTitle, '
        'artistName: $artistName, '
        'albumArt: $albumArt, '
        'duration: $duration, '
        'position: $position, '
        'isPlaying: $isPlaying, '
        'isBuffering: $isBuffering, '
        'isLoading: $isLoading, '
        'isMuted: $isMuted, '
        'volume: $volume, '
        'playlist: $playlist, '
        'currentIndex: $currentIndex, '
        'isShuffleEnabled: $isShuffleEnabled, '
        'repeatMode: $repeatMode, '
        'hasError: $hasError, '
        'processingState: $processingState, '
        'error: $error, '
        'isLiveStream: $isLiveStream'
        ')';
  }
}

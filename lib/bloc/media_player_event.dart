import 'package:just_audio/just_audio.dart';
import 'repeat_mode.dart';

abstract class MediaPlayerEvent {
  const MediaPlayerEvent();
}

// Public events
class Initialize extends MediaPlayerEvent {
  final String trackTitle;
  final String artistName;
  final String albumArt;
  final String? audioUrl;
  final List<Map<String, dynamic>>? playlist;
  final int? currentIndex;
  final bool autoPlay;

  const Initialize({
    required this.trackTitle,
    required this.artistName,
    required this.albumArt,
    this.audioUrl,
    this.playlist,
    this.currentIndex,
    this.autoPlay = false,
  });
}

class Play extends MediaPlayerEvent {
  const Play();
}

class Pause extends MediaPlayerEvent {
  const Pause();
}

class Seek extends MediaPlayerEvent {
  final Duration position;
  const Seek(this.position);
}

class SkipToNext extends MediaPlayerEvent {
  const SkipToNext();
}

class SkipToPrevious extends MediaPlayerEvent {
  const SkipToPrevious();
}

class SetVolume extends MediaPlayerEvent {
  final double volume;
  const SetVolume(this.volume);
}

class ToggleMute extends MediaPlayerEvent {
  const ToggleMute();
}

class ToggleShuffle extends MediaPlayerEvent {
  const ToggleShuffle();
}

class SetRepeatMode extends MediaPlayerEvent {
  final RepeatMode mode;
  const SetRepeatMode(this.mode);
}

class ClearError extends MediaPlayerEvent {
  const ClearError();
}

// Internal events for stream updates
class PositionUpdated extends MediaPlayerEvent {
  final Duration position;
  const PositionUpdated(this.position);
}

class DurationUpdated extends MediaPlayerEvent {
  final Duration duration;
  const DurationUpdated(this.duration);
}

class PlayerStateUpdated extends MediaPlayerEvent {
  final PlayerState playerState;
  const PlayerStateUpdated(this.playerState);
}

class ProcessingStateUpdated extends MediaPlayerEvent {
  final ProcessingState processingState;
  const ProcessingStateUpdated(this.processingState);
}

class StreamError extends MediaPlayerEvent {
  final String error;
  const StreamError(this.error);
}

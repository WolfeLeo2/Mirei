import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../models/youtube_music_models.dart';

enum PlayerState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  error,
}

enum RepeatMode {
  off,
  one,
  all,
}

class MusicPlayerService {
  static final MusicPlayerService _instance = MusicPlayerService._internal();
  factory MusicPlayerService() => _instance;
  MusicPlayerService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Current state
  PlayerState _playerState = PlayerState.idle;
  YouTubeSong? _currentSong;
  List<YouTubeSong> _playlist = [];
  int _currentIndex = 0;
  bool _shuffleEnabled = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  PlayerState get playerState => _playerState;
  YouTubeSong? get currentSong => _currentSong;
  List<YouTubeSong> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get shuffleEnabled => _shuffleEnabled;
  RepeatMode get repeatMode => _repeatMode;
  
  // Streams
  Stream<PlayerState> get playerStateStream => _audioPlayer.processingStateStream.map(_mapProcessingState);
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  /// Initialize the music player
  Future<void> initialize() async {
    try {
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.example.mirei.channel.audio',
        androidNotificationChannelName: 'Mirei Music',
        androidNotificationOngoing: true,
      );
      
      // Set up player state listeners
      _audioPlayer.processingStateStream.listen((state) {
        _playerState = _mapProcessingState(state);
      });

      // Handle playback completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _handleSongComplete();
        }
      });

    } catch (e) {
      print('Error initializing music player: $e');
      _playerState = PlayerState.error;
    }
  }

  /// Play a single song
  Future<void> playSong(YouTubeSong song) async {
    try {
      _playerState = PlayerState.loading;
      _currentSong = song;
      _playlist = [song];
      _currentIndex = 0;

      // Show that the song is selected but explain streaming limitation
      print('Selected song: ${song.title} by ${song.artist}');
      print('Note: ytmusicapi_dart doesn\'t provide streaming URLs for copyright protection');
      
      // Update state to show the song is "playing" (for UI demonstration)
      _playerState = PlayerState.playing;
      
      // For actual playback, you would need:
      // 1. YouTube Data API v3 with OAuth
      // 2. YouTube IFrame Player integration
      // 3. Legal streaming service APIs
      // 4. Local music files
      
    } catch (e) {
      print('Error selecting song: $e');
      _playerState = PlayerState.error;
    }
  }

  /// Play a playlist starting from a specific index
  Future<void> playPlaylist(List<YouTubeSong> songs, {int startIndex = 0}) async {
    if (songs.isEmpty) return;

    try {
      _playerState = PlayerState.loading;
      _playlist = List.from(songs);
      _currentIndex = startIndex.clamp(0, songs.length - 1);
      _currentSong = _playlist[_currentIndex];

      // Create playlist source
      final audioSources = _playlist.map((song) => AudioSource.uri(
        Uri.parse('https://example.com/placeholder.mp3'), // Placeholder
        tag: MediaItem(
          id: song.id,
          album: song.album?.title ?? 'Unknown Album',
          title: song.title,
          artist: song.artist,
          artUri: song.thumbnailUrl.isNotEmpty ? Uri.parse(song.thumbnailUrl) : null,
        ),
      )).toList();

      final playlist = ConcatenatingAudioSource(children: audioSources);
      await _audioPlayer.setAudioSource(playlist, initialIndex: _currentIndex);
      await _audioPlayer.play();

    } catch (e) {
      print('Error playing playlist: $e');
      _playerState = PlayerState.error;
    }
  }

  /// Resume playback
  Future<void> play() async {
    try {
      await _audioPlayer.play();
    } catch (e) {
      print('Error resuming playback: $e');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Error pausing playback: $e');
    }
  }

  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _playerState = PlayerState.stopped;
    } catch (e) {
      print('Error stopping playback: $e');
    }
  }

  /// Skip to next song
  Future<void> skipToNext() async {
    if (_playlist.isEmpty) return;

    try {
      if (_shuffleEnabled) {
        _currentIndex = _getRandomIndex();
      } else {
        _currentIndex = (_currentIndex + 1) % _playlist.length;
      }
      
      _currentSong = _playlist[_currentIndex];
      
      if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
        await _audioPlayer.seekToNext();
      } else {
        await playSong(_currentSong!);
      }
    } catch (e) {
      print('Error skipping to next: $e');
    }
  }

  /// Skip to previous song
  Future<void> skipToPrevious() async {
    if (_playlist.isEmpty) return;

    try {
      if (_shuffleEnabled) {
        _currentIndex = _getRandomIndex();
      } else {
        _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
      }
      
      _currentSong = _playlist[_currentIndex];
      
      if (_audioPlayer.audioSource is ConcatenatingAudioSource) {
        await _audioPlayer.seekToPrevious();
      } else {
        await playSong(_currentSong!);
      }
    } catch (e) {
      print('Error skipping to previous: $e');
    }
  }

  /// Seek to position
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      print('Error seeking: $e');
    }
  }

  /// Toggle shuffle
  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    _audioPlayer.setShuffleModeEnabled(_shuffleEnabled);
  }

  /// Toggle repeat mode
  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        _audioPlayer.setLoopMode(LoopMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Add song to queue
  void addToQueue(YouTubeSong song) {
    _playlist.add(song);
    // TODO: Add to concatenating audio source if playing
  }

  /// Remove song from queue
  void removeFromQueue(int index) {
    if (index >= 0 && index < _playlist.length) {
      _playlist.removeAt(index);
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex && _currentIndex >= _playlist.length) {
        _currentIndex = _playlist.isEmpty ? 0 : _playlist.length - 1;
      }
    }
  }

  /// Handle song completion
  void _handleSongComplete() {
    switch (_repeatMode) {
      case RepeatMode.one:
        // Song will repeat automatically due to LoopMode.one
        break;
      case RepeatMode.all:
        if (_currentIndex < _playlist.length - 1) {
          skipToNext();
        } else {
          // Restart playlist
          _currentIndex = 0;
          _currentSong = _playlist[_currentIndex];
          playSong(_currentSong!);
        }
        break;
      case RepeatMode.off:
        if (_currentIndex < _playlist.length - 1) {
          skipToNext();
        } else {
          // Stop at end
          _playerState = PlayerState.stopped;
        }
        break;
    }
  }

  /// Get random index for shuffle
  int _getRandomIndex() {
    if (_playlist.length <= 1) return 0;
    int newIndex;
    do {
      newIndex = (DateTime.now().millisecondsSinceEpoch % _playlist.length);
    } while (newIndex == _currentIndex);
    return newIndex;
  }

  /// Map processing state to player state
  PlayerState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return PlayerState.idle;
      case ProcessingState.loading:
        return PlayerState.loading;
      case ProcessingState.buffering:
        return PlayerState.loading;
      case ProcessingState.ready:
        return _audioPlayer.playing ? PlayerState.playing : PlayerState.paused;
      case ProcessingState.completed:
        return PlayerState.stopped;
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _audioPlayer.dispose();
  }
}

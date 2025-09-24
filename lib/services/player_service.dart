import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:audio_waveforms/audio_waveforms.dart';

/// Centralized audio player service that manages all audio playback in the app
class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final just_audio.AudioPlayer _player = just_audio.AudioPlayer();
  final Map<String, PlayerController> _waveformControllers = {};

  String? _currentlyPlayingPath;
  final StreamController<String?> _currentlyPlayingController =
      StreamController<String?>.broadcast();
  final StreamController<just_audio.PlayerState> _playerStateController =
      StreamController<just_audio.PlayerState>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();

  bool _isInitialized = false;

  // Public streams
  Stream<String?> get currentlyPlayingStream =>
      _currentlyPlayingController.stream;
  Stream<just_audio.PlayerState> get playerStateStream =>
      _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  String? get currentlyPlayingPath => _currentlyPlayingPath;
  bool get isPlaying => _player.playing;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;

  /// Initialize the service (idempotent - safe to call multiple times)
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Subscribe to player streams and re-broadcast
    _player.playerStateStream.listen(_playerStateController.add);
    _player.positionStream.listen(_positionController.add);
    _player.durationStream.listen(_durationController.add);

    _isInitialized = true;

    if (kDebugMode) {
      print('PlayerService: Initialized');
    }
  }

  /// Get or create a waveform controller for a specific audio path
  PlayerController getWaveformController(String audioPath) {
    if (!_waveformControllers.containsKey(audioPath)) {
      final controller = PlayerController();
      controller.preparePlayer(
        path: audioPath,
        shouldExtractWaveform: true,
        noOfSamples: 100,
        volume: 1.0,
      );
      _waveformControllers[audioPath] = controller;
    }
    return _waveformControllers[audioPath]!;
  }

  /// Play audio from a file path
  Future<void> playAudio(String audioPath) async {
    try {
      if (_currentlyPlayingPath == audioPath) {
        // Toggle play/pause for current audio
        if (_player.playing) {
          await _player.pause();
          final controller = _waveformControllers[audioPath];
          await controller?.pausePlayer();
        } else {
          await _player.play();
          final controller = _waveformControllers[audioPath];
          await controller?.startPlayer();
        }
        return;
      }

      // Stop current audio if playing different file
      if (_currentlyPlayingPath != null) {
        await _player.stop();
        final prevController = _waveformControllers[_currentlyPlayingPath!];
        await prevController?.stopPlayer();
      }

      // Start new audio
      await _player.setFilePath(audioPath);
      await _player.play();

      final controller = _waveformControllers[audioPath];
      await controller?.startPlayer();

      _currentlyPlayingPath = audioPath;
      _currentlyPlayingController.add(audioPath);

      if (kDebugMode) {
        print('PlayerService: Started playing $audioPath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PlayerService: Error playing audio $audioPath: $e');
      }
      rethrow;
    }
  }

  /// Play audio from URL (for streaming)
  Future<void> playUrl(String url) async {
    try {
      if (_currentlyPlayingPath != null) {
        await stop();
      }

      await _player.setUrl(url);
      await _player.play();

      _currentlyPlayingPath = url;
      _currentlyPlayingController.add(url);

      if (kDebugMode) {
        print('PlayerService: Started streaming $url');
      }
    } catch (e) {
      if (kDebugMode) {
        print('PlayerService: Error streaming audio $url: $e');
      }
      rethrow;
    }
  }

  /// Pause current audio
  Future<void> pause() async {
    await _player.pause();
    if (_currentlyPlayingPath != null) {
      final controller = _waveformControllers[_currentlyPlayingPath!];
      await controller?.pausePlayer();
    }
  }

  /// Resume current audio
  Future<void> resume() async {
    await _player.play();
    if (_currentlyPlayingPath != null) {
      final controller = _waveformControllers[_currentlyPlayingPath!];
      await controller?.startPlayer();
    }
  }

  /// Stop current audio
  Future<void> stop() async {
    await _player.stop();
    if (_currentlyPlayingPath != null) {
      final controller = _waveformControllers[_currentlyPlayingPath!];
      await controller?.stopPlayer();
    }
    _currentlyPlayingPath = null;
    _currentlyPlayingController.add(null);
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    if (_currentlyPlayingPath != null) {
      final controller = _waveformControllers[_currentlyPlayingPath!];
      await controller?.seekTo(position.inMilliseconds);
    }
  }

  /// Skip forward by duration
  Future<void> skipForward(Duration duration) async {
    final newPosition = _player.position + duration;
    final maxDuration = _player.duration ?? Duration.zero;
    final clampedPosition = newPosition > maxDuration
        ? maxDuration
        : newPosition;
    await seek(clampedPosition);
  }

  /// Skip backward by duration
  Future<void> skipBackward(Duration duration) async {
    final newPosition = _player.position - duration;
    final clampedPosition = newPosition < Duration.zero
        ? Duration.zero
        : newPosition;
    await seek(clampedPosition);
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  /// Clean up resources for a specific audio path
  void disposeWaveformController(String audioPath) {
    final controller = _waveformControllers.remove(audioPath);
    controller?.dispose();
  }

  /// Clean up all resources
  Future<void> dispose() async {
    await _player.dispose();
    for (final controller in _waveformControllers.values) {
      controller.dispose();
    }
    _waveformControllers.clear();
    await _currentlyPlayingController.close();
    await _playerStateController.close();
    await _positionController.close();
    await _durationController.close();
  }
}

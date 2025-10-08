import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

/// Centralized audio player service that manages audio playback using
/// the audio_waveforms package.
class PlayerService {
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;
  PlayerService._internal();

  final Map<String, PlayerController> _controllers = {};
  final Map<String, Future<void>> _preparingControllers = {};
  final Map<String, StreamSubscription<void>> _completionSubscriptions = {};
  final Set<String> _preparedPaths = <String>{};

  String? _currentlyPlayingPath;
  final StreamController<String?> _currentlyPlayingController =
      StreamController<String?>.broadcast();

  bool _isInitialized = false;

  Stream<String?> get currentlyPlayingStream =>
      _currentlyPlayingController.stream;

  String? get currentlyPlayingPath => _currentlyPlayingPath;

  bool get isPlaying {
    if (_currentlyPlayingPath == null) return false;
    final controller = _controllers[_currentlyPlayingPath!];
    return controller?.playerState == PlayerState.playing;
  }

  /// Initialize the service (idempotent - safe to call multiple times)
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kDebugMode) {
      print('PlayerService: Initialized');
    }
  }

  /// Get or create a waveform/player controller for a specific audio path.
  PlayerController getWaveformController(String audioPath) {
    final existing = _controllers[audioPath];
    if (existing != null) {
      if (!_preparedPaths.contains(audioPath) &&
          !_preparingControllers.containsKey(audioPath)) {
        unawaited(_ensurePrepared(audioPath));
      }
      return existing;
    }

    final controller = PlayerController();
    _controllers[audioPath] = controller;

    _completionSubscriptions[audioPath] = controller.onCompletion.listen(
      (_) => _handleCompletion(audioPath),
    );

    unawaited(_ensurePrepared(audioPath));

    return controller;
  }

  /// Play or toggle playback for a local audio file.
  Future<void> playAudio(String audioPath) async {
    try {
      await initialize();

      final controller = getWaveformController(audioPath);
      await _ensurePrepared(audioPath);

      if (_currentlyPlayingPath == audioPath) {
        if (controller.playerState == PlayerState.playing) {
          await controller.pausePlayer();
          _currentlyPlayingPath = null;
          _currentlyPlayingController.add(null);
        } else {
          await controller.startPlayer();
          _currentlyPlayingPath = audioPath;
          _currentlyPlayingController.add(audioPath);
        }
        return;
      }

      if (_currentlyPlayingPath != null) {
        final previous = _controllers[_currentlyPlayingPath!];
        await previous?.stopPlayer();
      }

      await controller.startPlayer();
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

  /// Stop the currently playing audio, if any.
  Future<void> stop() async {
    if (_currentlyPlayingPath == null) {
      return;
    }

    final controller = _controllers[_currentlyPlayingPath!];
    await controller?.stopPlayer();

    _currentlyPlayingPath = null;
    _currentlyPlayingController.add(null);
  }

  /// Dispose all controllers and clean up resources.
  Future<void> dispose() async {
    await stop();

    for (final subscription in _completionSubscriptions.values) {
      await subscription.cancel();
    }
    _completionSubscriptions.clear();

    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    _preparingControllers.clear();
    _preparedPaths.clear();

    await _currentlyPlayingController.close();

    if (kDebugMode) {
      print('PlayerService: Disposed');
    }
  }

  Future<void> _ensurePrepared(String audioPath) async {
    if (_preparedPaths.contains(audioPath)) {
      return;
    }

    var future = _preparingControllers[audioPath];
    if (future != null) {
      await future;
      return;
    }

    future = _prepareController(audioPath);
    _preparingControllers[audioPath] = future;
    try {
      await future;
      _preparedPaths.add(audioPath);
    } finally {
      _preparingControllers.remove(audioPath);
    }
  }

  Future<void> _prepareController(String audioPath) async {
    final controller = _controllers[audioPath];
    if (controller == null) return;

    await controller.preparePlayer(
      path: audioPath,
      shouldExtractWaveform: true,
      noOfSamples: 120,
      volume: 1.0,
    );
    await controller.setFinishMode(finishMode: FinishMode.stop);
  }

  void _handleCompletion(String completedPath) {
    if (_currentlyPlayingPath == completedPath) {
      _currentlyPlayingPath = null;
      _currentlyPlayingController.add(null);
    }
  }
}

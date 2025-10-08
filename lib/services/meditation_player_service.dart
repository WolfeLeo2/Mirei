import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/meditation.dart';

class MeditationPlayerService {
  static final MeditationPlayerService _instance =
      MeditationPlayerService._internal();
  factory MeditationPlayerService() => _instance;
  MeditationPlayerService._internal();

  AudioPlayer? _player;
  Meditation? _currentMeditation;

  final StreamController<bool> _isPlayingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<Meditation?> _currentMeditationController =
      StreamController<Meditation?>.broadcast();

  // Streams for UI to listen to
  Stream<bool> get isPlayingStream => _isPlayingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<Meditation?> get currentMeditationStream =>
      _currentMeditationController.stream;

  // Getters for current state
  bool get isPlaying => _player?.playing ?? false;
  Meditation? get currentMeditation => _currentMeditation;
  Duration get currentPosition => _player?.position ?? Duration.zero;
  Duration get totalDuration => _player?.duration ?? Duration.zero;

  Future<void> playMeditation(Meditation meditation) async {
    if (_currentMeditation?.audioUrl == meditation.audioUrl &&
        _player != null) {
      // Same meditation, just toggle
      if (isPlaying) {
        await _player!.pause();
      } else {
        await _player!.play();
      }
      return;
    }

    // New meditation or first time
    await _stopCurrent();
    _currentMeditation = meditation;
    _currentMeditationController.add(meditation);

    _player = AudioPlayer();

    try {
      await _player!.setUrl(meditation.audioUrl);

      // Set up streams
      _player!.playerStateStream.listen((state) {
        final playing =
            state.playing && state.processingState != ProcessingState.completed;
        _isPlayingController.add(playing);
      });

      _player!.positionStream.listen((position) {
        _positionController.add(position);
      });

      _player!.durationStream.listen((duration) {
        if (duration != null) {
          _durationController.add(duration);
        }
      });

      await _player!.play();
    } catch (e) {
      if (kDebugMode) {
        print('Error playing meditation: $e');
      }
      await _stopCurrent();
    }
  }

  Future<void> pause() async {
    await _player?.pause();
  }

  Future<void> resume() async {
    await _player?.play();
  }

  Future<void> seek(Duration position) async {
    await _player?.seek(position);
  }

  Future<void> stop() async {
    await _stopCurrent();
    _currentMeditation = null;
    _currentMeditationController.add(null);
  }

  Future<void> _stopCurrent() async {
    await _player?.stop();
    await _player?.dispose();
    _player = null;
  }

  void dispose() {
    _stopCurrent();
    _isPlayingController.close();
    _positionController.close();
    _durationController.close();
    _currentMeditationController.close();
  }
}

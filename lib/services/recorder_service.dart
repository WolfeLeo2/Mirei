import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Service to handle audio recording using the audio_waveforms package.
class RecorderService {
  static final RecorderService _instance = RecorderService._internal();
  factory RecorderService() => _instance;
  RecorderService._internal();

  final RecorderController _recorderController = RecorderController();

  bool _isInitialized = false;
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription<Duration>? _durationSubscription;

  final StreamController<bool> _isRecordingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _recordingDurationController =
      StreamController<Duration>.broadcast();

  Stream<bool> get isRecordingStream => _isRecordingController.stream;
  Stream<Duration> get recordingDurationStream =>
      _recordingDurationController.stream;

  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  RecorderController get recorderController => _recorderController;

  /// Initialize the recording service (idempotent - safe to call multiple times)
  Future<void> initialize() async {
    if (_isInitialized) return;

    _recorderController
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100
      ..bitRate = 64000;

    _isInitialized = true;

    if (kDebugMode) {
      print('RecorderService: Initialized');
    }
  }

  /// Check and request microphone permission
  Future<bool> checkMicrophonePermission() => _ensurePermission();

  Future<bool> _ensurePermission() async {
    final hasPermission = await _recorderController.checkPermission();
    if (hasPermission) return true;

    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Start recording audio
  Future<String?> startRecording() async {
    try {
      if (_isRecording) {
        return _currentRecordingPath;
      }

      // Ensure permission
      if (!await checkMicrophonePermission()) {
        throw Exception('Microphone permission not granted');
      }

      await initialize();

      // Create audio directory and file path
      final directory = await getTemporaryDirectory();
      final audioDir = Directory('${directory.path}/journal_audio');
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioPath = '${audioDir.path}/audio_$timestamp.aac';

      await _recorderController.record(path: audioPath);

      // Update state
      _isRecording = true;
      _currentRecordingPath = audioPath;
      _recordingStartTime = DateTime.now();
      _recordingDuration = Duration.zero;

      // Notify listeners
      _isRecordingController.add(true);
      _recordingDurationController.add(Duration.zero);

      _durationSubscription?.cancel();
      _durationSubscription = _recorderController.onCurrentDuration.listen((
        duration,
      ) {
        _recordingDuration = duration;
        _recordingDurationController.add(duration);
      });

      if (kDebugMode) {
        print('RecorderService: Started recording to $audioPath');
      }

      return audioPath;
    } catch (e) {
      if (kDebugMode) {
        print('RecorderService: Error starting recording: $e');
      }
      rethrow;
    }
  }

  /// Stop recording and return the audio file path
  Future<RecordingResult?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      final startedAt = _recordingStartTime ?? DateTime.now();
      final endedAt = DateTime.now();

      String? recordedPath;
      try {
        recordedPath = await _recorderController.stop();
      } finally {
        await _durationSubscription?.cancel();
        _durationSubscription = null;
      }

      final path = recordedPath ?? _currentRecordingPath;

      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _recordingDuration = Duration.zero;
      _isRecordingController.add(false);
      _recordingDurationController.add(Duration.zero);

      if (kDebugMode) {
        print('RecorderService: Stopped recording, saved to $path');
      }

      if (path == null) {
        return null;
      }

      final recordedDuration = _recorderController.recordedDuration;
      final duration = recordedDuration != Duration.zero
          ? recordedDuration
          : endedAt.difference(startedAt);

      return RecordingResult(
        path: path,
        duration: duration,
        startedAt: startedAt,
        endedAt: endedAt,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RecorderService: Error stopping recording: $e');
      }
      rethrow;
    }
  }

  /// Cancel current recording (delete file)
  Future<void> cancelRecording() async {
    try {
      if (!_isRecording) return;
      final recordingPath = _currentRecordingPath;

      // Stop recorder without emitting a finalized result
      try {
        await _recorderController.stop();
      } catch (_) {
        // Ignore stop failures when recorder is already stopped
      }

      await _durationSubscription?.cancel();
      _durationSubscription = null;

      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _recordingDuration = Duration.zero;
      _isRecordingController.add(false);
      _recordingDurationController.add(Duration.zero);

      if (recordingPath != null) {
        final file = File(recordingPath);
        if (await file.exists()) {
          await file.delete();
          if (kDebugMode) {
            print(
              'RecorderService: Cancelled recording, deleted $recordingPath',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecorderService: Error cancelling recording: $e');
      }
      rethrow;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    await cancelRecording();
    await _durationSubscription?.cancel();
    _durationSubscription = null;
    _recorderController.dispose();

    await _isRecordingController.close();
    await _recordingDurationController.close();

    if (kDebugMode) {
      print('RecorderService: Disposed');
    }
  }
}

class RecordingResult {
  final String path;
  final Duration duration;
  final DateTime startedAt;
  final DateTime endedAt;
  const RecordingResult({
    required this.path,
    required this.duration,
    required this.startedAt,
    required this.endedAt,
  });
}

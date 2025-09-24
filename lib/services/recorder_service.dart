import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Service to handle audio recording with real-time waveform visualization
class RecorderService {
  static final RecorderService _instance = RecorderService._internal();
  factory RecorderService() => _instance;
  RecorderService._internal();

  FlutterSoundRecorder? _recorder;
  RecorderController? _recorderController;

  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Duration _recordingDuration = Duration.zero;

  Timer? _recordingTimer;
  Timer? _waveUpdateTimer;

  // Waveform visualization data
  final int _numberOfWaveBars = 20;
  List<double> _currentAmplitudes = [];

  // Streams for UI updates
  final StreamController<bool> _isRecordingController =
      StreamController<bool>.broadcast();
  final StreamController<Duration> _recordingDurationController =
      StreamController<Duration>.broadcast();
  final StreamController<List<double>> _waveAmplitudesController =
      StreamController<List<double>>.broadcast();
  final StreamController<String?> _recordingPathController =
      StreamController<String?>.broadcast();

  bool _isInitialized = false;

  // Public streams
  Stream<bool> get isRecordingStream => _isRecordingController.stream;
  Stream<Duration> get recordingDurationStream =>
      _recordingDurationController.stream;
  Stream<List<double>> get waveAmplitudesStream =>
      _waveAmplitudesController.stream;
  Stream<String?> get recordingPathStream => _recordingPathController.stream;

  // Public getters
  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  String? get currentRecordingPath => _currentRecordingPath;
  List<double> get currentAmplitudes => List.from(_currentAmplitudes);

  /// Initialize the recording service (idempotent - safe to call multiple times)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _recorder = FlutterSoundRecorder();
      _recorderController = RecorderController();
      await _recorder!.openRecorder();

      _currentAmplitudes = List.filled(_numberOfWaveBars, 0.1);
      _isInitialized = true;

      if (kDebugMode) {
        print('RecorderService: Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('RecorderService: Error initializing: $e');
      }
      rethrow;
    }
  }

  /// Check and request microphone permission
  Future<bool> checkMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;

    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    return status.isGranted;
  }

  /// Start recording audio
  Future<String?> startRecording() async {
    try {
      // Check permission
      if (!await checkMicrophonePermission()) {
        throw Exception('Microphone permission not granted');
      }

      // Check if recorder is available
      if (_recorder == null) {
        await initialize();
      }

      // Create audio directory and file path
      final directory = await getTemporaryDirectory();
      final audioDir = Directory('${directory.path}/journal_audio');
      if (!audioDir.existsSync()) {
        audioDir.createSync(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final audioPath = '${audioDir.path}/audio_$timestamp.aac';

      // Start flutter_sound recorder for audio file
      await _recorder!.startRecorder(toFile: audioPath, codec: Codec.aacADTS);

      // Start waveform recording (uses internal recording)
      await _recorderController!.record();

      // Update state
      _isRecording = true;
      _currentRecordingPath = audioPath;
      _recordingStartTime = DateTime.now();
      _recordingDuration = Duration.zero;

      // Notify listeners
      _isRecordingController.add(true);
      _recordingPathController.add(audioPath);
      _recordingDurationController.add(Duration.zero);

      // Start timers
      _startRecordingTimer();
      _startWaveformUpdates();

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
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      // Stop recorders
      await _recorder?.stopRecorder();
      await _recorderController?.stop();

      // Stop timers
      _recordingTimer?.cancel();
      _waveUpdateTimer?.cancel();

      final recordingPath = _currentRecordingPath;

      // Reset state
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _recordingDuration = Duration.zero;
      _currentAmplitudes = List.filled(_numberOfWaveBars, 0.1);

      // Notify listeners
      _isRecordingController.add(false);
      _recordingPathController.add(null);
      _recordingDurationController.add(Duration.zero);
      _waveAmplitudesController.add(List.from(_currentAmplitudes));

      if (kDebugMode) {
        print('RecorderService: Stopped recording, saved to $recordingPath');
      }

      return recordingPath;
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

      // Stop recording first
      await stopRecording();

      // Delete the recorded file
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

  /// Start the recording duration timer
  void _startRecordingTimer() {
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRecording || _recordingStartTime == null) {
        timer.cancel();
        return;
      }

      _recordingDuration = DateTime.now().difference(_recordingStartTime!);
      _recordingDurationController.add(_recordingDuration);
    });
  }

  /// Start waveform visualization updates
  void _startWaveformUpdates() {
    _waveUpdateTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      _updateWaveAmplitudes();
    });
  }

  /// Update waveform amplitudes based on recorder data
  void _updateWaveAmplitudes() {
    if (_recorderController == null || !_isRecording) return;

    final waveData = _recorderController!.waveData;
    if (waveData.isEmpty) {
      _currentAmplitudes = List.filled(_numberOfWaveBars, 0.1);
      _waveAmplitudesController.add(List.from(_currentAmplitudes));
      return;
    }

    // Sample recent waveform data
    final recentData = waveData.length > 50
        ? waveData.sublist(waveData.length - 50)
        : waveData;

    // Generate amplitudes based on actual data with some randomization for visual appeal
    final random = math.Random();
    _currentAmplitudes = List.generate(_numberOfWaveBars, (i) {
      final baseAmplitude = recentData.isNotEmpty
          ? recentData[i % recentData.length].abs()
          : 0.1;
      final randomVariation = 0.2 + (random.nextDouble() * 0.8);
      return (baseAmplitude * randomVariation).clamp(0.1, 1.0);
    });

    _waveAmplitudesController.add(List.from(_currentAmplitudes));
  }

  /// Get recording controller for external waveform display
  RecorderController? get recorderController => _recorderController;

  /// Clean up resources
  Future<void> dispose() async {
    await stopRecording();
    await _recorder?.closeRecorder();
    _recorderController?.dispose();

    await _isRecordingController.close();
    await _recordingDurationController.close();
    await _waveAmplitudesController.close();
    await _recordingPathController.close();

    if (kDebugMode) {
      print('RecorderService: Disposed');
    }
  }
}

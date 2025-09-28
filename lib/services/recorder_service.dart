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

  // Waveform visualization configuration & buffers
  final int _numberOfWaveBars = 20;
  // Public-facing (already normalized + smoothed) amplitudes 0..1
  List<double> _currentAmplitudes = [];
  // Internal smoothing buffer (EMA)
  List<double> _smoothedAmplitudes = [];
  static const double _emaAlpha =
      0.45; // 0 < alpha <= 1, higher = more reactive
  static const double _minVisualFloor =
      0.05; // avoid bars collapsing completely

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

      _currentAmplitudes = List.filled(_numberOfWaveBars, _minVisualFloor);
      _smoothedAmplitudes = List.filled(_numberOfWaveBars, _minVisualFloor);
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
  Future<RecordingResult?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      // Capture metadata before we reset state
      final recordingPath = _currentRecordingPath;
      final startedAt = _recordingStartTime;
      final finalDuration = _recordingDuration;

      // Stop recorders
      await _recorder?.stopRecorder();
      await _recorderController?.stop();

      // Stop timers
      _recordingTimer?.cancel();
      _waveUpdateTimer?.cancel();

      // Reset state AFTER capture
      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _recordingDuration = Duration.zero;
      _currentAmplitudes = List.filled(_numberOfWaveBars, _minVisualFloor);
      _smoothedAmplitudes = List.filled(_numberOfWaveBars, _minVisualFloor);

      // Notify listeners of reset
      _isRecordingController.add(false);
      _recordingPathController.add(null);
      _recordingDurationController.add(Duration.zero);
      _waveAmplitudesController.add(List.from(_currentAmplitudes));

      if (kDebugMode) {
        print('RecorderService: Stopped recording, saved to $recordingPath');
      }

      return (recordingPath != null && startedAt != null)
          ? RecordingResult(
              path: recordingPath,
              duration: finalDuration,
              startedAt: startedAt,
              endedAt: DateTime.now(),
            )
          : null;
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

      // Stop low-level recorders without emitting a finalized result
      await _recorder?.stopRecorder();
      await _recorderController?.stop();

      _recordingTimer?.cancel();
      _waveUpdateTimer?.cancel();

      _isRecording = false;
      _currentRecordingPath = null;
      _recordingStartTime = null;
      _recordingDuration = Duration.zero;
      _currentAmplitudes = List.filled(_numberOfWaveBars, _minVisualFloor);
      _smoothedAmplitudes = List.filled(_numberOfWaveBars, _minVisualFloor);
      _isRecordingController.add(false);
      _recordingPathController.add(null);
      _recordingDurationController.add(Duration.zero);
      _waveAmplitudesController.add(List.from(_currentAmplitudes));

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

  /// Compute normalized & smoothed waveform amplitudes.
  /// Steps:
  /// 1. Take a capped sliding window of recent raw samples.
  /// 2. Bucket into N segments (N = number of bars) and compute RMS per bucket.
  /// 3. Normalize by max RMS (gives relative energy 0..1).
  /// 4. Apply exponential moving average for temporal smoothing.
  /// 5. Enforce a visual floor so silence still shows subtle motion.
  void _updateWaveAmplitudes() {
    if (_recorderController == null || !_isRecording) return;

    final data = _recorderController!.waveData;
    if (data.isEmpty) {
      _currentAmplitudes = List.filled(_numberOfWaveBars, _minVisualFloor);
      _smoothedAmplitudes = List.filled(_numberOfWaveBars, _minVisualFloor);
      _waveAmplitudesController.add(List.from(_currentAmplitudes));
      return;
    }

    // Cap window size for performance & responsiveness
    const int maxWindow = 400; // Tunable
    final window = data.length > maxWindow
        ? data.sublist(data.length - maxWindow)
        : data;

    final bucketCount = _numberOfWaveBars;
    final bucketSize = (window.length / bucketCount).floor().clamp(
      1,
      window.length,
    );
    final List<double> bucketRms = List.filled(bucketCount, 0.0);

    for (int i = 0; i < bucketCount; i++) {
      final start = i * bucketSize;
      if (start >= window.length) break;
      final end = math.min(start + bucketSize, window.length);
      if (end <= start) continue;
      double sumSquares = 0.0;
      for (int j = start; j < end; j++) {
        final v = window[j];
        sumSquares += v * v;
      }
      bucketRms[i] = math.sqrt(sumSquares / (end - start));
    }

    double maxVal = 0.0001;
    for (final v in bucketRms) {
      if (v > maxVal) maxVal = v;
    }

    if (_smoothedAmplitudes.length != bucketCount) {
      _smoothedAmplitudes = List.filled(bucketCount, _minVisualFloor);
    }

    for (int i = 0; i < bucketCount; i++) {
      final normalized = (bucketRms[i] / maxVal).clamp(0.0, 1.0);
      final target = normalized < _minVisualFloor
          ? _minVisualFloor
          : normalized;
      final prev = _smoothedAmplitudes[i];
      final smoothed = prev + _emaAlpha * (target - prev);
      _smoothedAmplitudes[i] = smoothed.clamp(_minVisualFloor, 1.0);
    }

    _currentAmplitudes = List.from(_smoothedAmplitudes);
    _waveAmplitudesController.add(_currentAmplitudes);
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

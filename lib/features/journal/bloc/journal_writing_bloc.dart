import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../services/player_service.dart';
import '../../../services/recorder_service.dart';
import '../../../services/journal_mood_integration.dart';
import 'journal_writing_event.dart';
import 'journal_writing_state.dart';

class JournalWritingBloc
    extends Bloc<JournalWritingEvent, JournalWritingState> {
  final PlayerService _playerService;
  final RecorderService _recorderService;
  final JournalMoodIntegration _moodIntegration;
  final ImagePicker _imagePicker;

  StreamSubscription? _recordingSubscription;
  StreamSubscription? _waveformSubscription;
  StreamSubscription? _playerSubscription;

  JournalWritingBloc({
    PlayerService? playerService,
    RecorderService? recorderService,
    JournalMoodIntegration? moodIntegration,
    ImagePicker? imagePicker,
  }) : _playerService = playerService ?? PlayerService(),
       _recorderService = recorderService ?? RecorderService(),
       _moodIntegration = moodIntegration ?? JournalMoodIntegration(),
       _imagePicker = imagePicker ?? ImagePicker(),
       super(const JournalWritingState()) {
    on<JournalWritingInitialized>(_onInitialized);
    on<TitleChanged>(_onTitleChanged);
    on<ContentChanged>(_onContentChanged);
    on<MoodSelected>(_onMoodSelected);
    on<MoodContextChanged>(_onMoodContextChanged);
    on<ImagePickerRequested>(_onImagePickerRequested);
    on<CameraRequested>(_onCameraRequested);
    on<ImageRemoved>(_onImageRemoved);
    on<RecordingStartRequested>(_onRecordingStartRequested);
    on<RecordingStopRequested>(_onRecordingStopRequested);
    on<RecordingCancelRequested>(_onRecordingCancelRequested);
    on<AudioRecordingRemoved>(_onAudioRecordingRemoved);
    on<AudioPlaybackToggled>(_onAudioPlaybackToggled);
    on<JournalSaveRequested>(_onJournalSaveRequested);
    on<JournalWritingReset>(_onJournalWritingReset);
    on<RecordingStatusChanged>(_onRecordingStatusChanged);
    on<WaveformAmplitudesChanged>(_onWaveformAmplitudesChanged);
    on<AudioPlaybackChanged>(_onAudioPlaybackChanged);
    on<RecordingDurationChanged>(_onRecordingDurationChanged);
  }

  Future<void> _onInitialized(
    JournalWritingInitialized event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      // Initialize services
      await _playerService.initialize();
      await _recorderService.initialize();

      // Subscribe to recorder streams
      _recordingSubscription =
          _recorderService.isRecordingStream.listen((isRecording) {
        if (!isClosed) {
          add(RecordingStatusChanged(isRecording));
        }
      });

      _waveformSubscription =
          _recorderService.waveAmplitudesStream.listen((amplitudes) {
        if (!isClosed) {
          add(WaveformAmplitudesChanged(amplitudes));
        }
      });

      // Subscribe to player streams
      _playerSubscription =
          _playerService.currentlyPlayingStream.listen((path) {
        if (!isClosed) {
          add(AudioPlaybackChanged(path));
        }
      });

      if (kDebugMode) {
        print('JournalWritingBloc: Initialized successfully');
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to initialize: $e'));
    }
  }

  void _onTitleChanged(TitleChanged event, Emitter<JournalWritingState> emit) {
    emit(
      state.copyWith(
        title: event.title,
        hasUnsavedChanges: true,
        clearError: true,
      ),
    );
  }

  void _onContentChanged(
    ContentChanged event,
    Emitter<JournalWritingState> emit,
  ) {
    emit(
      state.copyWith(
        content: event.content,
        hasUnsavedChanges: true,
        clearError: true,
      ),
    );
  }

  void _onMoodSelected(MoodSelected event, Emitter<JournalWritingState> emit) {
    emit(
      state.copyWith(
        selectedMood: event.mood,
        hasUnsavedChanges: true,
        clearError: true,
      ),
    );
  }

  void _onMoodContextChanged(
    MoodContextChanged event,
    Emitter<JournalWritingState> emit,
  ) {
    emit(
      state.copyWith(
        moodContext: event.context,
        hasUnsavedChanges: true,
        clearError: true,
      ),
    );
  }

  Future<void> _onImagePickerRequested(
    ImagePickerRequested event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        final updatedImages = List<XFile>.from(state.selectedImages)
          ..addAll(images);
        emit(
          state.copyWith(
            selectedImages: updatedImages,
            hasUnsavedChanges: true,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to pick images: $e'));
    }
  }

  Future<void> _onCameraRequested(
    CameraRequested event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          emit(state.copyWith(error: 'Camera permission denied'));
          return;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        final updatedImages = List<XFile>.from(state.selectedImages)
          ..add(image);
        emit(
          state.copyWith(
            selectedImages: updatedImages,
            hasUnsavedChanges: true,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: 'Failed to take photo: $e'));
    }
  }

  void _onImageRemoved(ImageRemoved event, Emitter<JournalWritingState> emit) {
    if (event.index >= 0 && event.index < state.selectedImages.length) {
      final updatedImages = List<XFile>.from(state.selectedImages)
        ..removeAt(event.index);
      emit(
        state.copyWith(
          selectedImages: updatedImages,
          hasUnsavedChanges: true,
          clearError: true,
        ),
      );
    }
  }

  Future<void> _onRecordingStartRequested(
    RecordingStartRequested event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      if (state.isRecording) return;

      final recordingPath = await _recorderService.startRecording();
      if (recordingPath != null) {
        emit(state.copyWith(isRecording: true, clearError: true));

        // Listen to recording duration updates
        final durationSubscription =
            _recorderService.recordingDurationStream.listen((duration) {
          if (!isClosed) {
            add(RecordingDurationChanged(duration));
          }
        });

        // Cancel subscription when recording stops
        _recorderService.isRecordingStream
            .where((isRecording) => !isRecording)
            .take(1)
            .listen((_) {
              durationSubscription.cancel();
            });
      }
    } catch (e) {
      emit(
        state.copyWith(
          isRecording: false,
          error: 'Failed to start recording: $e',
        ),
      );
    }
  }

  Future<void> _onRecordingStopRequested(
    RecordingStopRequested event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      if (!state.isRecording) return;

      final recordingPath = await _recorderService.stopRecording();
      if (recordingPath != null) {
        // Add the recording to the list
        final audioData = {
          'path': recordingPath,
          'duration': state.recordingDuration.inMilliseconds,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };

        final updatedRecordings = List<Map<String, dynamic>>.from(
          state.audioRecordings,
        )..add(audioData);

        emit(
          state.copyWith(
            audioRecordings: updatedRecordings,
            isRecording: false,
            recordingDuration: Duration.zero,
            waveAmplitudes: [],
            hasUnsavedChanges: true,
            clearError: true,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          isRecording: false,
          error: 'Failed to stop recording: $e',
        ),
      );
    }
  }

  Future<void> _onRecordingCancelRequested(
    RecordingCancelRequested event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      if (!state.isRecording) return;

      await _recorderService.cancelRecording();
      emit(
        state.copyWith(
          isRecording: false,
          recordingDuration: Duration.zero,
          waveAmplitudes: [],
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRecording: false,
          error: 'Failed to cancel recording: $e',
        ),
      );
    }
  }

  void _onAudioRecordingRemoved(
    AudioRecordingRemoved event,
    Emitter<JournalWritingState> emit,
  ) {
    if (event.index >= 0 && event.index < state.audioRecordings.length) {
      final recording = state.audioRecordings[event.index];
      final recordingPath = recording['path'] as String?;

      // Stop playback if this audio is currently playing
      if (recordingPath != null &&
          state.currentlyPlayingAudio == recordingPath) {
        _playerService.stop();
      }

      // Delete the file
      if (recordingPath != null) {
        final file = File(recordingPath);
        file.delete().catchError((e) {
          if (kDebugMode) {
            print('Failed to delete audio file: $e');
          }
          return file; // Return the file to satisfy the catchError handler
        });
      }

      final updatedRecordings = List<Map<String, dynamic>>.from(
        state.audioRecordings,
      )..removeAt(event.index);

      emit(
        state.copyWith(
          audioRecordings: updatedRecordings,
          hasUnsavedChanges: true,
          clearError: true,
        ),
      );
    }
  }

  Future<void> _onAudioPlaybackToggled(
    AudioPlaybackToggled event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      await _playerService.playAudio(event.audioPath);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to play audio: $e'));
    }
  }

  Future<void> _onJournalSaveRequested(
    JournalSaveRequested event,
    Emitter<JournalWritingState> emit,
  ) async {
    if (!state.canSave) return;

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      // Convert XFile paths to string paths
      final imagePaths = state.selectedImages
          .map((xfile) => xfile.path)
          .toList();

      // Save journal entry
      await _moodIntegration.saveJournalWithMoodContext(
        title: state.title.trim().isEmpty ? 'Untitled' : state.title.trim(),
        content: state.content.trim(),
        entryMood: state.selectedMood,
        entryMoodContext: state.moodContext,
        imagePaths: imagePaths,
        audioRecordings: state.audioRecordings,
      );

      emit(state.copyWith(isSaving: false, hasUnsavedChanges: false));

      if (kDebugMode) {
        print('JournalWritingBloc: Journal saved successfully');
      }
    } catch (e) {
      emit(
        state.copyWith(isSaving: false, error: 'Failed to save journal: $e'),
      );
    }
  }

  void _onJournalWritingReset(
    JournalWritingReset event,
    Emitter<JournalWritingState> emit,
  ) {
    // Stop any ongoing recording or playback
    if (state.isRecording) {
      _recorderService.cancelRecording();
    }
    _playerService.stop();

    // Reset to initial state
    emit(const JournalWritingState());
  }

  void _onRecordingStatusChanged(
    RecordingStatusChanged event,
    Emitter<JournalWritingState> emit,
  ) {
    if (!event.isRecording) {
      add(RecordingStopRequested());
    }
  }

  void _onWaveformAmplitudesChanged(
    WaveformAmplitudesChanged event,
    Emitter<JournalWritingState> emit,
  ) {
    emit(state.copyWith(waveAmplitudes: event.amplitudes));
  }

  void _onAudioPlaybackChanged(
    AudioPlaybackChanged event,
    Emitter<JournalWritingState> emit,
  ) {
    emit(
      state.copyWith(
        currentlyPlayingAudio: event.audioPath,
        clearCurrentlyPlaying: event.audioPath == null,
      ),
    );
  }

  void _onRecordingDurationChanged(
    RecordingDurationChanged event,
    Emitter<JournalWritingState> emit,
  ) {
    emit(state.copyWith(recordingDuration: event.duration));
  }

  @override
  Future<void> close() async {
    await _recordingSubscription?.cancel();
    await _waveformSubscription?.cancel();
    await _playerSubscription?.cancel();
    return super.close();
  }
}

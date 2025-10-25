import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

import '../../../services/player_service.dart';
import '../../../services/recorder_service.dart';
import '../../../services/journal_mood_integration.dart';
import '../../../services/media_store.dart';
import 'journal_writing_event.dart';
import 'journal_writing_state.dart';

class JournalWritingBloc
    extends Bloc<JournalWritingEvent, JournalWritingState> {
  final PlayerService _playerService;
  final RecorderService _recorderService;
  final JournalMoodIntegration _moodIntegration;
  final ImagePicker _imagePicker;

  StreamSubscription? _recordingSubscription;
  StreamSubscription? _playerSubscription;

  JournalWritingBloc({
    required PlayerService playerService,
    required RecorderService recorderService,
    required JournalMoodIntegration moodIntegration,
    ImagePicker? imagePicker,
  }) : _playerService = playerService,
       _recorderService = recorderService,
       _moodIntegration = moodIntegration,
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
    on<ExistingImageLoaded>(_onExistingImageLoaded);
    on<RecordingStartRequested>(_onRecordingStartRequested);
    on<RecordingStopRequested>(_onRecordingStopRequested);
    on<RecordingCancelRequested>(_onRecordingCancelRequested);
    on<AudioRecordingRemoved>(_onAudioRecordingRemoved);
    on<AudioPlaybackToggled>(_onAudioPlaybackToggled);
    on<JournalSaveRequested>(_onJournalSaveRequested);
    on<JournalWritingReset>(_onJournalWritingReset);
    // Removed RecordingStatusChanged indirection; explicit events control lifecycle.
    // Removed live waveform support per simplification request.
    on<AudioPlaybackChanged>(_onAudioPlaybackChanged);
    on<RecordingDurationChanged>(_onRecordingDurationChanged);
  }

  // Public accessors (read-only) for UI helpers needing services
  PlayerService get playerService => _playerService;
  RecorderService get recorderService => _recorderService;

  // Convenience passthrough to obtain (and lazily prepare) a waveform controller
  // for a given audio file path without exposing the entire player service API.
  PlayerController getWaveformController(String path) =>
      _playerService.getWaveformController(path);

  Future<void> _onInitialized(
    JournalWritingInitialized event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      // Initialize services
      await _playerService.initialize();
      await _recorderService.initialize();

      // Subscribe to recorder streams (duration updates only).
      _recordingSubscription = _recorderService.isRecordingStream.listen(
        (_) {},
      );

      // Live waveform subscription removed.

      // Subscribe to player streams
      _playerSubscription = _playerService.currentlyPlayingStream.listen((
        path,
      ) {
        if (!isClosed) {
          add(AudioPlaybackChanged(path));
        }
      });

      if (kDebugMode) {
        print('JournalWritingBloc: Initialized successfully');
      }
    } catch (e) {
      emit(
        state.copyWith(
          failure: JournalFailure.unknown('Failed to initialize: $e'),
        ),
      );
    }
  }

  void _onTitleChanged(TitleChanged event, Emitter<JournalWritingState> emit) {
    emit(
      state.copyWith(
        title: event.title,
        hasUnsavedChanges: true,
        failure: null,
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
        failure: null,
      ),
    );
  }

  void _onMoodSelected(MoodSelected event, Emitter<JournalWritingState> emit) {
    emit(
      state.copyWith(
        selectedMood: event.mood,
        hasUnsavedChanges: true,
        failure: null,
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
        failure: null,
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
            failure: null,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          failure: JournalFailure.unknown('Failed to pick images: $e'),
        ),
      );
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
          emit(
            state.copyWith(
              failure: const JournalFailure.validation(
                'Camera permission denied',
              ),
            ),
          );
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
            failure: null,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          failure: JournalFailure.unknown('Failed to take photo: $e'),
        ),
      );
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
          failure: null,
        ),
      );
    }
  }

  void _onExistingImageLoaded(
    ExistingImageLoaded event,
    Emitter<JournalWritingState> emit,
  ) async {
    try {
      // Resolve the image path (convert relative to absolute if needed)
      final resolvedPath = await MediaStore.instance.resolvePath(
        event.imagePath,
      );

      // Convert resolved path to XFile
      final xFile = XFile(resolvedPath);
      final updatedImages = List<XFile>.from(state.selectedImages)..add(xFile);
      emit(
        state.copyWith(
          selectedImages: updatedImages,
          hasUnsavedChanges:
              false, // Don't mark as unsaved when loading existing
          failure: null,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JournalWritingBloc: Failed to load image: $e');
      }
      emit(
        state.copyWith(
          failure: JournalFailure.unknown('Failed to load image: $e'),
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
        emit(state.copyWith(isRecording: true, failure: null));

        // Listen to recording duration updates
        final durationSubscription = _recorderService.recordingDurationStream
            .listen((duration) {
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
          failure: JournalFailure.unknown('Failed to start recording: $e'),
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

      final result = await _recorderService.stopRecording();
      if (result != null) {
        final audioData = {
          'path': result.path,
          'duration': result.duration.inMilliseconds,
          'timestamp': result.startedAt.millisecondsSinceEpoch,
        };
        final updatedRecordings = List<Map<String, dynamic>>.from(
          state.audioRecordings,
        )..add(audioData);
        emit(
          state.copyWith(
            audioRecordings: updatedRecordings,
            isRecording: false,
            recordingDuration: Duration.zero,
            hasUnsavedChanges: true,
            failure: null,
          ),
        );
      } else {
        emit(state.copyWith(isRecording: false));
      }
    } catch (e) {
      emit(
        state.copyWith(
          isRecording: false,
          failure: JournalFailure.unknown('Failed to stop recording: $e'),
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
          failure: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isRecording: false,
          failure: JournalFailure.unknown('Failed to cancel recording: $e'),
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
          failure: null,
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
      emit(
        state.copyWith(
          failure: JournalFailure.unknown('Failed to play audio: $e'),
        ),
      );
    }
  }

  Future<void> _onJournalSaveRequested(
    JournalSaveRequested event,
    Emitter<JournalWritingState> emit,
  ) async {
    if (!state.canSave) return;

    emit(state.copyWith(saveStatus: JournalSaveStatus.saving, failure: null));

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

      emit(
        state.copyWith(
          saveStatus: JournalSaveStatus.success,
          hasUnsavedChanges: false,
        ),
      );

      if (kDebugMode) {
        print('JournalWritingBloc: Journal saved successfully');
      }
    } catch (e) {
      emit(
        state.copyWith(
          saveStatus: JournalSaveStatus.failure,
          failure: JournalFailure.storage('Failed to save journal: $e'),
        ),
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

  // Live waveform event handler removed.

  void _onAudioPlaybackChanged(
    AudioPlaybackChanged event,
    Emitter<JournalWritingState> emit,
  ) {
    emit(state.copyWith(currentlyPlayingAudio: event.audioPath));
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
    await _playerSubscription?.cancel();
    return super.close();
  }
}

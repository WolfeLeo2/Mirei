import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';

part 'journal_writing_state.freezed.dart';

enum JournalSaveStatus { idle, saving, success, failure }

@freezed
abstract class JournalFailure with _$JournalFailure {
  const factory JournalFailure.validation(String message) = _ValidationFailure;
  const factory JournalFailure.storage(String message) = _StorageFailure;
  const factory JournalFailure.network(String message) = _NetworkFailure;
  const factory JournalFailure.unknown(String message) = _UnknownFailure;
}

@freezed
abstract class JournalWritingState with _$JournalWritingState {
  const JournalWritingState._();
  const factory JournalWritingState({
    @Default('') String title,
    @Default('') String content,
    String? selectedMood,
    String? moodContext,
    @Default(<XFile>[]) List<XFile> selectedImages,
    // audioRecordings: List<Map>{ path: String, duration: int(ms), timestamp: int(ms) }
    //forced comment
    @Default(<Map<String, dynamic>>[])
    List<Map<String, dynamic>> audioRecordings,
    @Default(false) bool isRecording,
    @Default(Duration.zero) Duration recordingDuration,
    @Default(<double>[]) List<double> waveAmplitudes,
    String? currentlyPlayingAudio,
    @Default(JournalSaveStatus.idle) JournalSaveStatus saveStatus,
    JournalFailure? failure,
    @Default(false) bool hasUnsavedChanges,
  }) = _JournalWritingState;

  bool get isSaving => saveStatus == JournalSaveStatus.saving;
  bool get canSaveCore =>
      title.trim().isNotEmpty ||
      content.trim().isNotEmpty ||
      selectedImages.isNotEmpty ||
      audioRecordings.isNotEmpty;
  bool get canSave =>
      canSaveCore &&
      !isSaving &&
      !isRecording &&
      saveStatus != JournalSaveStatus.success;
  String? get errorMessage => failure?.when(
    validation: (m) => m,
    storage: (m) => m,
    network: (m) => m,
    unknown: (m) => m,
  );
}

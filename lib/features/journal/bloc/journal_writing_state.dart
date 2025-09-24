import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

class JournalWritingState extends Equatable {
  final String title;
  final String content;
  final String? selectedMood;
  final String? moodContext;
  final List<XFile> selectedImages;
  final List<Map<String, dynamic>> audioRecordings;
  final bool isRecording;
  final Duration recordingDuration;
  final List<double> waveAmplitudes;
  final String? currentlyPlayingAudio;
  final bool isSaving;
  final String? error;
  final bool hasUnsavedChanges;

  const JournalWritingState({
    this.title = '',
    this.content = '',
    this.selectedMood,
    this.moodContext,
    this.selectedImages = const [],
    this.audioRecordings = const [],
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.waveAmplitudes = const [],
    this.currentlyPlayingAudio,
    this.isSaving = false,
    this.error,
    this.hasUnsavedChanges = false,
  });

  JournalWritingState copyWith({
    String? title,
    String? content,
    String? selectedMood,
    String? moodContext,
    List<XFile>? selectedImages,
    List<Map<String, dynamic>>? audioRecordings,
    bool? isRecording,
    Duration? recordingDuration,
    List<double>? waveAmplitudes,
    String? currentlyPlayingAudio,
    bool? isSaving,
    String? error,
    bool? hasUnsavedChanges,
    bool clearError = false,
    bool clearCurrentlyPlaying = false,
  }) {
    return JournalWritingState(
      title: title ?? this.title,
      content: content ?? this.content,
      selectedMood: selectedMood ?? this.selectedMood,
      moodContext: moodContext ?? this.moodContext,
      selectedImages: selectedImages ?? this.selectedImages,
      audioRecordings: audioRecordings ?? this.audioRecordings,
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      waveAmplitudes: waveAmplitudes ?? this.waveAmplitudes,
      currentlyPlayingAudio: clearCurrentlyPlaying
          ? null
          : (currentlyPlayingAudio ?? this.currentlyPlayingAudio),
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }

  bool get canSave =>
      (title.trim().isNotEmpty ||
          content.trim().isNotEmpty ||
          selectedImages.isNotEmpty ||
          audioRecordings.isNotEmpty) &&
      !isSaving &&
      !isRecording;

  @override
  List<Object?> get props => [
    title,
    content,
    selectedMood,
    moodContext,
    selectedImages,
    audioRecordings,
    isRecording,
    recordingDuration,
    waveAmplitudes,
    currentlyPlayingAudio,
    isSaving,
    error,
    hasUnsavedChanges,
  ];
}

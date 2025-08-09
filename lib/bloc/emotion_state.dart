part of 'emotion_bloc.dart';

@freezed
abstract class EmotionState with _$EmotionState {
  const factory EmotionState.initial() = EmotionInitial;
  const factory EmotionState.loadInProgress() = EmotionLoadInProgress;
  const factory EmotionState.loadSuccess({
    required List<String> allEmotions,
    required String selectedMood,
  }) = EmotionLoadSuccess;
  const factory EmotionState.loadFailure(String error) = EmotionLoadFailure;
}

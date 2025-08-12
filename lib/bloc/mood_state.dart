part of 'mood_bloc.dart';

@freezed
abstract class MoodState with _$MoodState {
  const factory MoodState.initial() = MoodInitial;
  const factory MoodState.loadInProgress() = MoodLoadInProgress;
  const factory MoodState.loadSuccess({
    required List<String> allMoods,
    required String selectedMood,
  }) = MoodLoadSuccess;
  const factory MoodState.loadFailure(String error) = MoodLoadFailure;
}

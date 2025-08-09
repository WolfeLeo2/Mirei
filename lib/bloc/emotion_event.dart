part of 'emotion_bloc.dart';

@freezed
abstract class EmotionEvent with _$EmotionEvent {
  const factory EmotionEvent.loadInitialMood() = LoadInitialMood;
  const factory EmotionEvent.moodSelected(String mood) = MoodSelected;
}

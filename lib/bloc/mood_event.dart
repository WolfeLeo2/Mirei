part of 'mood_bloc.dart';

@freezed
abstract class MoodEvent with _$MoodEvent {
  const factory MoodEvent.loadInitialMood() = LoadInitialMood;
  const factory MoodEvent.moodSelected(String mood) = MoodSelected;
}

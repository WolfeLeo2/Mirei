import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../repositories/mood_repository.dart';

part 'emotion_event.dart';
part 'emotion_state.dart';
part 'emotion_bloc.freezed.dart';

class EmotionBloc extends Bloc<EmotionEvent, EmotionState> {
  final MoodRepository _moodRepository;

  // This static list defines the available emotions.
  // In a more dynamic app, this could also come from the repository.
  static const List<String> _emotions = [
    'Angelic', 'Sorry', 'Excited', 'Embarrassed', 'Happy',
    'Romantic', 'Neutral', 'Sad', 'Silly',
  ];

  EmotionBloc({required MoodRepository moodRepository})
      : _moodRepository = moodRepository,
        super(const EmotionState.initial()) {
    on<LoadInitialMood>(_onLoadInitialMood);
    on<MoodSelected>(_onMoodSelected);
  }

  Future<void> _onLoadInitialMood(
      LoadInitialMood event, Emitter<EmotionState> emit) async {
    emit(const EmotionState.loadInProgress());
    try {
      final todaysMood = await _moodRepository.getTodaysMood();
      // Default to 'Neutral' if no mood is set for the day.
      final initialMood = todaysMood?.mood ?? 'Neutral';
      emit(EmotionState.loadSuccess(
        allEmotions: _emotions,
        selectedMood: initialMood,
      ));
    } catch (e) {
      emit(EmotionState.loadFailure(e.toString()));
    }
  }

  Future<void> _onMoodSelected(
      MoodSelected event, Emitter<EmotionState> emit) async {
    final currentState = state;
    if (currentState is EmotionLoadSuccess) {
      // Immediately update the UI with the new selection.
      emit(EmotionState.loadSuccess(
        allEmotions: currentState.allEmotions,
        selectedMood: event.mood,
      ));
      try {
        // Save the mood in the background.
        await _moodRepository.saveMood(event.mood);
        // You could emit a success state here if needed, but for a simple
        // selection, updating the UI instantly is often enough.
      } catch (e) {
        // If saving fails, emit a failure state. You could also revert
        // the UI to the previous state if desired.
        emit(EmotionState.loadFailure("Failed to save mood: ${e.toString()}"));
      }
    }
  }
}

import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../repositories/mood_repository.dart';

part 'mood_event.dart';
part 'mood_state.dart';
part 'mood_bloc.freezed.dart';

class MoodBloc extends Bloc<MoodEvent, MoodState> {
  final MoodRepository _moodRepository;

  // This static list defines the available Moods.
  // In a more dynamic app, this could also come from the repository.
  static const List<String> _moods = [
    'Happy',
    'Cutesy',
    'Shocked',
    'Neutral',
    'Awkward',
    'Disappointed',
    'Sad',
    'Angry',
    'Worried',
    'Tired',
  ];

  MoodBloc({required MoodRepository moodRepository})
    : _moodRepository = moodRepository,
      super(const MoodState.initial()) {
    on<LoadInitialMood>(_onLoadInitialMood);
    on<MoodSelected>(_onMoodSelected);
  }

  Future<void> _onLoadInitialMood(
    LoadInitialMood event,
    Emitter<MoodState> emit,
  ) async {
    emit(const MoodState.loadInProgress());
    try {
      final todaysMood = await _moodRepository.getTodaysMood();
      // Default to 'Neutral' if no mood is set for the day.
      final initialMood = todaysMood?.mood ?? 'Neutral';
      emit(MoodState.loadSuccess(allMoods: _moods, selectedMood: initialMood));
    } catch (e) {
      emit(MoodState.loadFailure(e.toString()));
    }
  }

  Future<void> _onMoodSelected(
    MoodSelected event,
    Emitter<MoodState> emit,
  ) async {
    final currentState = state;
    if (currentState is MoodLoadSuccess) {
      // Immediately update the UI with the new selection.
      emit(
        MoodState.loadSuccess(
          allMoods: currentState.allMoods,
          selectedMood: event.mood,
        ),
      );
      try {
        // Save the mood in the background.
        await _moodRepository.saveMood(event.mood);
        // You could emit a success state here if needed, but for a simple
        // selection, updating the UI instantly is often enough.
      } catch (e) {
        // If saving fails, emit a failure state. You could also revert
        // the UI to the previous state if desired.
        emit(MoodState.loadFailure("Failed to save mood: ${e.toString()}"));
      }
    }
  }
}

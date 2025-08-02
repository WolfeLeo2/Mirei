import 'package:bloc/bloc.dart';

part 'emotion_event.dart';
part 'emotion_state.dart';

class EmotionBloc extends Bloc<EmotionEvent, EmotionState> {
  EmotionBloc() : super(EmotionInitial()) {
    on<EmotionSelected>((event, emit) {
      emit(EmotionLoadSuccess(event.selectedIndex));
    });
  }
}

part of 'emotion_bloc.dart';

abstract class EmotionEvent {}

class EmotionSelected extends EmotionEvent {
  final int selectedIndex;

  EmotionSelected(this.selectedIndex);
}

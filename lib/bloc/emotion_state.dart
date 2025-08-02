part of 'emotion_bloc.dart';

abstract class EmotionState {}

class EmotionInitial extends EmotionState {}

class EmotionLoadSuccess extends EmotionState {
  final int selectedIndex;

  EmotionLoadSuccess(this.selectedIndex);
}

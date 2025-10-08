import 'package:equatable/equatable.dart';

abstract class JournalWritingEvent extends Equatable {
  const JournalWritingEvent();

  @override
  List<Object?> get props => [];
}

class JournalWritingInitialized extends JournalWritingEvent {
  const JournalWritingInitialized();
}

class TitleChanged extends JournalWritingEvent {
  final String title;

  const TitleChanged(this.title);

  @override
  List<Object> get props => [title];
}

class ContentChanged extends JournalWritingEvent {
  final String content;

  const ContentChanged(this.content);

  @override
  List<Object> get props => [content];
}

class MoodSelected extends JournalWritingEvent {
  final String mood;

  const MoodSelected(this.mood);

  @override
  List<Object> get props => [mood];
}

class MoodContextChanged extends JournalWritingEvent {
  final String? context;

  const MoodContextChanged(this.context);

  @override
  List<Object?> get props => [context];
}

class ImagePickerRequested extends JournalWritingEvent {
  const ImagePickerRequested();
}

class CameraRequested extends JournalWritingEvent {
  const CameraRequested();
}

class ImageRemoved extends JournalWritingEvent {
  final int index;

  const ImageRemoved(this.index);

  @override
  List<Object> get props => [index];
}

class RecordingStartRequested extends JournalWritingEvent {
  const RecordingStartRequested();
}

class RecordingStopRequested extends JournalWritingEvent {
  const RecordingStopRequested();
}

class RecordingCancelRequested extends JournalWritingEvent {
  const RecordingCancelRequested();
}

class AudioRecordingRemoved extends JournalWritingEvent {
  final int index;

  const AudioRecordingRemoved(this.index);

  @override
  List<Object> get props => [index];
}

class AudioPlaybackToggled extends JournalWritingEvent {
  final String audioPath;

  const AudioPlaybackToggled(this.audioPath);

  @override
  List<Object> get props => [audioPath];
}

class JournalSaveRequested extends JournalWritingEvent {
  const JournalSaveRequested();
}

class JournalWritingReset extends JournalWritingEvent {
  const JournalWritingReset();
}

// Removed WaveformAmplitudesChanged (live waveform no longer used).

class AudioPlaybackChanged extends JournalWritingEvent {
  final String? audioPath;

  const AudioPlaybackChanged(this.audioPath);

  @override
  List<Object?> get props => [audioPath];
}

class RecordingDurationChanged extends JournalWritingEvent {
  final Duration duration;

  const RecordingDurationChanged(this.duration);

  @override
  List<Object> get props => [duration];
}

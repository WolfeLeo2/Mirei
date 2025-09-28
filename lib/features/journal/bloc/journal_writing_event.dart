import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

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

class RecordingStatusChanged extends JournalWritingEvent {
  final bool isRecording;

  const RecordingStatusChanged(this.isRecording);

  @override
  List<Object> get props => [isRecording];
}

class WaveformAmplitudesChanged extends JournalWritingEvent {
  final List<double> amplitudes;

  const WaveformAmplitudesChanged(this.amplitudes);

  @override
  List<Object> get props => [amplitudes];
}

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

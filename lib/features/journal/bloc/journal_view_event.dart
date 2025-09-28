import 'package:equatable/equatable.dart';
import '../../../models/realm_models.dart';

abstract class JournalViewEvent extends Equatable {
  const JournalViewEvent();

  @override
  List<Object?> get props => [];
}

class JournalViewInitialized extends JournalViewEvent {
  final JournalEntryRealm entry;

  const JournalViewInitialized(this.entry);

  @override
  List<Object> get props => [entry];
}

class JournalViewRefreshRequested extends JournalViewEvent {
  const JournalViewRefreshRequested();
}

class AudioPlaybackToggled extends JournalViewEvent {
  final String audioPath;

  const AudioPlaybackToggled(this.audioPath);

  @override
  List<Object> get props => [audioPath];
}

class JournalEditRequested extends JournalViewEvent {
  const JournalEditRequested();
}

class JournalShareRequested extends JournalViewEvent {
  const JournalShareRequested();
}

class JournalDeleteRequested extends JournalViewEvent {
  const JournalDeleteRequested();
}

class JournalDeleteConfirmed extends JournalViewEvent {
  const JournalDeleteConfirmed();
}

class JournalEntryUpdated extends JournalViewEvent {
  final JournalEntryRealm entry;

  const JournalEntryUpdated(this.entry);

  @override
  List<Object> get props => [entry];
}

class AudioPlaybackChanged extends JournalViewEvent {
  final String? audioPath;

  const AudioPlaybackChanged(this.audioPath);

  @override
  List<Object?> get props => [audioPath];
}

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:realm/realm.dart';

import '../../../services/player_service.dart';
import '../../../utils/realm_database_helper.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/realm_models.dart';
import 'journal_view_event.dart';
import 'journal_view_state.dart';

class JournalViewBloc extends Bloc<JournalViewEvent, JournalViewState> {
  final PlayerService _playerService;
  final RealmDatabaseHelper _dbHelper;

  Realm? _realm;
  JournalEntryRealm? _liveEntry;
  StreamSubscription<RealmObjectChanges<JournalEntryRealm>>? _entrySub;
  StreamSubscription? _playerSubscription;

  JournalViewBloc({PlayerService? playerService, RealmDatabaseHelper? dbHelper})
    : _playerService = playerService ?? PlayerService(),
      _dbHelper = dbHelper ?? RealmDatabaseHelper(),
      super(const JournalViewState()) {
    on<JournalViewInitialized>(_onInitialized);
    on<JournalViewRefreshRequested>(_onRefreshRequested);
    on<AudioPlaybackToggled>(_onAudioPlaybackToggled);
    on<JournalEditRequested>(_onJournalEditRequested);
    on<JournalShareRequested>(_onJournalShareRequested);
    on<JournalDeleteRequested>(_onJournalDeleteRequested);
    on<JournalDeleteConfirmed>(_onJournalDeleteConfirmed);
    on<JournalEntryUpdated>(_onJournalEntryUpdated);
    on<AudioPlaybackChanged>(_onAudioPlaybackChanged);
  }

  Future<void> _onInitialized(
    JournalViewInitialized event,
    Emitter<JournalViewState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // Initialize player service
      await _playerService.initialize();

      // Subscribe to player streams
      _playerSubscription = _playerService.currentlyPlayingStream.listen((
        path,
      ) {
        if (!isClosed) {
          add(AudioPlaybackChanged(path));
        }
      });

      // Initialize Realm watcher
      await _initEntryWatcher(event.entry, emit);

      // Prepare audio controllers for all audio recordings
      _setupAudioControllers();

      // Load associated mood
      await _loadAssociatedMood();

      emit(state.copyWith(isLoading: false));

      if (kDebugMode) {
        debugPrint('JournalViewBloc: Initialized successfully');
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'Failed to initialize: $e'));
    }
  }

  Future<void> _onRefreshRequested(
    JournalViewRefreshRequested event,
    Emitter<JournalViewState> emit,
  ) async {
    try {
      await _loadAssociatedMood();
      _setupAudioControllers();
    } catch (e) {
      emit(state.copyWith(error: 'Failed to refresh: $e'));
    }
  }

  Future<void> _onAudioPlaybackToggled(
    AudioPlaybackToggled event,
    Emitter<JournalViewState> emit,
  ) async {
    try {
      await _playerService.playAudio(event.audioPath);
    } catch (e) {
      emit(state.copyWith(error: 'Failed to play audio: $e'));
    }
  }

  void _onJournalEditRequested(
    JournalEditRequested event,
    Emitter<JournalViewState> emit,
  ) {
    // This will be handled by navigation in the UI
    // The bloc just needs to ensure current state is available
  }

  void _onJournalShareRequested(
    JournalShareRequested event,
    Emitter<JournalViewState> emit,
  ) {
    // This will be handled by the UI layer using platform sharing
    // The bloc provides the data to share
  }

  void _onJournalDeleteRequested(
    JournalDeleteRequested event,
    Emitter<JournalViewState> emit,
  ) {
    emit(state.copyWith(showDeleteConfirmation: true));
  }

  Future<void> _onJournalDeleteConfirmed(
    JournalDeleteConfirmed event,
    Emitter<JournalViewState> emit,
  ) async {
    if (state.entry == null) return;

    emit(
      state.copyWith(
        isDeleting: true,
        showDeleteConfirmation: false,
        clearError: true,
      ),
    );

    try {
      final entryToDelete = state.entry!;

      // Stop any playing audio from this entry
      await _playerService.stop();

      // Delete associated image files
      for (final imagePath in entryToDelete.imagePaths) {
        try {
          final file = File(imagePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete image file $imagePath: $e');
          }
        }
      }

      // Delete associated audio files
      for (final audio in entryToDelete.audioRecordings) {
        try {
          final file = File(audio.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete audio file ${audio.path}: $e');
          }
        }
      }

      // Delete from database
      await _dbHelper.deleteJournalEntry(entryToDelete.id);

      emit(state.copyWith(isDeleting: false));

      if (kDebugMode) {
        print('JournalViewBloc: Journal entry deleted successfully');
      }
    } catch (e) {
      emit(
        state.copyWith(
          isDeleting: false,
          error: 'Failed to delete journal: $e',
        ),
      );
    }
  }

  /// Initialize Realm entry watcher
  Future<void> _initEntryWatcher(
    JournalEntryRealm entry,
    Emitter<JournalViewState> emit,
  ) async {
    try {
      _realm ??= await _dbHelper.realm;
      final found = _realm!.find<JournalEntryRealm>(entry.id);

      if (found != null) {
        _liveEntry = found;
        emit(state.copyWith(entry: found));

        // Cancel existing subscription
        await _entrySub?.cancel();

        // Subscribe to changes
        _entrySub = found.changes.listen((changes) {
          if (!isClosed) {
            add(JournalEntryUpdated(changes.object));
          }
        });
      } else {
        // Entry not found in database, use the passed entry
        emit(state.copyWith(entry: entry));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('JournalViewBloc: Error initializing entry watcher: $e');
      }
      // Fallback to using the passed entry
      emit(state.copyWith(entry: entry));
    }
  }

  /// Setup audio controllers for all audio recordings
  void _setupAudioControllers() {
    final entry = _liveEntry ?? state.entry;
    if (entry == null) return;

    try {
      for (final audio in entry.audioRecordings) {
        if (audio.path.isNotEmpty) {
          // This will create the controller if it doesn't exist
          _playerService.getWaveformController(audio.path);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('JournalViewBloc: Error setting up audio controllers: $e');
      }
    }
  }

  /// Load associated mood for the journal entry
  Future<void> _loadAssociatedMood() async {
    final entry = _liveEntry ?? state.entry;
    if (entry == null) return;

    try {
      // First check if entry has a direct mood
      final entryMood = _safeAccess(() => entry.entryMood);
      if (entryMood != null) {
        final moodEntry = MoodEntryRealm(
          ObjectId(),
          entryMood,
          entry.createdAt.toUtc(),
          intensity: null,
        );

        final moodColor = AppColors.getEmotionColor(entryMood);

        emit(state.copyWith(associatedMood: moodEntry, moodColor: moodColor));
        return;
      }

      // Otherwise, look for moods on the same day
      final createdAt = _safeAccess(() => entry.createdAt);
      if (createdAt != null) {
        final dailyMoods = await _dbHelper.getAllMoodsForDate(createdAt);
        if (dailyMoods.isNotEmpty) {
          final moodColor = AppColors.getEmotionColor(dailyMoods.first.mood);

          emit(
            state.copyWith(
              associatedMood: dailyMoods.first,
              moodColor: moodColor,
            ),
          );
        } else {
          emit(state.copyWith(clearAssociatedMood: true));
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('JournalViewBloc: Error loading associated mood: $e');
      }
      // Don't emit error for mood loading failures
    }
  }

  /// Safely access a Realm object property with error handling
  T? _safeAccess<T>(T Function() accessor, [T? defaultValue]) {
    try {
      return accessor();
    } catch (e) {
      if (e is RealmException && e.message.contains('invalidated')) {
        return defaultValue;
      }
      rethrow;
    }
  }

  void _onJournalEntryUpdated(
    JournalEntryUpdated event,
    Emitter<JournalViewState> emit,
  ) {
    _liveEntry = event.entry;
    emit(state.copyWith(entry: event.entry));
    _setupAudioControllers();
    _loadAssociatedMood();
  }

  void _onAudioPlaybackChanged(
    AudioPlaybackChanged event,
    Emitter<JournalViewState> emit,
  ) {
    emit(
      state.copyWith(
        currentlyPlayingAudio: event.audioPath,
        clearCurrentlyPlaying: event.audioPath == null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _entrySub?.cancel();
    await _playerSubscription?.cancel();
    return super.close();
  }
}

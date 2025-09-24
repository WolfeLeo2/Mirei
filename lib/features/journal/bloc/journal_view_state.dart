import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../models/realm_models.dart';
import '../../../core/constants/app_colors.dart';

class JournalViewState extends Equatable {
  final JournalEntryRealm? entry;
  final MoodEntryRealm? associatedMood;
  final Color moodColor;
  final String? currentlyPlayingAudio;
  final bool isLoading;
  final bool isDeleting;
  final String? error;
  final bool showDeleteConfirmation;

  const JournalViewState({
    this.entry,
    this.associatedMood,
    this.moodColor = AppColors.primary,
    this.currentlyPlayingAudio,
    this.isLoading = false,
    this.isDeleting = false,
    this.error,
    this.showDeleteConfirmation = false,
  });

  JournalViewState copyWith({
    JournalEntryRealm? entry,
    MoodEntryRealm? associatedMood,
    Color? moodColor,
    String? currentlyPlayingAudio,
    bool? isLoading,
    bool? isDeleting,
    String? error,
    bool? showDeleteConfirmation,
    bool clearError = false,
    bool clearCurrentlyPlaying = false,
    bool clearAssociatedMood = false,
  }) {
    return JournalViewState(
      entry: entry ?? this.entry,
      associatedMood: clearAssociatedMood
          ? null
          : (associatedMood ?? this.associatedMood),
      moodColor: moodColor ?? this.moodColor,
      currentlyPlayingAudio: clearCurrentlyPlaying
          ? null
          : (currentlyPlayingAudio ?? this.currentlyPlayingAudio),
      isLoading: isLoading ?? this.isLoading,
      isDeleting: isDeleting ?? this.isDeleting,
      error: clearError ? null : (error ?? this.error),
      showDeleteConfirmation:
          showDeleteConfirmation ?? this.showDeleteConfirmation,
    );
  }

  @override
  List<Object?> get props => [
    entry,
    associatedMood,
    moodColor,
    currentlyPlayingAudio,
    isLoading,
    isDeleting,
    error,
    showDeleteConfirmation,
  ];
}

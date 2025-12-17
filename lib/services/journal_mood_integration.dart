import 'dart:convert';
import 'package:realm/realm.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import 'enhanced_mood_service.dart';
import 'enhanced_mood_analytics.dart';
import 'media_store.dart';

/// Service for integrating journal entries with mood context
/// Solves the problem of correlating journals with multiple daily mood entries
class JournalMoodIntegration {
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();
  final EnhancedMoodService _moodService = EnhancedMoodService();
  final EnhancedMoodAnalytics _analytics = EnhancedMoodAnalytics();

  // JOURNAL WRITING MOOD CONTEXT

  /// Save journal entry with current mood context
  /// This creates a mood snapshot specifically for this journal entry
  Future<ObjectId> saveJournalWithMoodContext({
    required String title,
    required String content,
    String? entryMood,
    String? entryMoodContext,
    List<String>? imagePaths,
    List<Map<String, dynamic>>?
    audioRecordings, // expects path,duration(ms),timestamp(ms)
  }) async {
    // Generate ID first so we can place media under a per-journal folder
    final id = ObjectId();

    // Copy images into app storage and store relative paths
    List<String> relativeImagePaths = <String>[];
    if (imagePaths != null && imagePaths.isNotEmpty) {
      try {
        relativeImagePaths = await MediaStore.instance.copyImagesForJournal(
          id,
          imagePaths,
        );
      } catch (_) {}
    }

    // Copy audio files into app storage and rewrite paths to relative before saving
    List<Map<String, dynamic>>? processedAudio = audioRecordings;
    if (audioRecordings != null && audioRecordings.isNotEmpty) {
      try {
        final relAudioPaths = await MediaStore.instance
            .copyAudioFilesForJournal(
              id,
              audioRecordings.map((a) => a['path'] as String).toList(),
            );
        processedAudio = [
          for (int i = 0; i < audioRecordings.length; i++)
            {
              'path': relAudioPaths.length > i
                  ? relAudioPaths[i]
                  : audioRecordings[i]['path'],
              'duration': audioRecordings[i]['duration'],
              'timestamp': audioRecordings[i]['timestamp'],
            },
        ];
      } catch (_) {}
    }

    // Create journal entry object
    final journalEntry = JournalEntryRealm(
      id,
      title,
      content,
      DateTime.now().toUtc(),
      DateTime.now().toUtc(),
      imagePathsString: jsonEncode(relativeImagePaths),
      audioRecordingsString: processedAudio != null
          ? jsonEncode(processedAudio)
          : null,
      entryMood: entryMood,
      entryMoodContext: entryMoodContext,
    );

    // Save the journal entry
    final journalId = await _dbHelper.insertJournalEntry(journalEntry);

    return journalId;
  }

  /// Get suggested mood for journal writing based on recent patterns
  Future<JournalMoodSuggestion?> getSuggestedJournalMood() async {
    // Get recent journal writing patterns
    final correlation = await _analytics.getJournalMoodCorrelation();

    if (correlation.mostProductiveMood.isNotEmpty) {
      return JournalMoodSuggestion(
        suggestedMood: correlation.mostProductiveMood,
        reason:
            'You tend to write most productively when feeling ${correlation.mostProductiveMood}',
        confidence: correlation.averageWritingMood > 0.5 ? 'high' : 'medium',
      );
    }

    // Fallback: suggest based on current time of day patterns
    final timePatterns = await _analytics.getTimeBasedMoodPatterns();
    final hour = DateTime.now().hour;

    String suggestedMood;
    String reason;

    if (hour < 12 && timePatterns.morningAverage > 0) {
      suggestedMood = 'Happy'; // Default positive morning mood
      reason = 'Morning tends to be your best time for writing';
    } else if (hour < 17 && timePatterns.afternoonAverage > 0) {
      suggestedMood = 'Neutral';
      reason = 'Afternoon writing sessions work well for you';
    } else if (timePatterns.eveningAverage > 0) {
      suggestedMood = 'Neutral';
      reason = 'Evening reflection time';
    } else {
      return null; // No clear pattern
    }

    return JournalMoodSuggestion(
      suggestedMood: suggestedMood,
      reason: reason,
      confidence: 'low',
    );
  }

  // CORRELATION ANALYSIS

  /// Analyze correlation between journal content and mood
  Future<ContentMoodAnalysis> analyzeContentMoodCorrelation(
    String content,
  ) async {
    // Simple keyword-based mood analysis
    final positiveWords = [
      'happy',
      'joy',
      'excited',
      'grateful',
      'love',
      'amazing',
      'wonderful',
      'blessed',
      'peaceful',
      'content',
      'proud',
      'accomplished',
      'hopeful',
    ];

    final negativeWords = [
      'sad',
      'angry',
      'frustrated',
      'worried',
      'anxious',
      'depressed',
      'overwhelmed',
      'stressed',
      'tired',
      'lonely',
      'disappointed',
      'upset',
    ];

    final lowerContent = content.toLowerCase();
    int positiveCount = 0;
    int negativeCount = 0;

    for (final word in positiveWords) {
      positiveCount += word.allMatches(lowerContent).length;
    }

    for (final word in negativeWords) {
      negativeCount += word.allMatches(lowerContent).length;
    }

    String suggestedMood;
    double confidence;

    if (positiveCount > negativeCount) {
      suggestedMood = positiveCount > negativeCount * 2 ? 'Happy' : 'Neutral';
      confidence = (positiveCount / (positiveCount + negativeCount + 1));
    } else if (negativeCount > positiveCount) {
      suggestedMood = negativeCount > positiveCount * 2 ? 'Sad' : 'Neutral';
      confidence = (negativeCount / (positiveCount + negativeCount + 1));
    } else {
      suggestedMood = 'Neutral';
      confidence = 0.5;
    }

    return ContentMoodAnalysis(
      suggestedMood: suggestedMood,
      confidence: confidence,
      positiveWordCount: positiveCount,
      negativeWordCount: negativeCount,
      overallSentiment: positiveCount > negativeCount
          ? 'positive'
          : negativeCount > positiveCount
          ? 'negative'
          : 'neutral',
    );
  }

  // TIMELINE CORRELATION

  /// Get mood timeline correlation for a journal entry
  /// Finds the closest mood entry to when the journal was written
  Future<MoodTimelineCorrelation?> getJournalMoodTimelineCorrelation(
    JournalEntryRealm journal,
  ) async {
    // Get the closest mood entry to the journal writing time
    final closestMood = await _analytics.getMoodEntryNearTime(
      journal.createdAt,
    );

    if (closestMood == null) {
      return null;
    }

    final timeDifference = journal.createdAt.difference(closestMood.createdAt);

    return MoodTimelineCorrelation(
      journalEntry: journal,
      correlatedMoodEntry: closestMood,
      timeDifference: timeDifference,
      correlationStrength: _calculateCorrelationStrength(timeDifference),
      isReliableCorrelation:
          timeDifference.abs().inHours <= 3, // Within 3 hours
    );
  }

  /// Get all journal-mood correlations for analysis
  Future<List<MoodTimelineCorrelation>> getAllJournalMoodCorrelations() async {
    final journals = await _dbHelper.getAllJournalEntries();
    final correlations = <MoodTimelineCorrelation>[];

    for (final journal in journals) {
      final correlation = await getJournalMoodTimelineCorrelation(journal);
      if (correlation != null && correlation.isReliableCorrelation) {
        correlations.add(correlation);
      }
    }

    return correlations;
  }

  // HELPER METHODS

  double _calculateCorrelationStrength(Duration timeDifference) {
    final hours = timeDifference.abs().inHours;

    if (hours == 0) return 1.0; // Same hour = perfect correlation
    if (hours <= 1) return 0.9; // Within 1 hour = very strong
    if (hours <= 3) return 0.7; // Within 3 hours = strong
    if (hours <= 6) return 0.5; // Within 6 hours = moderate
    if (hours <= 12) return 0.3; // Within 12 hours = weak
    return 0.1; // Beyond 12 hours = very weak
  }

  // MOOD PROMPTING FOR JOURNAL WRITING

  /// Check if user should be prompted to log mood when writing
  Future<bool> shouldPromptMoodForJournal() async {
    final todaysMoods = await _moodService.getTodaysMoodEntries();
    final now = DateTime.now();

    // If no moods today, definitely prompt
    if (todaysMoods.isEmpty) return true;

    // If last mood was more than 4 hours ago, prompt
    final latestMood = todaysMoods.last;
    final hoursSinceLastMood = now.difference(latestMood.createdAt).inHours;

    return hoursSinceLastMood >= 4;
  }

  /// Get personalized mood prompt for journal writing
  Future<String> getJournalMoodPrompt() async {
    final hasLoggedToday = await _moodService.hasLoggedMoodToday();

    if (!hasLoggedToday) {
      return "How are you feeling as you start writing? This helps us understand your journaling patterns.";
    } else {
      return "Has your mood changed since your last check-in? Let's capture how you're feeling while writing.";
    }
  }
}

// DATA CLASSES

class JournalMoodSuggestion {
  final String suggestedMood;
  final String reason;
  final String confidence; // 'high', 'medium', 'low'

  JournalMoodSuggestion({
    required this.suggestedMood,
    required this.reason,
    required this.confidence,
  });
}

class ContentMoodAnalysis {
  final String suggestedMood;
  final double confidence;
  final int positiveWordCount;
  final int negativeWordCount;
  final String overallSentiment;

  ContentMoodAnalysis({
    required this.suggestedMood,
    required this.confidence,
    required this.positiveWordCount,
    required this.negativeWordCount,
    required this.overallSentiment,
  });
}

class MoodTimelineCorrelation {
  final JournalEntryRealm journalEntry;
  final MoodEntryRealm correlatedMoodEntry;
  final Duration timeDifference;
  final double correlationStrength;
  final bool isReliableCorrelation;

  MoodTimelineCorrelation({
    required this.journalEntry,
    required this.correlatedMoodEntry,
    required this.timeDifference,
    required this.correlationStrength,
    required this.isReliableCorrelation,
  });
}

import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';

/// Enhanced mood analytics service with industry-level insights
class EnhancedMoodAnalytics {
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();

  // INTENSITY-BASED ANALYTICS

  /// Get mood intensity trends over time
  Future<IntensityTrend> getIntensityTrend({int days = 14}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final moods = await _dbHelper.getMoodEntriesForPeriod(startDate, endDate);

    // Filter entries with intensity data
    final moodsWithIntensity = moods.where((m) => m.intensity != null).toList();

    if (moodsWithIntensity.length < 3) {
      return IntensityTrend(
        trend: TrendDirection.insufficient,
        averageIntensity: 0,
        intensityChange: 0,
      );
    }

    // Calculate trend using linear regression on intensity values
    final intensities = moodsWithIntensity
        .map((m) => m.intensity!.toDouble())
        .toList();
    final trendSlope = _calculateTrend(intensities);
    final averageIntensity =
        intensities.reduce((a, b) => a + b) / intensities.length;

    return IntensityTrend(
      trend: trendSlope > 0.1
          ? TrendDirection.improving
          : trendSlope < -0.1
          ? TrendDirection.declining
          : TrendDirection.stable,
      averageIntensity: averageIntensity,
      intensityChange: trendSlope,
    );
  }

  /// Get mood intensity distribution
  Future<Map<String, IntensityStats>> getMoodIntensityDistribution() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final moods = await _dbHelper.getMoodEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    final moodIntensities = <String, List<int>>{};

    for (final mood in moods) {
      if (mood.intensity != null) {
        moodIntensities.putIfAbsent(mood.mood, () => []).add(mood.intensity!);
      }
    }

    return moodIntensities.map((mood, intensities) {
      final average = intensities.reduce((a, b) => a + b) / intensities.length;
      final highest = intensities.reduce((a, b) => a > b ? a : b);
      final lowest = intensities.reduce((a, b) => a < b ? a : b);

      return MapEntry(
        mood,
        IntensityStats(
          averageIntensity: average,
          highestIntensity: highest,
          lowestIntensity: lowest,
          occurrences: intensities.length,
        ),
      );
    });
  }

  // TRIGGER PATTERN ANALYSIS

  /// Analyze most common mood triggers
  Future<Map<String, TriggerAnalysis>> getTriggerPatterns() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final moods = await _dbHelper.getMoodEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    final triggerMoods = <String, List<MoodEntryRealm>>{};

    for (final mood in moods) {
      if (mood.triggers != null && mood.triggers!.isNotEmpty) {
        final triggers = mood.triggers!.split(',');
        for (final trigger in triggers) {
          final cleanTrigger = trigger.trim();
          if (cleanTrigger.isNotEmpty) {
            triggerMoods.putIfAbsent(cleanTrigger, () => []).add(mood);
          }
        }
      }
    }

    return triggerMoods.map((trigger, moodEntries) {
      final moodScores = moodEntries.map((m) => _getMoodScore(m.mood)).toList();
      final intensityScores = moodEntries
          .where((m) => m.intensity != null)
          .map((m) => m.intensity!.toDouble())
          .toList();

      final averageMoodScore =
          moodScores.reduce((a, b) => a + b) / moodScores.length;
      final averageIntensity = intensityScores.isEmpty
          ? 0.0
          : intensityScores.reduce((a, b) => a + b) / intensityScores.length;

      return MapEntry(
        trigger,
        TriggerAnalysis(
          triggerName: trigger,
          occurrences: moodEntries.length,
          averageMoodScore: averageMoodScore,
          averageIntensity: averageIntensity,
          isPositiveTrigger: averageMoodScore > 0,
          mostCommonMood: _getMostCommonMood(moodEntries),
        ),
      );
    });
  }

  // ACTIVITY CORRELATION

  /// Analyze activity impact on mood
  Future<Map<String, ActivityImpact>> getActivityMoodCorrelation() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final moods = await _dbHelper.getMoodEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    final activityMoods = <String, List<MoodEntryRealm>>{};

    for (final mood in moods) {
      if (mood.activities != null && mood.activities!.isNotEmpty) {
        final activities = mood.activities!.split(',');
        for (final activity in activities) {
          final cleanActivity = activity.trim();
          if (cleanActivity.isNotEmpty) {
            activityMoods.putIfAbsent(cleanActivity, () => []).add(mood);
          }
        }
      }
    }

    return activityMoods.map((activity, moodEntries) {
      final moodScores = moodEntries.map((m) => _getMoodScore(m.mood)).toList();
      final intensityScores = moodEntries
          .where((m) => m.intensity != null)
          .map((m) => m.intensity!.toDouble())
          .toList();

      final averageMoodScore =
          moodScores.reduce((a, b) => a + b) / moodScores.length;
      final averageIntensity = intensityScores.isEmpty
          ? 0.0
          : intensityScores.reduce((a, b) => a + b) / intensityScores.length;

      return MapEntry(
        activity,
        ActivityImpact(
          activityName: activity,
          occurrences: moodEntries.length,
          averageMoodScore: averageMoodScore,
          averageIntensity: averageIntensity,
          isPositiveActivity: averageMoodScore > 0,
          moodImprovement: _calculateActivityMoodImprovement(
            activity,
            moodEntries,
          ),
        ),
      );
    });
  }

  // JOURNAL-MOOD CORRELATION (Enhanced)

  /// Analyze correlation between journal writing mood and content
  Future<JournalMoodCorrelation> getJournalMoodCorrelation() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final journals = await _dbHelper.getJournalEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    // Analyze journals with mood context
    final journalsWithMood = journals
        .where((j) => j.entryMood != null)
        .toList();

    if (journalsWithMood.isEmpty) {
      return JournalMoodCorrelation(
        averageWritingMood: 0,
        mostProductiveMood: '',
        moodContentPatterns: {},
        writingMoodTrend: TrendDirection.insufficient,
      );
    }

    // Calculate writing mood patterns
    final writingMoodScores = journalsWithMood
        .map((j) => _getMoodScore(j.entryMood!))
        .toList();
    final averageWritingMood =
        writingMoodScores.reduce((a, b) => a + b) / writingMoodScores.length;

    // Find most productive writing mood (longest content)
    final moodContentLengths = <String, List<int>>{};
    for (final journal in journalsWithMood) {
      moodContentLengths
          .putIfAbsent(journal.entryMood!, () => [])
          .add(journal.content.length);
    }

    String mostProductiveMood = '';
    double longestAverageContent = 0;

    moodContentLengths.forEach((mood, lengths) {
      final average = lengths.reduce((a, b) => a + b) / lengths.length;
      if (average > longestAverageContent) {
        longestAverageContent = average;
        mostProductiveMood = mood;
      }
    });

    return JournalMoodCorrelation(
      averageWritingMood: averageWritingMood,
      mostProductiveMood: mostProductiveMood,
      moodContentPatterns: moodContentLengths,
      writingMoodTrend:
          _calculateTrend(writingMoodScores.map((s) => s.toDouble()).toList()) >
              0.1
          ? TrendDirection.improving
          : TrendDirection.stable,
    );
  }

  // TIME-BASED PATTERN ANALYSIS

  /// Get detailed time-based mood patterns
  Future<TimeBasedPatterns> getTimeBasedMoodPatterns() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final moods = await _dbHelper.getMoodEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    final morningMoods = <MoodEntryRealm>[];
    final afternoonMoods = <MoodEntryRealm>[];
    final eveningMoods = <MoodEntryRealm>[];
    final weekdayMoods = <MoodEntryRealm>[];
    final weekendMoods = <MoodEntryRealm>[];

    for (final mood in moods) {
      final hour = mood.createdAt.hour;
      final weekday = mood.createdAt.weekday;

      // Time of day patterns
      if (hour < 12) {
        morningMoods.add(mood);
      } else if (hour < 17) {
        afternoonMoods.add(mood);
      } else {
        eveningMoods.add(mood);
      }

      // Day of week patterns
      if (weekday <= 5) {
        weekdayMoods.add(mood);
      } else {
        weekendMoods.add(mood);
      }
    }

    return TimeBasedPatterns(
      morningAverage: _calculateAverageMoodScore(morningMoods),
      afternoonAverage: _calculateAverageMoodScore(afternoonMoods),
      eveningAverage: _calculateAverageMoodScore(eveningMoods),
      weekdayAverage: _calculateAverageMoodScore(weekdayMoods),
      weekendAverage: _calculateAverageMoodScore(weekendMoods),
      bestTimeOfDay: _getBestTimeOfDay(
        morningMoods,
        afternoonMoods,
        eveningMoods,
      ),
      bestDayType:
          _calculateAverageMoodScore(weekendMoods) >
              _calculateAverageMoodScore(weekdayMoods)
          ? 'weekends'
          : 'weekdays',
    );
  }

  // PERSONALIZED RECOMMENDATIONS

  /// Generate personalized wellness recommendations
  Future<List<WellnessRecommendation>> getPersonalizedRecommendations() async {
    final recommendations = <WellnessRecommendation>[];

    // Get all analysis data
    final intensityTrend = await getIntensityTrend();
    final triggerPatterns = await getTriggerPatterns();
    final activityCorrelation = await getActivityMoodCorrelation();
    final timePatterns = await getTimeBasedMoodPatterns();
    final journalCorrelation = await getJournalMoodCorrelation();

    // Intensity-based recommendations
    if (intensityTrend.averageIntensity < 5) {
      recommendations.add(
        WellnessRecommendation(
          type: RecommendationType.intensity,
          priority: RecommendationPriority.high,
          title: 'Low Mood Intensity Detected',
          message:
              'Your recent mood intensity averages ${intensityTrend.averageIntensity.toStringAsFixed(1)}/10. Consider gentle self-care activities.',
          actionSuggestions: ['meditation', 'gentle walk', 'call a friend'],
        ),
      );
    }

    // Trigger-based recommendations
    final negativeTriggers =
        triggerPatterns.values
            .where((t) => !t.isPositiveTrigger && t.occurrences >= 3)
            .toList()
          ..sort((a, b) => b.occurrences.compareTo(a.occurrences));

    if (negativeTriggers.isNotEmpty) {
      final topTrigger = negativeTriggers.first;
      recommendations.add(
        WellnessRecommendation(
          type: RecommendationType.trigger,
          priority: RecommendationPriority.medium,
          title: 'Recurring Trigger Identified',
          message:
              '"${topTrigger.triggerName}" appears to impact your mood negatively (${topTrigger.occurrences} times this month).',
          actionSuggestions: [
            'coping strategies',
            'trigger avoidance',
            'professional support',
          ],
        ),
      );
    }

    // Activity-based recommendations
    final positiveActivities =
        activityCorrelation.values
            .where((a) => a.isPositiveActivity && a.occurrences >= 2)
            .toList()
          ..sort((a, b) => b.averageMoodScore.compareTo(a.averageMoodScore));

    if (positiveActivities.isNotEmpty) {
      final topActivity = positiveActivities.first;
      recommendations.add(
        WellnessRecommendation(
          type: RecommendationType.activity,
          priority: RecommendationPriority.high,
          title: 'Mood-Boosting Activity Found',
          message:
              '${topActivity.activityName} consistently improves your mood (avg ${topActivity.averageIntensity.toStringAsFixed(1)}/10).',
          actionSuggestions: [
            'schedule more ${topActivity.activityName}',
            'set reminders',
            'track progress',
          ],
        ),
      );
    }

    // Time-based recommendations
    if (timePatterns.morningAverage < timePatterns.eveningAverage - 1) {
      recommendations.add(
        WellnessRecommendation(
          type: RecommendationType.timing,
          priority: RecommendationPriority.medium,
          title: 'Morning Mood Pattern',
          message:
              'Your mornings tend to be more challenging. Consider a morning routine.',
          actionSuggestions: [
            'morning meditation',
            'exercise routine',
            'gratitude practice',
          ],
        ),
      );
    }

    // Journal writing recommendations
    if (journalCorrelation.averageWritingMood > 0.5) {
      recommendations.add(
        WellnessRecommendation(
          type: RecommendationType.journaling,
          priority: RecommendationPriority.high,
          title: 'Journaling Boost',
          message:
              'Writing consistently improves your mood. Your most productive writing happens when feeling "${journalCorrelation.mostProductiveMood}".',
          actionSuggestions: [
            'daily journaling',
            'mood-based prompts',
            'writing reminders',
          ],
        ),
      );
    }

    return recommendations;
  }

  // MULTIPLE DAILY ENTRIES SUPPORT

  /// Get mood timeline for a specific date
  Future<List<MoodTimelineEntry>> getDailyMoodTimeline(DateTime date) async {
    final moods = await _dbHelper.getAllMoodsForDate(date);

    return moods
        .map(
          (mood) => MoodTimelineEntry(
            mood: mood.mood,
            intensity: mood.intensity,
            timestamp: mood.createdAt,
            context: mood.context,
            triggers: mood.triggers?.split(',') ?? [],
            activities: mood.activities?.split(',') ?? [],
            checkInType: mood.checkInType,
          ),
        )
        .toList();
  }

  /// Get mood entry closest to a specific time (for journal correlation)
  Future<MoodEntryRealm?> getMoodEntryNearTime(DateTime targetTime) async {
    final dayMoods = await _dbHelper.getAllMoodsForDate(targetTime);

    if (dayMoods.isEmpty) return null;

    // Find mood entry closest in time to the target
    MoodEntryRealm? closestMood;
    Duration smallestDifference = const Duration(days: 1);

    for (final mood in dayMoods) {
      final difference = targetTime.difference(mood.createdAt).abs();
      if (difference < smallestDifference) {
        smallestDifference = difference;
        closestMood = mood;
      }
    }

    return closestMood;
  }

  // HELPER METHODS

  int _getMoodScore(String mood) {
    const positiveModods = ['Happy', 'Cutesy', 'Shocked'];
    const negativeModods = ['Sad', 'Angry', 'Disappointed', 'Worried', 'Tired'];

    if (positiveModods.contains(mood)) return 1;
    if (negativeModods.contains(mood)) return -1;
    return 0; // Neutral, Awkward
  }

  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0;

    final n = values.length;
    final sumX = n * (n - 1) / 2;
    final sumY = values.reduce((a, b) => a + b);
    final sumXY = values
        .asMap()
        .entries
        .map((e) => e.key * e.value)
        .reduce((a, b) => a + b);
    final sumX2 = n * (n - 1) * (2 * n - 1) / 6;

    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  }

  double _calculateAverageMoodScore(List<MoodEntryRealm> moods) {
    if (moods.isEmpty) return 0;
    final scores = moods.map((mood) => _getMoodScore(mood.mood)).toList();
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  String _getMostCommonMood(List<MoodEntryRealm> moods) {
    final moodCounts = <String, int>{};
    for (final mood in moods) {
      moodCounts[mood.mood] = (moodCounts[mood.mood] ?? 0) + 1;
    }

    if (moodCounts.isEmpty) return '';

    return moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  String _getBestTimeOfDay(
    List<MoodEntryRealm> morning,
    List<MoodEntryRealm> afternoon,
    List<MoodEntryRealm> evening,
  ) {
    final morningScore = _calculateAverageMoodScore(morning);
    final afternoonScore = _calculateAverageMoodScore(afternoon);
    final eveningScore = _calculateAverageMoodScore(evening);

    if (morningScore >= afternoonScore && morningScore >= eveningScore) {
      return 'morning';
    } else if (afternoonScore >= eveningScore) {
      return 'afternoon';
    } else {
      return 'evening';
    }
  }

  double _calculateActivityMoodImprovement(
    String activity,
    List<MoodEntryRealm> moodEntries,
  ) {
    // Calculate if mood improves after this activity
    // This would require temporal analysis of before/after moods
    // For now, return the average mood score for this activity
    return _calculateAverageMoodScore(moodEntries);
  }
}

// DATA CLASSES FOR ANALYTICS

class IntensityTrend {
  final TrendDirection trend;
  final double averageIntensity;
  final double intensityChange;

  IntensityTrend({
    required this.trend,
    required this.averageIntensity,
    required this.intensityChange,
  });
}

class IntensityStats {
  final double averageIntensity;
  final int highestIntensity;
  final int lowestIntensity;
  final int occurrences;

  IntensityStats({
    required this.averageIntensity,
    required this.highestIntensity,
    required this.lowestIntensity,
    required this.occurrences,
  });
}

class TriggerAnalysis {
  final String triggerName;
  final int occurrences;
  final double averageMoodScore;
  final double averageIntensity;
  final bool isPositiveTrigger;
  final String mostCommonMood;

  TriggerAnalysis({
    required this.triggerName,
    required this.occurrences,
    required this.averageMoodScore,
    required this.averageIntensity,
    required this.isPositiveTrigger,
    required this.mostCommonMood,
  });
}

class ActivityImpact {
  final String activityName;
  final int occurrences;
  final double averageMoodScore;
  final double averageIntensity;
  final bool isPositiveActivity;
  final double moodImprovement;

  ActivityImpact({
    required this.activityName,
    required this.occurrences,
    required this.averageMoodScore,
    required this.averageIntensity,
    required this.isPositiveActivity,
    required this.moodImprovement,
  });
}

class JournalMoodCorrelation {
  final double averageWritingMood;
  final String mostProductiveMood;
  final Map<String, List<int>> moodContentPatterns;
  final TrendDirection writingMoodTrend;

  JournalMoodCorrelation({
    required this.averageWritingMood,
    required this.mostProductiveMood,
    required this.moodContentPatterns,
    required this.writingMoodTrend,
  });
}

class MoodTimelineEntry {
  final String mood;
  final int? intensity;
  final DateTime timestamp;
  final String? context;
  final List<String> triggers;
  final List<String> activities;
  final String? checkInType;

  MoodTimelineEntry({
    required this.mood,
    this.intensity,
    required this.timestamp,
    this.context,
    required this.triggers,
    required this.activities,
    this.checkInType,
  });
}

class TimeBasedPatterns {
  final double morningAverage;
  final double afternoonAverage;
  final double eveningAverage;
  final double weekdayAverage;
  final double weekendAverage;
  final String bestTimeOfDay;
  final String bestDayType;

  TimeBasedPatterns({
    required this.morningAverage,
    required this.afternoonAverage,
    required this.eveningAverage,
    required this.weekdayAverage,
    required this.weekendAverage,
    required this.bestTimeOfDay,
    required this.bestDayType,
  });
}

class WellnessRecommendation {
  final RecommendationType type;
  final RecommendationPriority priority;
  final String title;
  final String message;
  final List<String> actionSuggestions;

  WellnessRecommendation({
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.actionSuggestions,
  });
}

enum TrendDirection { improving, declining, stable, insufficient }

enum RecommendationType { intensity, trigger, activity, timing, journaling }

enum RecommendationPriority { high, medium, low }
 
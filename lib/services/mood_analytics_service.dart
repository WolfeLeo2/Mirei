import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';

class MoodAnalyticsService {
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();

  /// Get mood entries for today
  Future<List<MoodEntryRealm>> getTodayMoods() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await _dbHelper.getMoodEntriesForPeriod(startOfDay, endOfDay);
  }

  /// Get mood entries for the current week
  Future<List<MoodEntryRealm>> getWeekMoods() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    return await _dbHelper.getMoodEntriesForPeriod(startOfWeekDay, now);
  }

  /// Get mood frequency count for a period
  Future<Map<String, int>> getMoodFrequency(
    DateTime start,
    DateTime end,
  ) async {
    final moods = await _dbHelper.getMoodEntriesForPeriod(start, end);
    final frequency = <String, int>{};

    for (final mood in moods) {
      frequency[mood.mood] = (frequency[mood.mood] ?? 0) + 1;
    }

    return frequency;
  }

  /// Get the most frequent mood for a period
  Future<String?> getMostFrequentMood(DateTime start, DateTime end) async {
    final frequency = await getMoodFrequency(start, end);

    if (frequency.isEmpty) return null;

    return frequency.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get mood streak (consecutive days with same mood)
  Future<int> getCurrentMoodStreak(String mood) async {
    final allMoods = await _dbHelper.getAllMoodEntries();
    int streak = 0;

    for (final moodEntry in allMoods) {
      if (moodEntry.mood == mood) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Get average moods per day for the last 30 days
  Future<double> getAverageMoodsPerDay() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final moods = await _dbHelper.getMoodEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    return moods.length / 30.0;
  }

  // NEW ENHANCED ANALYTICS METHODS

  /// Get mood trend analysis (improving, declining, stable)
  Future<MoodTrend> getMoodTrend({int days = 14}) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    final moods = await _dbHelper.getMoodEntriesForPeriod(startDate, endDate);

    if (moods.length < 3) return MoodTrend.insufficient;

    // Score moods: positive = 1, neutral = 0, negative = -1
    final scores = moods.map((mood) => _getMoodScore(mood.mood)).toList();

    // Calculate trend using linear regression
    final trend = _calculateTrend(scores);

    if (trend > 0.1) return MoodTrend.improving;
    if (trend < -0.1) return MoodTrend.declining;
    return MoodTrend.stable;
  }

  /// Get time-based mood patterns (morning vs evening, weekday vs weekend)
  Future<Map<String, dynamic>> getMoodPatterns() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final moods = await _dbHelper.getMoodEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    final morningMoods = <String>[];
    final eveningMoods = <String>[];
    final weekdayMoods = <String>[];
    final weekendMoods = <String>[];

    for (final mood in moods) {
      final hour = mood.createdAt.hour;
      final weekday = mood.createdAt.weekday;

      // Time patterns
      if (hour < 12) {
        morningMoods.add(mood.mood);
      } else {
        eveningMoods.add(mood.mood);
      }

      // Day patterns
      if (weekday <= 5) {
        weekdayMoods.add(mood.mood);
      } else {
        weekendMoods.add(mood.mood);
      }
    }

    return {
      'timePatterns': {
        'morningAverage': _calculateMoodAverage(morningMoods),
        'eveningAverage': _calculateMoodAverage(eveningMoods),
      },
      'dayPatterns': {
        'weekdayAverage': _calculateMoodAverage(weekdayMoods),
        'weekendAverage': _calculateMoodAverage(weekendMoods),
      },
    };
  }

  /// Get mood correlation with journal entries
  Future<Map<String, dynamic>> getMoodJournalCorrelation() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final moods = await _dbHelper.getMoodEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );
    final journals = await _dbHelper.getJournalEntriesForPeriod(
      thirtyDaysAgo,
      DateTime.now(),
    );

    // Group by day
    final moodsByDay = <String, List<String>>{};
    final journalsByDay = <String, int>{};

    for (final mood in moods) {
      final day = _formatDate(mood.createdAt);
      moodsByDay.putIfAbsent(day, () => []).add(mood.mood);
    }

    for (final journal in journals) {
      final day = _formatDate(journal.createdAt);
      journalsByDay[day] = (journalsByDay[day] ?? 0) + 1;
    }

    // Calculate correlation
    int daysWithBothActivities = 0;
    double totalMoodScore = 0;
    int totalJournalEntries = 0;

    for (final day in moodsByDay.keys) {
      if (journalsByDay.containsKey(day)) {
        daysWithBothActivities++;
        totalMoodScore += _calculateMoodAverage(moodsByDay[day]!);
        totalJournalEntries += journalsByDay[day]!;
      }
    }

    return {
      'daysWithBothActivities': daysWithBothActivities,
      'averageMoodOnJournalDays': daysWithBothActivities > 0
          ? totalMoodScore / daysWithBothActivities
          : 0,
      'averageJournalEntriesPerDay': daysWithBothActivities > 0
          ? totalJournalEntries / daysWithBothActivities
          : 0,
    };
  }

  /// Get personalized wellness recommendations
  Future<List<String>> getWellnessRecommendations() async {
    final recommendations = <String>[];
    final patterns = await getMoodPatterns();
    final trend = await getMoodTrend();
    final correlation = await getMoodJournalCorrelation();

    // Trend-based recommendations
    switch (trend) {
      case MoodTrend.declining:
        recommendations.add(
          "Your mood trend shows some challenges. Consider scheduling a wellness check-in.",
        );
        recommendations.add(
          "Try incorporating more mindfulness activities into your routine.",
        );
        break;
      case MoodTrend.improving:
        recommendations.add(
          "Great progress! Keep up the positive momentum with your current practices.",
        );
        break;
      case MoodTrend.stable:
        recommendations.add(
          "Your mood is stable. Consider exploring new wellness activities to continue growing.",
        );
        break;
      default:
        break;
    }

    // Time-based recommendations
    final timePatterns = patterns['timePatterns'] as Map<String, dynamic>;
    if (timePatterns['morningAverage'] < timePatterns['eveningAverage']) {
      recommendations.add(
        "Your mornings tend to be challenging. Try a morning meditation routine.",
      );
    }

    // Journal correlation recommendations
    if (correlation['averageMoodOnJournalDays'] > 0.5) {
      recommendations.add(
        "Journaling seems to positively impact your mood. Consider daily journaling.",
      );
    }

    return recommendations;
  }

  // Helper methods
  int _getMoodScore(String mood) {
    const positiveModods = ['Happy', 'Cutesy', 'Shocked'];
    const negativeModods = ['Sad', 'Angry', 'Disappointed', 'Worried', 'Tired'];

    if (positiveModods.contains(mood)) return 1;
    if (negativeModods.contains(mood)) return -1;
    return 0; // Neutral, Awkward
  }

  double _calculateTrend(List<int> scores) {
    if (scores.length < 2) return 0;

    final n = scores.length;
    final sumX = n * (n - 1) / 2; // Sum of indices
    final sumY = scores.reduce((a, b) => a + b).toDouble(); // Sum of scores
    final sumXY = scores
        .asMap()
        .entries
        .map((e) => e.key * e.value)
        .reduce((a, b) => a + b)
        .toDouble();
    final sumX2 = n * (n - 1) * (2 * n - 1) / 6; // Sum of squared indices

    // Linear regression slope
    return (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  }

  double _calculateMoodAverage(List<String> moods) {
    if (moods.isEmpty) return 0;
    final total = moods.map(_getMoodScore).reduce((a, b) => a + b);
    return total / moods.length;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

enum MoodTrend { improving, declining, stable, insufficient }

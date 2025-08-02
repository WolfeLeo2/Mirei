import '../models/mood_entry.dart';
import '../utils/database_helper.dart';

class MoodAnalyticsService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get mood entries for today
  Future<List<MoodEntry>> getTodayMoods() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return await _dbHelper.getMoodEntriesForPeriod(startOfDay, endOfDay);
  }

  /// Get mood entries for the current week
  Future<List<MoodEntry>> getWeekMoods() async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    
    return await _dbHelper.getMoodEntriesForPeriod(startOfWeekDay, now);
  }

  /// Get mood frequency count for a period
  Future<Map<String, int>> getMoodFrequency(DateTime start, DateTime end) async {
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
    
    return frequency.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
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
    final moods = await _dbHelper.getMoodEntriesForPeriod(thirtyDaysAgo, DateTime.now());
    
    return moods.length / 30.0;
  }
}

import 'package:realm/realm.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';

/// Enhanced mood service for handling multiple daily entries and journal mood context
class EnhancedMoodService {
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();

  // DAILY MOOD TRACKING (Enhanced)

  /// Save mood with enhanced context data
  Future<void> saveMoodEntry({
    required String mood,
    int? intensity,
    String? context,
    List<String>? triggers,
    List<String>? activities,
    String? location,
    String? checkInType,
  }) async {
    // Auto-determine time of day if not provided
    final finalCheckInType = checkInType ?? getSuggestedCheckInType();

    await _dbHelper.insertEnhancedMoodEntry(
      mood: mood,
      intensity: intensity,
      context: context,
      triggers: triggers,
      activities: activities,
      location: location,
      checkInType: finalCheckInType,
    );
  }

  /// Get all mood entries for today (supports multiple entries)
  Future<List<MoodEntryRealm>> getTodaysMoodEntries() async {
    return await _dbHelper.getAllMoodsForDate(DateTime.now());
  }

  /// Get the latest mood entry for today
  Future<MoodEntryRealm?> getLatestMoodToday() async {
    return await _dbHelper.getLatestMoodToday();
  }

  /// Check if user has logged mood today
  Future<bool> hasLoggedMoodToday() async {
    final todaysMoods = await getTodaysMoodEntries();
    return todaysMoods.isNotEmpty;
  }

  /// Get suggested check-in type based on time of day
  String getSuggestedCheckInType() {
    final hour = DateTime.now().hour;

    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  // JOURNAL MOOD CONTEXT

  /// Save mood context for a specific journal entry
  Future<void> saveJournalMoodContext({
    required String journalId,
    required String mood,
    String? context,
  }) async {
    final objectId = ObjectId.fromHexString(journalId);
    await _dbHelper.updateJournalEntryMoodContext(
      objectId,
      entryMood: mood,
      entryMoodContext: context,
    );
  }

  /// Get journal entries with mood context
  Future<List<JournalEntryRealm>> getJournalsWithMoodContext() async {
    final allJournals = await _dbHelper.getAllJournalEntries();
    return allJournals.where((j) => j.entryMood != null).toList();
  }

  // QUICK CHECK-IN HELPERS

  /// Quick mood check-in (just mood + intensity)
  Future<void> quickMoodCheckIn(String mood, int intensity) async {
    await saveMoodEntry(mood: mood, intensity: intensity, checkInType: 'quick');
  }

  /// Detailed mood check-in (full context)
  Future<void> detailedMoodCheckIn({
    required String mood,
    required int intensity,
    String? context,
    List<String>? triggers,
    List<String>? activities,
    String? location,
  }) async {
    await saveMoodEntry(
      mood: mood,
      intensity: intensity,
      context: context,
      triggers: triggers,
      activities: activities,
      location: location,
      checkInType: 'detailed',
    );
  }

  // MOOD SUGGESTIONS

  /// Get suggested triggers based on previous entries
  Future<List<String>> getSuggestedTriggers() async {
    final recentMoods = await _dbHelper.getMoodEntriesForPeriod(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    final triggerCounts = <String, int>{};

    for (final mood in recentMoods) {
      if (mood.triggers != null && mood.triggers!.isNotEmpty) {
        final triggers = mood.triggers!.split(',');
        for (final trigger in triggers) {
          final cleanTrigger = trigger.trim();
          if (cleanTrigger.isNotEmpty) {
            triggerCounts[cleanTrigger] =
                (triggerCounts[cleanTrigger] ?? 0) + 1;
          }
        }
      }
    }

    // Return most common triggers, sorted by frequency
    final sortedTriggers = triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTriggers.take(10).map((e) => e.key).toList();
  }

  /// Get suggested activities based on previous entries
  Future<List<String>> getSuggestedActivities() async {
    final recentMoods = await _dbHelper.getMoodEntriesForPeriod(
      DateTime.now().subtract(const Duration(days: 30)),
      DateTime.now(),
    );

    final activityCounts = <String, int>{};

    for (final mood in recentMoods) {
      if (mood.activities != null && mood.activities!.isNotEmpty) {
        final activities = mood.activities!.split(',');
        for (final activity in activities) {
          final cleanActivity = activity.trim();
          if (cleanActivity.isNotEmpty) {
            activityCounts[cleanActivity] =
                (activityCounts[cleanActivity] ?? 0) + 1;
          }
        }
      }
    }

    final sortedActivities = activityCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedActivities.take(10).map((e) => e.key).toList();
  }

  // BACKWARD COMPATIBILITY

  /// Save simple mood (backward compatible with existing system)
  Future<void> saveSimpleMood(String mood) async {
    // Check if there's already a mood for today
    final existingMood = await _dbHelper.getTodaysMoodEntry();

    if (existingMood != null) {
      // Update existing mood entry
      final updatedMoodEntry = MoodEntryRealm(
        existingMood.id,
        mood,
        DateTime.now(),
        note: existingMood.note,
        intensity: existingMood.intensity,
        context: existingMood.context,
        triggers: existingMood.triggers,
        activities: existingMood.activities,
        location: existingMood.location,
        checkInType: existingMood.checkInType ?? 'simple',
        sequenceNumber: existingMood.sequenceNumber,
      );
      await _dbHelper.updateMoodEntry(updatedMoodEntry);
    } else {
      // Create new simple mood entry
      await saveMoodEntry(mood: mood, checkInType: 'simple');
    }
  }

  /// Get today's mood (backward compatible - returns latest if multiple)
  Future<MoodEntryRealm?> getTodaysMood() async {
    return await _dbHelper.getLatestMoodToday();
  }
}

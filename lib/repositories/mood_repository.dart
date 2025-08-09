
import 'package:realm/realm.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';

/// Abstract definition for a mood data source.
/// This allows for swapping the implementation (e.g., for testing) without
/// changing the business logic in the BLoC.
abstract class MoodRepository {
  Future<MoodEntryRealm?> getTodaysMood();
  Future<void> saveMood(String mood);
}

/// A repository implementation that uses Realm for data persistence.
class RealmMoodRepository implements MoodRepository {
  // Note: In a larger app, you might inject this helper as a dependency.
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();

  @override
  Future<MoodEntryRealm?> getTodaysMood() async {
    return _dbHelper.getTodaysMoodEntry();
  }

  @override
  Future<void> saveMood(String mood) async {
    final existingMood = await getTodaysMood();

    if (existingMood != null) {
      // If a mood already exists for today, update it.
      final updatedMood = MoodEntryRealm(
        existingMood.id,
        mood,
        DateTime.now(),
        note: existingMood.note,
      );
      await _dbHelper.updateMoodEntry(updatedMood);
    } else {
      // Otherwise, create a new entry.
      final newMood = MoodEntryRealm(ObjectId(), mood, DateTime.now());
      await _dbHelper.insertMoodEntry(newMood);
    }
  }
}

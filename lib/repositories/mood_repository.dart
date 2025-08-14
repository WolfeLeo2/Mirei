
import 'package:flutter/foundation.dart';
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
  final RealmDatabaseHelper _dbHelper;

  RealmMoodRepository({RealmDatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? RealmDatabaseHelper();

  @override
  Future<MoodEntryRealm?> getTodaysMood() async {
    try {
      return _dbHelper.getTodaysMoodEntry();
    } catch (e) {
      // In a real app, you might want to log this error to a service
      // like Sentry or Firebase Crashlytics.
      debugPrint('Error getting today\'s mood: $e');
      rethrow; // Re-throwing allows the BLoC to handle the error.
    }
  }

  @override
  Future<void> saveMood(String mood) async {
    try {
      final realm = await _dbHelper.realm;
      final existingMood = await getTodaysMood();

      if (existingMood != null) {
        // If a mood already exists for today, update it in a write transaction.
        realm.write(() {
          existingMood.mood = mood;
          // Preserve the original creation date to keep it on the same day
          existingMood.createdAt = existingMood.createdAt; 
        });
      } else {
        // Otherwise, create a new entry.
        final newMood = MoodEntryRealm(ObjectId(), mood, DateTime.now());
        await _dbHelper.insertMoodEntry(newMood);
      }
    } catch (e) {
      debugPrint('Error saving mood: $e');
      rethrow;
    }
  }
}

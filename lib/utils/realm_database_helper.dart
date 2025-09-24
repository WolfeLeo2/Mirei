import 'package:realm/realm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
import '../models/realm_models.dart';
import '../services/media_store.dart';

class RealmDatabaseHelper {
  static final RealmDatabaseHelper _instance = RealmDatabaseHelper._internal();
  static Realm? _realm;

  RealmDatabaseHelper._internal();

  factory RealmDatabaseHelper() {
    return _instance;
  }

  Future<Realm> get realm async {
    if (_realm != null) return _realm!;
    _realm = await _initRealm();
    return _realm!;
  }

  Future<Realm> _initRealm() async {
    final directory = await getApplicationDocumentsDirectory();
    final realmPath = path.join(directory.path, 'mirei_app.realm');

    final schemas = [
      MoodEntryRealm.schema,
      JournalEntryRealm.schema,
      UserProfileRealm.schema,
    ];

    try {
      // Add schema version and migration
      final config = Configuration.local(
        schemas,
        path: realmPath,
        schemaVersion: 7, // Pruned media cache models
        migrationCallback: (migration, oldSchemaVersion) {
          if (oldSchemaVersion < 7) {
            print('Migrating to schema v7: removing media cache models');
          }
        },
      );

      return Realm(config);
    } catch (e) {
      print('Realm migration failed: $e');
      print('Rebuilding database for schema compatibility...');

      try {
        final file = File(realmPath);
        if (await file.exists()) {
          await file.delete();
          print('Database file cleared - will rebuild automatically');
        }

        final config = Configuration.local(
          schemas,
          path: realmPath,
          schemaVersion: 7,
        );
        return Realm(config);
      } catch (recreateError) {
        print('Failed to recreate database: $recreateError');
        rethrow;
      }
    }
  }

  // DATABASE MAINTENANCE METHODS

  /// Reset database completely (deletes file and recreates)
  Future<void> resetDatabase() async {
    if (_realm != null) {
      _realm!.close();
      _realm = null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final realmPath = path.join(directory.path, 'mirei_app.realm');

    final file = File(realmPath);
    if (await file.exists()) {
      await file.delete();
      print('Database file deleted and will be recreated on next access');
    }
  }

  // MOOD ENTRY METHODS
  Future<ObjectId> insertMoodEntry(MoodEntryRealm moodEntry) async {
    final realmDb = await realm;
    late ObjectId id;

    realmDb.write(() {
      final savedEntry = realmDb.add(moodEntry);
      id = savedEntry.id;
    });

    return id;
  }

  Future<List<MoodEntryRealm>> getAllMoodEntries() async {
    final realmDb = await realm;
    final results = realmDb.all<MoodEntryRealm>().query(
      'TRUEPREDICATE SORT(createdAt DESC)',
    );
    return results.toList();
  }

  Future<List<MoodEntryRealm>> getMoodEntriesForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final realmDb = await realm;
    final results = realmDb.all<MoodEntryRealm>().query(
      'createdAt >= \$0 AND createdAt <= \$1 SORT(createdAt DESC)',
      [start, end],
    );
    return results.toList();
  }

  Future<void> deleteMoodEntry(ObjectId id) async {
    final realmDb = await realm;
    final entry = realmDb.find<MoodEntryRealm>(id);
    if (entry != null) {
      realmDb.write(() {
        realmDb.delete(entry);
      });
    }
  }

  Future<void> updateMoodEntry(MoodEntryRealm moodEntry) async {
    final realmDb = await realm;
    final existingEntry = realmDb.find<MoodEntryRealm>(moodEntry.id);

    if (existingEntry != null) {
      realmDb.write(() {
        existingEntry.mood = moodEntry.mood;
        existingEntry.createdAt = moodEntry.createdAt;
        existingEntry.note = moodEntry.note;
      });
    }
  }

  Future<MoodEntryRealm?> getTodaysMoodEntry() async {
    final now = DateTime.now();
    // Use the new method to get moods for the current date
    return getMoodsForDate(now);
  }

  /// Retrieves the first mood entry for a specific date.
  Future<MoodEntryRealm?> getMoodsForDate(DateTime date) async {
    final realmDb = await realm;

    // Normalize the date to the start and end of the day in UTC
    final startOfDay = DateTime.utc(date.year, date.month, date.day);
    final endOfDay = DateTime.utc(
      date.year,
      date.month,
      date.day,
      23,
      59,
      59,
      999,
    );

    // Query for entries within the specified day
    final results = realmDb.all<MoodEntryRealm>().query(
      'createdAt >= \$0 AND createdAt <= \$1',
      [startOfDay, endOfDay],
    );

    // Return the first result if available, otherwise null
    return results.isEmpty ? null : results.first;
  }

  // ENHANCED MOOD TRACKING METHODS

  /// Get all mood entries for a specific date (supports multiple daily entries)
  Future<List<MoodEntryRealm>> getAllMoodsForDate(DateTime date) async {
    final realmDb = await realm;

    // Compute local day boundaries, then convert to UTC for querying stored UTC timestamps
    final localStart = DateTime(date.year, date.month, date.day);
    final localEnd = localStart
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));
    final utcStart = localStart.toUtc();
    final utcEnd = localEnd.toUtc();

    final results = realmDb.all<MoodEntryRealm>().query(
      'createdAt >= \$0 AND createdAt <= \$1 SORT(createdAt ASC)',
      [utcStart, utcEnd],
    );

    return results.toList();
  }

  /// Get the latest mood entry for today
  Future<MoodEntryRealm?> getLatestMoodToday() async {
    final todaysMoods = await getAllMoodsForDate(DateTime.now());
    return todaysMoods.isEmpty ? null : todaysMoods.last;
  }

  /// Insert mood entry with enhanced data
  Future<ObjectId> insertEnhancedMoodEntry({
    required String mood,
    int? intensity,
    String? context,
    List<String>? triggers,
    List<String>? activities,
    String? location,
  }) async {
    final realmDb = await realm;
    late ObjectId id;

    // Calculate sequence number for today
    final todaysMoods = await getAllMoodsForDate(DateTime.now());
    final sequenceNumber = todaysMoods.length + 1;

    final moodEntry = MoodEntryRealm(
      ObjectId(),
      mood,
      DateTime.now().toUtc(),
      note: context,
      intensity: intensity,
      context: context,
      triggers: triggers?.join(','),
      activities: activities?.join(','),
      location: location,
      sequenceNumber: sequenceNumber,
    );

    realmDb.write(() {
      final savedEntry = realmDb.add(moodEntry);
      id = savedEntry.id;
    });

    return id;
  }

  /// Update journal entry with mood context
  Future<void> updateJournalEntryMoodContext(
    ObjectId journalId, {
    String? entryMood,
    String? entryMoodContext,
  }) async {
    final realmDb = await realm;
    final existingEntry = realmDb.find<JournalEntryRealm>(journalId);

    if (existingEntry != null) {
      realmDb.write(() {
        existingEntry.entryMood = entryMood;
        existingEntry.entryMoodContext = entryMoodContext;
      });
    }
  }

  // JOURNAL ENTRY METHODS
  Future<ObjectId> insertJournalEntry(JournalEntryRealm entry) async {
    final realmDb = await realm;
    late ObjectId id;

    realmDb.write(() {
      final savedEntry = realmDb.add(entry);
      id = savedEntry.id;
    });

    return id;
  }

  Future<List<JournalEntryRealm>> getAllJournalEntries() async {
    final realmDb = await realm;
    final results = realmDb.all<JournalEntryRealm>().query(
      'TRUEPREDICATE SORT(createdAt DESC)',
    );
    return results.toList();
  }

  Future<JournalEntryRealm?> getJournalEntry(ObjectId id) async {
    final realmDb = await realm;
    return realmDb.find<JournalEntryRealm>(id);
  }

  Future<void> updateJournalEntry(JournalEntryRealm entry) async {
    final realmDb = await realm;
    final existingEntry = realmDb.find<JournalEntryRealm>(entry.id);

    if (existingEntry != null) {
      // Capture old vs new image sets for cleanup
      final List<String> oldImages = List<String>.from(
        existingEntry.imagePaths,
      );
      final List<String> newImages = List<String>.from(entry.imagePaths);

      realmDb.write(() {
        existingEntry.title = entry.title;
        existingEntry.content = entry.content;
        existingEntry.imagePathsString = entry.imagePathsString;
        existingEntry.audioRecordingsString = entry.audioRecordingsString;
      });

      // Delete removed images from storage (those present before but not after)
      final removedImages = oldImages
          .where((o) => !newImages.contains(o))
          .toList();
      if (removedImages.isNotEmpty) {
        try {
          await MediaStore.instance.deleteRelativeFiles(removedImages);
        } catch (_) {}
      }

      // Delete removed audio files similarly
      final List<String> oldAudio = existingEntry.audioRecordings
          .map((a) => a.path)
          .toList();
      final List<String> newAudio = entry.audioRecordings
          .map((a) => a.path)
          .toList();
      final removedAudio = oldAudio
          .where((o) => !newAudio.contains(o))
          .toList();
      if (removedAudio.isNotEmpty) {
        try {
          await MediaStore.instance.deleteRelativeFiles(removedAudio);
        } catch (_) {}
      }
    }
  }

  Future<void> deleteJournalEntry(ObjectId id) async {
    final realmDb = await realm;
    final entry = realmDb.find<JournalEntryRealm>(id);
    if (entry != null) {
      // Best-effort media cleanup
      try {
        await MediaStore.instance.deleteJournalMedia(id);
      } catch (_) {}
      realmDb.write(() {
        realmDb.delete(entry);
      });
    }
  }

  Future<List<JournalEntryRealm>> getJournalEntriesForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final realmDb = await realm;
    final results = realmDb.all<JournalEntryRealm>().query(
      'createdAt >= \$0 AND createdAt <= \$1 SORT(createdAt DESC)',
      [start, end],
    );
    return results.toList();
  }
}

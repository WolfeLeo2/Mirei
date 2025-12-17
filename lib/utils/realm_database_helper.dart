import 'package:realm/realm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../models/realm_models.dart';
import '../services/media_store.dart';
import '../services/auth_service.dart';

class RealmDatabaseHelper {
  static final RealmDatabaseHelper _instance = RealmDatabaseHelper._internal();
  static Realm? _realm;
  static String? _currentUserId;

  RealmDatabaseHelper._internal();

  factory RealmDatabaseHelper() {
    return _instance;
  }

  /// Get the current user's Realm instance
  Future<Realm> get realm async {
    final userId = await _getCurrentUserId();

    // If user changed or no realm exists, reinitialize
    if (_realm == null || _currentUserId != userId) {
      // Close existing realm if user changed
      if (_realm != null && _currentUserId != userId) {
        _realm!.close();
        _realm = null;
      }
      _currentUserId = userId;
      _realm = await _initRealm(userId);
    }

    return _realm!;
  }

  /// Get current user ID from Supabase Auth
  Future<String> _getCurrentUserId() async {
    // Import at the top of file if not already present
    final authService = AuthService();
    final userId = authService.currentUserId;

    if (userId == null) {
      throw Exception('No authenticated user found. Please sign in first.');
    }

    return userId;
  }

  Future<Realm> _initRealm(String userId) async {
    final directory = await getApplicationDocumentsDirectory();
    // Create user-specific database path
    final realmPath = path.join(directory.path, 'mirei_app_$userId.realm');

    final schemas = [
      MoodEntryRealm.schema,
      JournalEntryRealm.schema,
      UserProfileRealm.schema,
      MemoryEntryRealm.schema,
    ];

    try {
      // Add schema version and migration
      final config = Configuration.local(
        schemas,
        path: realmPath,
        schemaVersion: 9, // Add sync tracking fields
        migrationCallback: (migration, oldSchemaVersion) {
          if (oldSchemaVersion < 8) {
            print('Migrating to schema v8: adding memory entries');
          }
          if (oldSchemaVersion < 9) {
            print('Migrating to schema v9: adding sync tracking fields');
            // Initialize new sync fields for existing entries
            migration.newRealm.all<MoodEntryRealm>().forEach((entry) {
              entry.lastModified = entry.createdAt;
              entry.syncedAt = null; // Mark as not synced
              entry.remoteId = null;
            });
            migration.newRealm.all<JournalEntryRealm>().forEach((entry) {
              entry.lastModified = entry.createdAt;
              entry.syncedAt = null;
              entry.remoteId = null;
            });
            migration.newRealm.all<MemoryEntryRealm>().forEach((entry) {
              entry.lastModified = entry.createdAt;
              entry.syncedAt = null;
              entry.remoteId = null;
            });
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
          schemaVersion: 9,
        );
        return Realm(config);
      } catch (recreateError) {
        print('Failed to recreate database: $recreateError');
        rethrow;
      }
    }
  }

  // DATABASE MAINTENANCE METHODS

  /// Close the current realm connection (call this on logout)
  Future<void> closeRealm() async {
    if (_realm != null) {
      _realm!.close();
      _realm = null;
      _currentUserId = null;
      print('Realm database closed');
    }
  }

  /// Reset database completely for current user (deletes file and recreates)
  Future<void> resetDatabase() async {
    final userId = await _getCurrentUserId();

    if (_realm != null) {
      _realm!.close();
      _realm = null;
      _currentUserId = null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final realmPath = path.join(directory.path, 'mirei_app_$userId.realm');

    final file = File(realmPath);
    if (await file.exists()) {
      await file.delete();
      print('Database file deleted and will be recreated on next access');
    }
  }

  /// Delete all user databases (admin/cleanup function)
  Future<void> deleteAllUserDatabases() async {
    if (_realm != null) {
      _realm!.close();
      _realm = null;
      _currentUserId = null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync();

    for (var file in files) {
      if (file.path.contains('mirei_app_') && file.path.endsWith('.realm')) {
        await File(file.path).delete();
        print('Deleted database: ${file.path}');
      }
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

    final now = DateTime.now().toUtc();
    final moodEntry = MoodEntryRealm(
      ObjectId(),
      mood,
      now,
      now, // lastModified = createdAt for new entries
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

  // MEMORY ENTRY METHODS
  Future<ObjectId> insertMemoryEntry(MemoryEntryRealm entry) async {
    final realmDb = await realm;
    late ObjectId id;

    realmDb.write(() {
      final saved = realmDb.add(entry);
      id = saved.id;
    });

    return id;
  }

  Future<void> updateMemoryEntry(
    ObjectId id, {
    List<String>? imagePaths,
    String? caption,
  }) async {
    final realmDb = await realm;
    final entry = realmDb.find<MemoryEntryRealm>(id);
    if (entry == null) return;

    final existingImages = List<String>.from(entry.imagePaths);

    realmDb.write(() {
      if (caption != null) {
        entry.caption = caption;
      }
      if (imagePaths != null) {
        entry.imagePaths = imagePaths;
      }
    });

    if (imagePaths != null) {
      final removed = existingImages
          .where((oldPath) => !imagePaths.contains(oldPath))
          .toList();
      if (removed.isNotEmpty) {
        try {
          await MediaStore.instance.deleteRelativeFiles(removed);
        } catch (_) {}
      }
    }
  }

  Future<List<MemoryEntryRealm>> getAllMemoryEntries() async {
    final realmDb = await realm;
    final results = realmDb.all<MemoryEntryRealm>().query(
      'TRUEPREDICATE SORT(createdAt DESC)',
    );
    return results.toList();
  }

  Future<void> deleteMemoryEntry(ObjectId id) async {
    final realmDb = await realm;
    final entry = realmDb.find<MemoryEntryRealm>(id);
    if (entry == null) return;

    try {
      await MediaStore.instance.deleteMemoryMedia(id);
    } catch (_) {}

    realmDb.write(() {
      realmDb.delete(entry);
    });
  }
}

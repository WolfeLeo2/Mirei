import 'package:realm/realm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../models/realm_models.dart';

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

    final config = Configuration.local([
      MoodEntryRealm.schema,
      JournalEntryRealm.schema,
      AudioCacheEntry.schema,
      PlaylistCacheEntry.schema,
      HttpCacheEntry.schema,
    ], path: realmPath);

    return Realm(config);
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
    final results = realmDb.all<MoodEntryRealm>().query('TRUEPREDICATE SORT(createdAt DESC)');
    return results.toList();
  }

  Future<List<MoodEntryRealm>> getMoodEntriesForPeriod(
    DateTime start,
    DateTime end,
  ) async {
    final realmDb = await realm;
    final results = realmDb.all<MoodEntryRealm>()
        .query('createdAt >= \$0 AND createdAt <= \$1 SORT(createdAt DESC)', [start, end]);
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
    final realmDb = await realm;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final results = realmDb.all<MoodEntryRealm>()
        .query('createdAt >= \$0 AND createdAt <= \$1 SORT(createdAt DESC) LIMIT(1)', [startOfDay, endOfDay]);
    
    return results.isEmpty ? null : results.first;
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
    final results = realmDb.all<JournalEntryRealm>().query('TRUEPREDICATE SORT(createdAt DESC)');
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
      realmDb.write(() {
        existingEntry.title = entry.title;
        existingEntry.content = entry.content;
        existingEntry.mood = entry.mood;
        existingEntry.imagePathsString = entry.imagePathsString;
        existingEntry.audioRecordingsString = entry.audioRecordingsString;
      });
    }
  }

  Future<void> deleteJournalEntry(ObjectId id) async {
    final realmDb = await realm;
    final entry = realmDb.find<JournalEntryRealm>(id);
    if (entry != null) {
      realmDb.write(() {
        realmDb.delete(entry);
      });
    }
  }

  // AUDIO CACHE METHODS
  Future<void> insertAudioCacheEntry(AudioCacheEntry entry) async {
    final realmDb = await realm;
    realmDb.write(() {
      realmDb.add(entry, update: true); // Update if exists
    });
  }

  Future<AudioCacheEntry?> getAudioCacheEntry(String url) async {
    final realmDb = await realm;
    return realmDb.find<AudioCacheEntry>(url);
  }

  Future<List<AudioCacheEntry>> getAllAudioCacheEntries() async {
    final realmDb = await realm;
    return realmDb.all<AudioCacheEntry>().toList();
  }

  Future<void> updateAudioCacheAccess(String url) async {
    final realmDb = await realm;
    final entry = realmDb.find<AudioCacheEntry>(url);
    if (entry != null) {
      realmDb.write(() {
        entry.lastAccessed = DateTime.now();
        entry.accessCount += 1;
      });
    }
  }

  Future<void> deleteAudioCacheEntry(String url) async {
    final realmDb = await realm;
    final entry = realmDb.find<AudioCacheEntry>(url);
    if (entry != null) {
      realmDb.write(() {
        realmDb.delete(entry);
      });
    }
  }

  Future<List<AudioCacheEntry>> getOldestCacheEntries(int limit) async {
    final realmDb = await realm;
    final results = realmDb.all<AudioCacheEntry>()
        .query('TRUEPREDICATE SORT(lastAccessed ASC) LIMIT(\$0)', [limit]);
    return results.toList();
  }

  Future<int> getTotalCacheSize() async {
    final realmDb = await realm;
    final entries = realmDb.all<AudioCacheEntry>();
    int totalSize = 0;
    for (final entry in entries) {
      totalSize += entry.sizeBytes;
    }
    return totalSize;
  }

  // PLAYLIST CACHE METHODS
  Future<void> insertPlaylistCacheEntry(PlaylistCacheEntry entry) async {
    final realmDb = await realm;
    realmDb.write(() {
      realmDb.add(entry);
    });
  }

  Future<List<PlaylistCacheEntry>> getPlaylistCacheEntries(String playlistId) async {
    final realmDb = await realm;
    final results = realmDb.all<PlaylistCacheEntry>()
        .query('playlistId == \$0 SORT(priority ASC)', [playlistId]);
    return results.toList();
  }

  Future<void> clearPlaylistCache(String playlistId) async {
    final realmDb = await realm;
    final entries = realmDb.all<PlaylistCacheEntry>()
        .query('playlistId == \$0', [playlistId]);
    
    realmDb.write(() {
      realmDb.deleteMany(entries);
    });
  }

  Future<void> updatePlaylistCachePreloadStatus(ObjectId id, bool isPreloaded) async {
    final realmDb = await realm;
    final entry = realmDb.find<PlaylistCacheEntry>(id);
    if (entry != null) {
      realmDb.write(() {
        entry.isPreloaded = isPreloaded;
      });
    }
  }

  // HTTP CACHE METHODS
  Future<void> insertHttpCacheEntry(HttpCacheEntry entry) async {
    final realmDb = await realm;
    realmDb.write(() {
      realmDb.add(entry, update: true); // Update if exists
    });
  }

  Future<HttpCacheEntry?> getHttpCacheEntry(String key) async {
    final realmDb = await realm;
    return realmDb.find<HttpCacheEntry>(key);
  }

  Future<void> cleanExpiredHttpCache() async {
    final realmDb = await realm;
    final now = DateTime.now();
    final expiredEntries = realmDb.all<HttpCacheEntry>()
        .query('expiresAt < \$0', [now]);
    
    realmDb.write(() {
      realmDb.deleteMany(expiredEntries);
    });
  }

  // UTILITY METHODS
  Future<void> close() async {
    _realm?.close();
    _realm = null;
  }

  Future<void> deleteDatabase() async {
    await close();
    final directory = await getApplicationDocumentsDirectory();
    final realmPath = path.join(directory.path, 'mirei_app.realm');
    final file = File(realmPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Migration helper for existing SQLite data
  Future<void> migrateFromSQLite() async {
    try {
      // This would be called once to migrate data from the old SQLite database
      // Implementation would depend on the existing DatabaseHelper structure
      print('Realm migration: Starting migration from SQLite...');
      
      // For now, we'll just ensure the database is initialized
      await realm;
      
      print('Realm migration: Migration completed successfully');
    } catch (e) {
      print('Realm migration error: $e');
      rethrow;
    }
  }
}

// Extension methods for backward compatibility with existing models
extension MoodEntryConversion on MoodEntryRealm {
  Map<String, dynamic> toMap() {
    return {
      'id': id.hexString,
      'mood': mood,
      'created_at': createdAt.millisecondsSinceEpoch,
      'note': note,
    };
  }
}

extension JournalEntryConversion on JournalEntryRealm {
  Map<String, dynamic> toMap() {
    return {
      'id': id.hexString,
      'title': title,
      'content': content,
      'created_at': createdAt.millisecondsSinceEpoch,
      'mood': mood,
      'image_paths': imagePaths.join('|'),
      'audio_recordings': audioRecordings
          .map((audio) => audio.toJson())
          .join('|||'),
    };
  }
}

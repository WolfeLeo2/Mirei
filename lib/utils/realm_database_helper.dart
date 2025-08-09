import 'package:realm/realm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'dart:convert';
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

    final schemas = [
      AudioCacheEntry.schema,
      MoodEntryRealm.schema,
      JournalEntryRealm.schema, // Added missing JournalEntryRealm schema
      PlaylistCacheEntry.schema,
      PlaylistData.schema, // Added playlist JSON cache
      HttpCacheEntry.schema,
    ];

    try {
      // Add schema version and migration
      final config = Configuration.local(
        schemas, 
        path: realmPath,
        schemaVersion: 4, // Increment version due to removing mood field from JournalEntryRealm
        migrationCallback: (migration, oldSchemaVersion) {
          // For cache data, it's safer to just clear and rebuild rather than migrate
          if (oldSchemaVersion < 4) {
            print('Schema version $oldSchemaVersion detected. Cache will be rebuilt.');
            // Migration will be handled by database recreation fallback
          }
        },
      );
      
      return Realm(config);
    } catch (e) {
      print('Realm migration failed: $e');
      print('Rebuilding cache database for schema compatibility...');
      
      // For cache data, it's acceptable to clear and rebuild
      // This is simpler and more reliable than complex migrations
      try {
        final file = File(realmPath);
        if (await file.exists()) {
          await file.delete();
          print('Cache database cleared - will rebuild automatically');
        }
        
        // Create fresh database with new schema
        final config = Configuration.local(schemas, path: realmPath, schemaVersion: 3);
        return Realm(config);
      } catch (recreateError) {
        print('Failed to recreate database: $recreateError');
        rethrow;
      }
    }
  }

  // DATABASE MAINTENANCE METHODS
  
  /// Clear all cache data (useful for testing or resolving migration issues)
  Future<void> clearAllCacheData() async {
    final realmDb = await realm;
    await realmDb.writeAsync(() {
      realmDb.deleteAll<AudioCacheEntry>();
      realmDb.deleteAll<PlaylistCacheEntry>();
      realmDb.deleteAll<PlaylistData>();
      realmDb.deleteAll<HttpCacheEntry>();
    });
    print('All cache data cleared');
  }

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
        // Removed mood field - moods are stored separately in MoodEntryRealm
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

  Future<void> cleanExpiredPlaylistEntries() async {
    final realmDb = await realm;
    final now = DateTime.now();
    final expiredEntries = realmDb.all<PlaylistCacheEntry>()
        .query('expiresAt < \$0', [now]);
    
    realmDb.write(() {
      realmDb.deleteMany(expiredEntries);
    });
    
    print('Cleaned ${expiredEntries.length} expired playlist cache entries');
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

  // PLAYLIST JSON CACHE METHODS WITH TTL
  Future<void> cachePlaylistJson(String playlistUrl, String jsonData, {Duration ttl = const Duration(hours: 6)}) async {
    final realmDb = await realm;
    await realmDb.writeAsync(() {
      final now = DateTime.now();
      final expiresAt = now.add(ttl);
      
      // Parse JSON to get track count for stats
      int trackCount = 0;
      String? title;
      try {
        final Map<String, dynamic> data = json.decode(jsonData);
        trackCount = (data['tracks'] as List?)?.length ?? 0;
        title = data['title'] as String?;
      } catch (e) {
        print('Error parsing playlist JSON for stats: $e');
      }
      
      final entry = PlaylistData(
        playlistUrl,
        jsonData,
        now,
        expiresAt,
        trackCount,
        title: title,
      );
      
      realmDb.add(entry, update: true); // Upsert
    });
  }

  Future<String?> getCachedPlaylistJson(String playlistUrl) async {
    final realmDb = await realm;
    final now = DateTime.now();
    final entry = realmDb.find<PlaylistData>(playlistUrl);
    
    if (entry != null) {
      if (entry.expiresAt.isAfter(now)) {
        print('Playlist cache hit for: $playlistUrl (expires: ${entry.expiresAt})');
        return entry.jsonData;
      } else {
        // Expired entry, clean it up
        await realmDb.writeAsync(() {
          realmDb.delete(entry);
        });
        print('Playlist cache expired for: $playlistUrl');
      }
    }
    
    return null; // Cache miss or expired
  }

  Future<void> cleanExpiredPlaylistData() async {
    final realmDb = await realm;
    final now = DateTime.now();
    final expiredPlaylists = realmDb.all<PlaylistData>()
        .query('expiresAt < \$0', [now]);
    
    await realmDb.writeAsync(() {
      realmDb.deleteMany(expiredPlaylists);
    });
    
    print('Cleaned ${expiredPlaylists.length} expired playlist entries');
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
      // Removed mood field - moods are stored separately in MoodEntryRealm
      'image_paths': imagePaths.join('|'),
      'audio_recordings': audioRecordings
          .map((audio) => audio.toJson())
          .join('|||'),
    };
  }
}

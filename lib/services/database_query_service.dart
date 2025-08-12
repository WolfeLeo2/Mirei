import 'dart:io';
import 'package:realm/realm.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';

/// Optimized database query service with caching and batch operations
class DatabaseQueryService {
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();

  // Query result caching
  static final Map<String, _QueryCache> _queryCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Get mood entries with optimized pagination and caching
  Future<List<MoodEntryRealm>> getMoodEntriesPaginated({
    int offset = 0,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    String? moodFilter,
    bool useCache = true,
  }) async {
    final cacheKey =
        'moods_${offset}_${limit}_${startDate}_${endDate}_$moodFilter';

    if (useCache && _queryCache.containsKey(cacheKey)) {
      final cached = _queryCache[cacheKey]!;
      if (cached.isValid) {
        return cached.data as List<MoodEntryRealm>;
      }
    }

    final realmDb = await _dbHelper.realm;
    RealmResults<MoodEntryRealm> results;

    if (startDate != null && endDate != null) {
      if (moodFilter != null) {
        // Optimized compound query with indexes
        results = realmDb.all<MoodEntryRealm>().query(
          'createdAt >= \$0 AND createdAt <= \$1 AND mood == \$2 SORT(createdAt DESC) LIMIT(\$3)',
          [startDate, endDate, moodFilter, limit],
        );
      } else {
        results = realmDb.all<MoodEntryRealm>().query(
          'createdAt >= \$0 AND createdAt <= \$1 SORT(createdAt DESC) LIMIT(\$2)',
          [startDate, endDate, limit],
        );
      }
    } else {
      results = realmDb.all<MoodEntryRealm>().query(
        'TRUEPREDICATE SORT(createdAt DESC) LIMIT(\$0)',
        [limit],
      );
    }

    final data = results.toList();

    if (useCache) {
      _queryCache[cacheKey] = _QueryCache(
        data,
        DateTime.now().add(_cacheExpiry),
      );
    }

    return data;
  }

  /// Get journal entries with full-text search optimization
  Future<List<JournalEntryRealm>> searchJournalEntries({
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    bool useCache = true,
  }) async {
    final cacheKey =
        'journals_search_${searchTerm}_${startDate}_${endDate}_$limit';

    if (useCache && _queryCache.containsKey(cacheKey)) {
      final cached = _queryCache[cacheKey]!;
      if (cached.isValid) {
        return cached.data as List<JournalEntryRealm>;
      }
    }

    final realmDb = await _dbHelper.realm;
    RealmResults<JournalEntryRealm> results;

    if (searchTerm != null && searchTerm.isNotEmpty) {
      if (startDate != null && endDate != null) {
        // Optimized compound search query
        results = realmDb.all<JournalEntryRealm>().query(
          '(title CONTAINS[c] \$0 OR content CONTAINS[c] \$0) AND createdAt >= \$1 AND createdAt <= \$2 SORT(createdAt DESC) LIMIT(\$3)',
          [searchTerm, startDate, endDate, limit],
        );
      } else {
        results = realmDb.all<JournalEntryRealm>().query(
          '(title CONTAINS[c] \$0 OR content CONTAINS[c] \$0) SORT(createdAt DESC) LIMIT(\$1)',
          [searchTerm, limit],
        );
      }
    } else if (startDate != null && endDate != null) {
      results = realmDb.all<JournalEntryRealm>().query(
        'createdAt >= \$0 AND createdAt <= \$1 SORT(createdAt DESC) LIMIT(\$2)',
        [startDate, endDate, limit],
      );
    } else {
      results = realmDb.all<JournalEntryRealm>().query(
        'TRUEPREDICATE SORT(createdAt DESC) LIMIT(\$0)',
        [limit],
      );
    }

    final data = results.toList();

    if (useCache) {
      _queryCache[cacheKey] = _QueryCache(
        data,
        DateTime.now().add(_cacheExpiry),
      );
    }

    return data;
  }

  /// Optimized mood statistics with aggregation
  Future<Map<String, dynamic>> getMoodStatistics({
    DateTime? startDate,
    DateTime? endDate,
    bool useCache = true,
  }) async {
    final cacheKey = 'mood_stats_${startDate}_$endDate';

    if (useCache && _queryCache.containsKey(cacheKey)) {
      final cached = _queryCache[cacheKey]!;
      if (cached.isValid) {
        return cached.data as Map<String, dynamic>;
      }
    }

    final realmDb = await _dbHelper.realm;
    RealmResults<MoodEntryRealm> results;

    if (startDate != null && endDate != null) {
      results = realmDb.all<MoodEntryRealm>().query(
        'createdAt >= \$0 AND createdAt <= \$1',
        [startDate, endDate],
      );
    } else {
      results = realmDb.all<MoodEntryRealm>();
    }

    // Efficient in-memory aggregation
    final moodCounts = <String, int>{};
    final moodsByDay = <String, List<String>>{};
    var totalEntries = 0;

    for (final entry in results) {
      totalEntries++;

      // Count by mood type
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;

      // Group by day for trend analysis
      final day = _formatDate(entry.createdAt);
      moodsByDay.putIfAbsent(day, () => []).add(entry.mood);
    }

    final stats = {
      'totalEntries': totalEntries,
      'moodCounts': moodCounts,
      'moodsByDay': moodsByDay,
      'uniqueDays': moodsByDay.length,
      'averageEntriesPerDay': moodsByDay.isNotEmpty
          ? totalEntries / moodsByDay.length
          : 0.0,
      'mostCommonMood': moodCounts.isNotEmpty
          ? moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
          : null,
    };

    if (useCache) {
      _queryCache[cacheKey] = _QueryCache(
        stats,
        DateTime.now().add(_cacheExpiry),
      );
    }

    return stats;
  }

  /// Batch operations for better performance
  Future<void> batchInsertMoodEntries(List<MoodEntryRealm> entries) async {
    final realmDb = await _dbHelper.realm;

    await realmDb.writeAsync(() {
      realmDb.addAll(entries);
    });

    // Clear related caches
    _clearCacheByPrefix('moods_');
    _clearCacheByPrefix('mood_stats_');
  }

  /// Batch delete with optimized queries
  Future<int> batchDeleteOldEntries({
    required DateTime cutoffDate,
    int batchSize = 100,
  }) async {
    final realmDb = await _dbHelper.realm;
    var totalDeleted = 0;

    // Delete old mood entries in batches
    while (true) {
      final oldMoods = realmDb.all<MoodEntryRealm>().query(
        'createdAt < \$0 LIMIT(\$1)',
        [cutoffDate, batchSize],
      );

      if (oldMoods.isEmpty) break;

      await realmDb.writeAsync(() {
        realmDb.deleteMany(oldMoods);
      });

      totalDeleted += oldMoods.length;
    }

    // Delete old journal entries in batches
    while (true) {
      final oldJournals = realmDb.all<JournalEntryRealm>().query(
        'createdAt < \$0 LIMIT(\$1)',
        [cutoffDate, batchSize],
      );

      if (oldJournals.isEmpty) break;

      await realmDb.writeAsync(() {
        realmDb.deleteMany(oldJournals);
      });

      totalDeleted += oldJournals.length;
    }

    // Clear all caches after batch delete
    clearAllCaches();

    return totalDeleted;
  }

  /// Optimized cache cleanup with smart LRU
  Future<void> optimizedCacheCleanup({
    int maxCacheSize = 500 * 1024 * 1024, // 500MB
    double cleanupThreshold = 0.8, // Clean when 80% full
  }) async {
    final realmDb = await _dbHelper.realm;

    // Get current cache size efficiently
    final totalSize = await _getTotalCacheSize(realmDb);

    if (totalSize < maxCacheSize * cleanupThreshold) {
      return; // No cleanup needed
    }

    // Smart LRU cleanup - remove least accessed files first
    final targetSize = (maxCacheSize * 0.7).round(); // Clean to 70%
    final toDelete = totalSize - targetSize;

    final oldEntries = realmDb.all<AudioCacheEntry>().query(
      'TRUEPREDICATE SORT(lastAccessed ASC, accessCount ASC)',
    );

    var deletedSize = 0;
    final entriesToDelete = <AudioCacheEntry>[];

    for (final entry in oldEntries) {
      entriesToDelete.add(entry);
      deletedSize += entry.sizeBytes;

      if (deletedSize >= toDelete) break;
    }

    // Batch delete cache entries and files
    await realmDb.writeAsync(() {
      realmDb.deleteMany(entriesToDelete);
    });

    // Delete actual files in background
    _deleteFilesInBackground(entriesToDelete.map((e) => e.localPath).toList());
  }

  /// Get database statistics for monitoring
  Future<Map<String, dynamic>> getDatabaseStats() async {
    final realmDb = await _dbHelper.realm;

    return {
      'moodEntries': realmDb.all<MoodEntryRealm>().length,
      'journalEntries': realmDb.all<JournalEntryRealm>().length,
      'audioCacheEntries': realmDb.all<AudioCacheEntry>().length,
      'playlistCacheEntries': realmDb.all<PlaylistCacheEntry>().length,
      'playlistDataEntries': realmDb.all<PlaylistData>().length,
      'httpCacheEntries': realmDb.all<HttpCacheEntry>().length,
      'totalCacheSize': await _getTotalCacheSize(realmDb),
      'queryCacheSize': _queryCache.length,
    };
  }

  /// Clear query caches
  void clearAllCaches() {
    _queryCache.clear();
  }

  void _clearCacheByPrefix(String prefix) {
    _queryCache.removeWhere((key, value) => key.startsWith(prefix));
  }

  Future<int> _getTotalCacheSize(Realm realmDb) async {
    final entries = realmDb.all<AudioCacheEntry>();
    var totalSize = 0;
    for (final entry in entries) {
      totalSize += entry.sizeBytes;
    }
    return totalSize;
  }

  void _deleteFilesInBackground(List<String> filePaths) {
    // Delete files in background thread to avoid blocking
    Future.microtask(() async {
      for (final filePath in filePaths) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting cache file $filePath: $e');
        }
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Query cache entry
class _QueryCache {
  final dynamic data;
  final DateTime expiresAt;

  _QueryCache(this.data, this.expiresAt);

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

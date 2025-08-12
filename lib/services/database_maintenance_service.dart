import 'dart:async';
import 'dart:io';
import 'package:realm/realm.dart';
import '../models/realm_models.dart';
import '../utils/realm_database_helper.dart';
import 'database_query_service.dart';

/// Automated database maintenance and optimization service
class DatabaseMaintenanceService {
  final RealmDatabaseHelper _dbHelper = RealmDatabaseHelper();
  final DatabaseQueryService _queryService = DatabaseQueryService();

  Timer? _maintenanceTimer;
  bool _isRunning = false;

  // Configuration
  static const Duration _maintenanceInterval = Duration(hours: 6);
  static const Duration _dataRetentionPeriod = Duration(
    days: 365,
  ); // Keep 1 year of data
  static const int _maxCacheSize = 500 * 1024 * 1024; // 500MB
  static const int _batchSize = 100;

  /// Start automated maintenance
  void startAutomatedMaintenance() {
    if (_maintenanceTimer != null) return;

    _maintenanceTimer = Timer.periodic(_maintenanceInterval, (timer) {
      runMaintenance();
    });

    // Run initial maintenance after a delay
    Timer(const Duration(minutes: 5), () => runMaintenance());

    print('Database maintenance service started');
  }

  /// Stop automated maintenance
  void stopAutomatedMaintenance() {
    _maintenanceTimer?.cancel();
    _maintenanceTimer = null;
    print('Database maintenance service stopped');
  }

  /// Run comprehensive database maintenance
  Future<MaintenanceReport> runMaintenance() async {
    if (_isRunning) {
      print('Maintenance already running, skipping...');
      return MaintenanceReport.empty();
    }

    _isRunning = true;
    final startTime = DateTime.now();

    try {
      print('Starting database maintenance...');

      final report = MaintenanceReport();

      // 1. Clean expired cache entries
      report.expiredCacheCleanup = await _cleanExpiredCacheEntries();

      // 2. Optimize audio cache with LRU
      report.audioCacheOptimization = await _optimizeAudioCache();

      // 3. Clean old data based on retention policy
      report.dataRetentionCleanup = await _cleanOldData();

      // 4. Optimize database (compact if needed)
      report.databaseOptimization = await _optimizeDatabase();

      // 5. Update statistics
      report.finalStats = await _queryService.getDatabaseStats();

      final duration = DateTime.now().difference(startTime);
      report.duration = duration;

      print('Database maintenance completed in ${duration.inSeconds}s');
      print('Report: ${report.summary}');

      return report;
    } catch (e, stackTrace) {
      print('Database maintenance error: $e');
      print('Stack trace: $stackTrace');
      return MaintenanceReport.error(e.toString());
    } finally {
      _isRunning = false;
    }
  }

  /// Clean expired cache entries
  Future<CleanupResult> _cleanExpiredCacheEntries() async {
    final realmDb = await _dbHelper.realm;
    final now = DateTime.now();
    var deletedCount = 0;

    // Clean expired playlist cache entries
    final expiredPlaylistEntries = realmDb.all<PlaylistCacheEntry>().query(
      'expiresAt < \$0',
      [now],
    );
    deletedCount += expiredPlaylistEntries.length;

    await realmDb.writeAsync(() {
      realmDb.deleteMany(expiredPlaylistEntries);
    });

    // Clean expired playlist data
    final expiredPlaylistData = realmDb.all<PlaylistData>().query(
      'expiresAt < \$0',
      [now],
    );
    deletedCount += expiredPlaylistData.length;

    await realmDb.writeAsync(() {
      realmDb.deleteMany(expiredPlaylistData);
    });

    // Clean expired HTTP cache
    final expiredHttpCache = realmDb.all<HttpCacheEntry>().query(
      'expiresAt < \$0',
      [now],
    );
    deletedCount += expiredHttpCache.length;

    await realmDb.writeAsync(() {
      realmDb.deleteMany(expiredHttpCache);
    });

    return CleanupResult(
      itemsDeleted: deletedCount,
      description: 'Expired cache entries',
    );
  }

  /// Optimize audio cache using smart LRU algorithm
  Future<CleanupResult> _optimizeAudioCache() async {
    final realmDb = await _dbHelper.realm;

    // Calculate current cache size
    var totalSize = 0;
    final allEntries = realmDb.all<AudioCacheEntry>();
    for (final entry in allEntries) {
      totalSize += entry.sizeBytes;
    }

    if (totalSize <= _maxCacheSize * 0.8) {
      return CleanupResult(
        itemsDeleted: 0,
        description: 'Audio cache within limits ($totalSize bytes)',
      );
    }

    // Smart cleanup: prioritize by access patterns
    final targetSize = (_maxCacheSize * 0.7).round();
    final toDelete = totalSize - targetSize;

    // Get candidates for deletion (least accessed, oldest first)
    final candidates = realmDb.all<AudioCacheEntry>().query(
      'TRUEPREDICATE SORT(accessCount ASC, lastAccessed ASC)',
    );

    var deletedSize = 0;
    var deletedCount = 0;
    final filesToDelete = <String>[];
    final entriesToDelete = <AudioCacheEntry>[];

    for (final entry in candidates) {
      entriesToDelete.add(entry);
      filesToDelete.add(entry.localPath);
      deletedSize += entry.sizeBytes;
      deletedCount++;

      if (deletedSize >= toDelete) break;
    }

    // Delete database entries
    await realmDb.writeAsync(() {
      realmDb.deleteMany(entriesToDelete);
    });

    // Delete files in background
    _deleteFilesInBackground(filesToDelete);

    return CleanupResult(
      itemsDeleted: deletedCount,
      description: 'Audio cache optimized (freed ${deletedSize} bytes)',
    );
  }

  /// Clean old data based on retention policy
  Future<CleanupResult> _cleanOldData() async {
    final cutoffDate = DateTime.now().subtract(_dataRetentionPeriod);

    final deletedCount = await _queryService.batchDeleteOldEntries(
      cutoffDate: cutoffDate,
      batchSize: _batchSize,
    );

    return CleanupResult(
      itemsDeleted: deletedCount,
      description:
          'Old data cleanup (older than ${_dataRetentionPeriod.inDays} days)',
    );
  }

  /// Optimize database structure and performance
  Future<OptimizationResult> _optimizeDatabase() async {
    final realmDb = await _dbHelper.realm;
    final startTime = DateTime.now();

    try {
      // Realm automatically handles compaction, but we can trigger it manually
      // Note: Realm compaction happens automatically, this is more for monitoring

      // Clear query caches to free memory
      _queryService.clearAllCaches();

      // Force garbage collection hint
      // Note: Dart GC is automatic, but we can suggest it

      final duration = DateTime.now().difference(startTime);

      return OptimizationResult(
        success: true,
        duration: duration,
        description: 'Database optimization completed',
      );
    } catch (e) {
      return OptimizationResult(
        success: false,
        duration: DateTime.now().difference(startTime),
        description: 'Database optimization failed: $e',
      );
    }
  }

  /// Delete files in background thread
  void _deleteFilesInBackground(List<String> filePaths) {
    if (filePaths.isEmpty) return;

    Future.microtask(() async {
      for (final filePath in filePaths) {
        try {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting file $filePath: $e');
        }
      }
      print('Deleted ${filePaths.length} cache files in background');
    });
  }

  /// Get maintenance status
  bool get isMaintenanceRunning => _isRunning;
  bool get isAutomatedMaintenanceActive => _maintenanceTimer != null;

  /// Dispose resources
  void dispose() {
    stopAutomatedMaintenance();
  }
}

/// Maintenance operation result
class CleanupResult {
  final int itemsDeleted;
  final String description;

  CleanupResult({required this.itemsDeleted, required this.description});

  @override
  String toString() => '$description: $itemsDeleted items deleted';
}

/// Database optimization result
class OptimizationResult {
  final bool success;
  final Duration duration;
  final String description;

  OptimizationResult({
    required this.success,
    required this.duration,
    required this.description,
  });

  @override
  String toString() => '$description (${duration.inMilliseconds}ms)';
}

/// Comprehensive maintenance report
class MaintenanceReport {
  CleanupResult? expiredCacheCleanup;
  CleanupResult? audioCacheOptimization;
  CleanupResult? dataRetentionCleanup;
  OptimizationResult? databaseOptimization;
  Map<String, dynamic>? finalStats;
  Duration? duration;
  String? error;

  MaintenanceReport();

  MaintenanceReport.empty()
    : expiredCacheCleanup = CleanupResult(
        itemsDeleted: 0,
        description: 'Skipped',
      ),
      audioCacheOptimization = CleanupResult(
        itemsDeleted: 0,
        description: 'Skipped',
      ),
      dataRetentionCleanup = CleanupResult(
        itemsDeleted: 0,
        description: 'Skipped',
      ),
      databaseOptimization = OptimizationResult(
        success: false,
        duration: Duration.zero,
        description: 'Skipped',
      );

  MaintenanceReport.error(this.error);

  String get summary {
    if (error != null) return 'Error: $error';

    final totalDeleted =
        (expiredCacheCleanup?.itemsDeleted ?? 0) +
        (audioCacheOptimization?.itemsDeleted ?? 0) +
        (dataRetentionCleanup?.itemsDeleted ?? 0);

    return 'Deleted $totalDeleted items in ${duration?.inSeconds ?? 0}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'expiredCacheCleanup': expiredCacheCleanup?.toString(),
      'audioCacheOptimization': audioCacheOptimization?.toString(),
      'dataRetentionCleanup': dataRetentionCleanup?.toString(),
      'databaseOptimization': databaseOptimization?.toString(),
      'finalStats': finalStats,
      'duration': duration?.inMilliseconds,
      'error': error,
      'summary': summary,
    };
  }
}

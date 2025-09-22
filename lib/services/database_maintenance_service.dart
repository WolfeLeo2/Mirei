import 'dart:async';
import 'package:realm/realm.dart';
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

      // 1. Clean old data based on retention policy
      report.dataRetentionCleanup = await _cleanOldData();

      // 2. Optimize database (compact if needed)
      report.databaseOptimization = await _optimizeDatabase();

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
      // Clear query caches to free memory
      _queryService.clearAllCaches();

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
  CleanupResult? dataRetentionCleanup;
  OptimizationResult? databaseOptimization;
  Map<String, dynamic>? finalStats;
  Duration? duration;
  String? error;

  MaintenanceReport();

  MaintenanceReport.empty()
    : dataRetentionCleanup = CleanupResult(
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

    final totalDeleted = (dataRetentionCleanup?.itemsDeleted ?? 0);

    return 'Deleted $totalDeleted items in ${duration?.inSeconds ?? 0}s';
  }

  Map<String, dynamic> toMap() {
    return {
      'dataRetentionCleanup': dataRetentionCleanup?.toString(),
      'databaseOptimization': databaseOptimization?.toString(),
      'finalStats': finalStats,
      'duration': duration?.inMilliseconds,
      'error': error,
      'summary': summary,
    };
  }
}

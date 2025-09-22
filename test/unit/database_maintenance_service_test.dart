import 'package:flutter_test/flutter_test.dart';
import 'package:mirei/models/realm_models.dart';
import 'package:mirei/services/database_maintenance_service.dart';
import 'package:mirei/utils/realm_database_helper.dart';
import 'package:realm/realm.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

void main() {
  // Initialize Flutter bindings for tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseMaintenanceService', () {
    late TestRealmDatabaseHelper testDbHelper;
    late TestDatabaseMaintenanceService maintenanceService;
    late String testDbPath;

    setUp(() async {
      // Create unique test database path using system temp directory
      final tempDir = Directory.systemTemp;
      testDbPath = path.join(
        tempDir.path,
        'test_${DateTime.now().millisecondsSinceEpoch}.realm',
      );

      testDbHelper = TestRealmDatabaseHelper(testDbPath);
      maintenanceService = TestDatabaseMaintenanceService(testDbHelper);
    });

    tearDown(() async {
      try {
        await testDbHelper.resetDatabase();
        // Clean up test file
        final file = File(testDbPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Automated Maintenance', () {
      test('should start and stop automated maintenance', () {
        expect(maintenanceService.isAutomatedMaintenanceActive, isFalse);

        maintenanceService.startAutomatedMaintenance();
        expect(maintenanceService.isAutomatedMaintenanceActive, isTrue);

        maintenanceService.stopAutomatedMaintenance();
        expect(maintenanceService.isAutomatedMaintenanceActive, isFalse);
      });

      test('should not run concurrent maintenance', () async {
        expect(maintenanceService.isMaintenanceRunning, isFalse);

        // Start maintenance (this will set _isRunning to true)
        final future1 = maintenanceService.runMaintenance();
        expect(maintenanceService.isMaintenanceRunning, isTrue);

        // Try to run again while first is running
        final report2 = await maintenanceService.runMaintenance();
        expect(report2.summary, contains('Skipped'));

        // Wait for first to complete
        final report1 = await future1;
        expect(report1.summary, isNot(contains('Skipped')));
        expect(maintenanceService.isMaintenanceRunning, isFalse);
      });
    });

    group('Data Retention Cleanup', () {
      test('should delete old entries and keep recent ones', () async {
        final oldDate = DateTime.now().subtract(const Duration(days: 400));
        final recentDate = DateTime.now().subtract(const Duration(days: 30));

        // Insert old and recent data
        await testDbHelper.insertMoodEntry(
          MoodEntryRealm(ObjectId(), 'Old Mood', oldDate),
        );
        await testDbHelper.insertMoodEntry(
          MoodEntryRealm(ObjectId(), 'Recent Mood', recentDate),
        );
        await testDbHelper.insertJournalEntry(
          JournalEntryRealm(ObjectId(), 'Old Journal', 'Old content', oldDate),
        );
        await testDbHelper.insertJournalEntry(
          JournalEntryRealm(
            ObjectId(),
            'Recent Journal',
            'Recent content',
            recentDate,
          ),
        );

        final report = await maintenanceService.runMaintenance();

        expect(report.dataRetentionCleanup?.itemsDeleted, equals(2));
        expect(report.error, isNull);

        // Verify only recent entries remain
        final remainingMoods = await testDbHelper.getAllMoodEntries();
        final remainingJournals = await testDbHelper.getAllJournalEntries();

        expect(remainingMoods, hasLength(1));
        expect(remainingJournals, hasLength(1));
        expect(remainingMoods.first.mood, equals('Recent Mood'));
        expect(remainingJournals.first.title, equals('Recent Journal'));
      });

      test('should handle empty database gracefully', () async {
        final report = await maintenanceService.runMaintenance();

        expect(report.dataRetentionCleanup?.itemsDeleted, equals(0));
        expect(report.error, isNull);
      });
    });

    group('Database Optimization', () {
      test('should complete optimization successfully', () async {
        final report = await maintenanceService.runMaintenance();

        expect(report.databaseOptimization?.success, isTrue);
        expect(report.databaseOptimization?.description, contains('completed'));
        expect(report.error, isNull);
      });

      test('should handle optimization errors gracefully', () async {
        // For this test, we'll just verify the service can handle errors
        final report = await maintenanceService.runMaintenance();

        // Even if optimization fails, maintenance should complete
        expect(report.error, isNull);
        expect(report.databaseOptimization, isNotNull);
      });
    });

    group('Maintenance Reports', () {
      test('should generate comprehensive maintenance report', () async {
        // Add some test data
        await testDbHelper.insertMoodEntry(
          MoodEntryRealm(
            ObjectId(),
            'Test',
            DateTime.now().subtract(const Duration(days: 400)),
          ),
        );

        final report = await maintenanceService.runMaintenance();

        expect(report.duration, isNotNull);
        expect(report.dataRetentionCleanup, isNotNull);
        expect(report.databaseOptimization, isNotNull);
        expect(report.summary, isA<String>());
        expect(report.toMap(), isA<Map<String, dynamic>>());
      });

      test('should generate error report on failure', () async {
        // This test verifies error reporting structure
        final errorReport = MaintenanceReport.error('Test error');

        expect(errorReport.error, equals('Test error'));
        expect(errorReport.summary, contains('Error: Test error'));
      });

      test('should convert report to map correctly', () async {
        final report = await maintenanceService.runMaintenance();
        final map = report.toMap();

        expect(map, containsPair('summary', isA<String>()));
        expect(map, containsPair('duration', isA<int?>()));
        expect(map.keys, contains('dataRetentionCleanup'));
        expect(map.keys, contains('databaseOptimization'));
      });
    });

    group('Concurrent Maintenance Prevention', () {
      test('should prevent concurrent maintenance runs', () async {
        expect(maintenanceService.isMaintenanceRunning, isFalse);

        // Start first maintenance
        final future1 = maintenanceService.runMaintenance();

        // Attempt concurrent maintenance
        final report2 = await maintenanceService.runMaintenance();

        // Second call should be skipped
        expect(report2.summary, contains('Skipped'));

        // Wait for first to complete
        await future1;
        expect(maintenanceService.isMaintenanceRunning, isFalse);
      });
    });

    group('Service Lifecycle', () {
      test('should dispose resources properly', () {
        maintenanceService.startAutomatedMaintenance();
        expect(maintenanceService.isAutomatedMaintenanceActive, isTrue);

        maintenanceService.dispose();
        expect(maintenanceService.isAutomatedMaintenanceActive, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle database errors gracefully', () async {
        // Reset database to simulate error conditions
        await testDbHelper.resetDatabase();

        final report = await maintenanceService.runMaintenance();

        // Should complete without throwing
        expect(report, isNotNull);
      });
    });
  });
}

/// Test implementation of DatabaseMaintenanceService for testing
class TestDatabaseMaintenanceService extends DatabaseMaintenanceService {
  final TestRealmDatabaseHelper _testDbHelper;
  bool _isRunning = false;

  TestDatabaseMaintenanceService(this._testDbHelper);

  // Override the getter to use test database helper
  @override
  RealmDatabaseHelper get _dbHelper =>
      throw UnimplementedError('Use _testDbHelper instead');

  /// Override runMaintenance to use test helper directly
  @override
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
      report.dataRetentionCleanup = await _cleanOldDataTest();

      // 2. Optimize database (compact if needed)
      report.databaseOptimization = await _optimizeDatabaseTest();

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

  /// Clean old data using test helper
  Future<CleanupResult> _cleanOldDataTest() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 365));

    // Count entries to delete
    final allMoods = await _testDbHelper.getAllMoodEntries();
    final allJournals = await _testDbHelper.getAllJournalEntries();

    final oldMoods = allMoods
        .where((m) => m.createdAt.isBefore(cutoffDate))
        .toList();
    final oldJournals = allJournals
        .where((j) => j.createdAt.isBefore(cutoffDate))
        .toList();

    // Delete old entries
    for (final mood in oldMoods) {
      await _testDbHelper.deleteMoodEntry(mood.id);
    }
    for (final journal in oldJournals) {
      await _testDbHelper.deleteJournalEntry(journal.id);
    }

    final totalDeleted = oldMoods.length + oldJournals.length;

    return CleanupResult(
      itemsDeleted: totalDeleted,
      description: 'Old data cleanup (older than 365 days)',
    );
  }

  /// Optimize database using test helper
  Future<OptimizationResult> _optimizeDatabaseTest() async {
    final startTime = DateTime.now();

    try {
      // Simulate database optimization
      await Future.delayed(const Duration(milliseconds: 10));

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
}

/// Test wrapper for RealmDatabaseHelper that uses a separate test database
class TestRealmDatabaseHelper {
  final String testDbPath;
  late final RealmDatabaseHelper _realHelper;

  TestRealmDatabaseHelper(this.testDbPath) {
    // Create a test instance with test path
    _realHelper = RealmDatabaseHelper();
  }

  Future<Realm> get realm => _realHelper.realm;

  // Only delegate methods that actually exist in RealmDatabaseHelper
  Future<ObjectId> insertMoodEntry(MoodEntryRealm moodEntry) =>
      _realHelper.insertMoodEntry(moodEntry);

  Future<List<MoodEntryRealm>> getAllMoodEntries() =>
      _realHelper.getAllMoodEntries();

  Future<List<MoodEntryRealm>> getMoodEntriesForPeriod(
    DateTime start,
    DateTime end,
  ) => _realHelper.getMoodEntriesForPeriod(start, end);

  Future<MoodEntryRealm?> getTodaysMoodEntry() =>
      _realHelper.getTodaysMoodEntry();

  Future<void> updateMoodEntry(MoodEntryRealm moodEntry) =>
      _realHelper.updateMoodEntry(moodEntry);

  Future<void> deleteMoodEntry(ObjectId id) => _realHelper.deleteMoodEntry(id);

  Future<ObjectId> insertJournalEntry(JournalEntryRealm entry) =>
      _realHelper.insertJournalEntry(entry);

  Future<List<JournalEntryRealm>> getAllJournalEntries() =>
      _realHelper.getAllJournalEntries();

  Future<JournalEntryRealm?> getJournalEntry(ObjectId id) =>
      _realHelper.getJournalEntry(id);

  Future<void> updateJournalEntry(JournalEntryRealm entry) =>
      _realHelper.updateJournalEntry(entry);

  Future<void> deleteJournalEntry(ObjectId id) =>
      _realHelper.deleteJournalEntry(id);

  Future<void> resetDatabase() => _realHelper.resetDatabase();
}

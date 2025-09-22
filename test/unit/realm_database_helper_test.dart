import 'package:flutter_test/flutter_test.dart';
import 'package:realm/realm.dart';
import 'package:mirei/models/realm_models.dart';
import 'package:mirei/utils/realm_database_helper.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:mirei/services/journal_mood_integration.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProvider extends PathProviderPlatform {
  final String docsPath;
  _FakePathProvider(this.docsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

void main() {
  group('RealmDatabaseHelper', () {
    late TestRealmDatabaseWrapper dbHelper;
    late String testDbPath;

    setUp(() async {
      // Create a unique test database for each test
      final testDir = Directory.systemTemp.createTempSync('mirei_test_');
      testDbPath = path.join(testDir.path, 'test_mirei.realm');

      // Create test wrapper
      dbHelper = TestRealmDatabaseWrapper(testDbPath);
    });

    tearDown(() async {
      // Clean up test database
      await dbHelper.cleanup();
      try {
        final testFile = File(testDbPath);
        if (await testFile.exists()) {
          await testFile.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Mood Entry Operations', () {
      test('should insert mood entry successfully', () async {
        final moodEntry = MoodEntryRealm(
          ObjectId(),
          'Happy',
          DateTime.now().toUtc(),
        );

        final insertedId = await dbHelper.insertMoodEntry(moodEntry);

        expect(insertedId, isA<ObjectId>());
        expect(insertedId, equals(moodEntry.id));
      });

      test('should retrieve all mood entries', () async {
        // Insert test data
        final mood1 = MoodEntryRealm(
          ObjectId(),
          'Happy',
          DateTime.now().toUtc(),
        );
        final mood2 = MoodEntryRealm(
          ObjectId(),
          'Sad',
          DateTime.now().toUtc().subtract(Duration(hours: 1)),
        );

        await dbHelper.insertMoodEntry(mood1);
        await dbHelper.insertMoodEntry(mood2);

        final allMoods = await dbHelper.getAllMoodEntries();

        expect(allMoods, hasLength(2));
        expect(allMoods.map((m) => m.mood), containsAll(['Happy', 'Sad']));
      });

      test('should get moods for specific date range', () async {
        final now = DateTime.now().toUtc();
        final yesterday = now.subtract(Duration(days: 1));
        final tomorrow = now.add(Duration(days: 1));

        // Insert moods for different days
        final todayMood = MoodEntryRealm(ObjectId(), 'Happy', now);
        final yesterdayMood = MoodEntryRealm(ObjectId(), 'Sad', yesterday);
        final tomorrowMood = MoodEntryRealm(ObjectId(), 'Excited', tomorrow);

        await dbHelper.insertMoodEntry(todayMood);
        await dbHelper.insertMoodEntry(yesterdayMood);
        await dbHelper.insertMoodEntry(tomorrowMood);

        final moodsInRange = await dbHelper.getMoodEntriesForPeriod(
          yesterday.subtract(Duration(hours: 1)),
          now.add(Duration(hours: 1)),
        );

        expect(moodsInRange, hasLength(2));
        expect(moodsInRange.map((m) => m.mood), containsAll(['Happy', 'Sad']));
        expect(moodsInRange.map((m) => m.mood), isNot(contains('Excited')));
      });

      test('should get today\'s mood entry', () async {
        final now = DateTime.now();
        final todayMood = MoodEntryRealm(ObjectId(), 'Content', now.toUtc());

        await dbHelper.insertMoodEntry(todayMood);

        final retrieved = await dbHelper.getTodaysMoodEntry();

        expect(retrieved, isNotNull);
        expect(retrieved!.mood, equals('Content'));
      });

      test('should get all moods for specific date', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Add multiple moods for today
        final mood1 = MoodEntryRealm(ObjectId(), 'Happy', today.toUtc());
        final mood2 = MoodEntryRealm(
          ObjectId(),
          'Neutral',
          today.add(Duration(hours: 6)).toUtc(),
        );
        final mood3 = MoodEntryRealm(
          ObjectId(),
          'Tired',
          today.add(Duration(hours: 20)).toUtc(),
        );

        await dbHelper.insertMoodEntry(mood1);
        await dbHelper.insertMoodEntry(mood2);
        await dbHelper.insertMoodEntry(mood3);

        final todayMoods = await dbHelper.getAllMoodsForDate(today);

        expect(todayMoods, hasLength(3));
        expect(
          todayMoods.map((m) => m.mood),
          containsAll(['Happy', 'Neutral', 'Tired']),
        );
      });

      test('should get latest mood for today', () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        final mood1 = MoodEntryRealm(ObjectId(), 'Happy', today.toUtc());
        final mood2 = MoodEntryRealm(
          ObjectId(),
          'Neutral',
          today.add(Duration(hours: 6)).toUtc(),
        );

        await dbHelper.insertMoodEntry(mood1);
        await dbHelper.insertMoodEntry(mood2);

        final latest = await dbHelper.getLatestMoodToday();

        expect(latest, isNotNull);
        expect(latest!.mood, equals('Neutral'));
      });

      test('should insert enhanced mood entry with context', () async {
        final id = await dbHelper.insertEnhancedMoodEntry(
          mood: 'Anxious',
          intensity: 7,
          context: 'Work stress',
          triggers: ['deadlines', 'meetings'],
          activities: ['meditation', 'walking'],
          location: 'office',
        );

        expect(id, isA<ObjectId>());

        final allMoods = await dbHelper.getAllMoodEntries();
        final insertedMood = allMoods.firstWhere((m) => m.id == id);

        expect(insertedMood.mood, equals('Anxious'));
        expect(insertedMood.intensity, equals(7));
        expect(insertedMood.context, equals('Work stress'));
        expect(insertedMood.triggers, equals('deadlines,meetings'));
        expect(insertedMood.activities, equals('meditation,walking'));
        expect(insertedMood.location, equals('office'));
        expect(insertedMood.sequenceNumber, equals(1));
      });

      test('should update mood entry', () async {
        final original = MoodEntryRealm(
          ObjectId(),
          'Happy',
          DateTime.now().toUtc(),
        );
        final insertedId = await dbHelper.insertMoodEntry(original);

        // Create a new mood entry with updated values
        final updated = MoodEntryRealm(
          insertedId,
          'Ecstatic',
          original.createdAt,
          note: 'Updated note',
          intensity: original.intensity,
          context: original.context,
          triggers: original.triggers,
          activities: original.activities,
          location: original.location,
          checkInType: original.checkInType,
          sequenceNumber: original.sequenceNumber,
        );

        await dbHelper.updateMoodEntry(updated);

        final allMoods = await dbHelper.getAllMoodEntries();
        final result = allMoods.firstWhere((m) => m.id == insertedId);

        expect(result.mood, equals('Ecstatic'));
        expect(result.note, equals('Updated note'));
      });

      test('should delete mood entry', () async {
        final moodEntry = MoodEntryRealm(
          ObjectId(),
          'Happy',
          DateTime.now().toUtc(),
        );
        await dbHelper.insertMoodEntry(moodEntry);

        await dbHelper.deleteMoodEntry(moodEntry.id);

        final allMoods = await dbHelper.getAllMoodEntries();
        expect(allMoods, isEmpty);
      });
    });

    group('Journal Entry Operations', () {
      test('should insert journal entry successfully', () async {
        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Test Title',
          'Test content for journal entry',
          DateTime.now().toUtc(),
        );

        final insertedId = await dbHelper.insertJournalEntry(journalEntry);

        expect(insertedId, isA<ObjectId>());
        expect(insertedId, equals(journalEntry.id));
      });

      test('should retrieve all journal entries', () async {
        final journal1 = JournalEntryRealm(
          ObjectId(),
          'Entry 1',
          'Content 1',
          DateTime.now().toUtc(),
        );
        final journal2 = JournalEntryRealm(
          ObjectId(),
          'Entry 2',
          'Content 2',
          DateTime.now().toUtc().subtract(Duration(hours: 1)),
        );

        await dbHelper.insertJournalEntry(journal1);
        await dbHelper.insertJournalEntry(journal2);

        final allJournals = await dbHelper.getAllJournalEntries();

        expect(allJournals, hasLength(2));
        expect(
          allJournals.map((j) => j.title),
          containsAll(['Entry 1', 'Entry 2']),
        );
      });

      test('should get specific journal entry by ID', () async {
        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Specific Entry',
          'Specific content',
          DateTime.now().toUtc(),
        );

        await dbHelper.insertJournalEntry(journalEntry);

        final retrieved = await dbHelper.getJournalEntry(journalEntry.id);

        expect(retrieved, isNotNull);
        expect(retrieved!.title, equals('Specific Entry'));
        expect(retrieved.content, equals('Specific content'));
      });

      test('should update journal entry', () async {
        final original = JournalEntryRealm(
          ObjectId(),
          'Original Title',
          'Original content',
          DateTime.now().toUtc(),
        );
        final insertedId = await dbHelper.insertJournalEntry(original);

        // Create updated entry
        final updated = JournalEntryRealm(
          insertedId,
          'Updated Title',
          'Updated content',
          original.createdAt,
          imagePathsString: '/path/to/image1.jpg|||/path/to/image2.jpg',
          audioRecordingsString: original.audioRecordingsString,
          entryMood: original.entryMood,
          entryMoodIntensity: original.entryMoodIntensity,
          entryMoodContext: original.entryMoodContext,
        );

        await dbHelper.updateJournalEntry(updated);

        final retrieved = await dbHelper.getJournalEntry(insertedId);

        expect(retrieved!.title, equals('Updated Title'));
        expect(retrieved.content, equals('Updated content'));
        expect(
          retrieved.imagePaths,
          equals(['/path/to/image1.jpg', '/path/to/image2.jpg']),
        );
      });

      test('should delete journal entry', () async {
        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'To Delete',
          'Content to delete',
          DateTime.now().toUtc(),
        );
        final insertedId = await dbHelper.insertJournalEntry(journalEntry);

        await dbHelper.deleteJournalEntry(insertedId);

        final retrieved = await dbHelper.getJournalEntry(insertedId);
        expect(retrieved, isNull);
      });

      test('should get journals for date range', () async {
        final now = DateTime.now().toUtc();
        final yesterday = now.subtract(Duration(days: 1));
        final tomorrow = now.add(Duration(days: 1));

        final todayJournal = JournalEntryRealm(
          ObjectId(),
          'Today',
          'Today content',
          now,
        );
        final yesterdayJournal = JournalEntryRealm(
          ObjectId(),
          'Yesterday',
          'Yesterday content',
          yesterday,
        );
        final tomorrowJournal = JournalEntryRealm(
          ObjectId(),
          'Tomorrow',
          'Tomorrow content',
          tomorrow,
        );

        await dbHelper.insertJournalEntry(todayJournal);
        await dbHelper.insertJournalEntry(yesterdayJournal);
        await dbHelper.insertJournalEntry(tomorrowJournal);

        final journalsInRange = await dbHelper.getJournalEntriesForPeriod(
          yesterday.subtract(Duration(hours: 1)),
          now.add(Duration(hours: 1)),
        );

        expect(journalsInRange, hasLength(2));
        expect(
          journalsInRange.map((j) => j.title),
          containsAll(['Today', 'Yesterday']),
        );
        expect(
          journalsInRange.map((j) => j.title),
          isNot(contains('Tomorrow')),
        );
      });

      test('should update journal mood context', () async {
        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Mood Journal',
          'Content with mood',
          DateTime.now().toUtc(),
        );
        await dbHelper.insertJournalEntry(journalEntry);

        await dbHelper.updateJournalEntryMoodContext(
          journalEntry.id,
          entryMood: 'Reflective',
          entryMoodContext: 'Thinking about life',
        );

        final updated = await dbHelper.getJournalEntry(journalEntry.id);

        expect(updated!.entryMood, equals('Reflective'));
        expect(updated.entryMoodContext, equals('Thinking about life'));
      });
    });

    group('Media Storage and Retrieval', () {
      test('should store and retrieve image paths correctly', () async {
        final imagePaths = [
          '/storage/images/photo1.jpg',
          '/storage/images/photo2.png',
          '/storage/images/photo3.gif',
        ];

        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Photo Journal',
          'Today I took some great photos',
          DateTime.now().toUtc(),
        );

        // Set image paths using the helper setter
        journalEntry.imagePaths = imagePaths;

        final entryId = await dbHelper.insertJournalEntry(journalEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        expect(retrieved!.imagePaths, equals(imagePaths));
        expect(retrieved.imagePathsString, equals(imagePaths.join('|||')));
      });

      test('should handle empty image paths', () async {
        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'No Photos',
          'Just text today',
          DateTime.now().toUtc(),
        );

        final entryId = await dbHelper.insertJournalEntry(journalEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        expect(retrieved!.imagePaths, isEmpty);
        expect(retrieved.imagePathsString, isNull);
      });

      test('should store and retrieve audio recordings correctly', () async {
        final audioRecordings = [
          AudioRecordingData(
            path: '/storage/audio/recording1.m4a',
            duration: const Duration(minutes: 2, seconds: 30),
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
          AudioRecordingData(
            path: '/storage/audio/recording2.wav',
            duration: const Duration(seconds: 45),
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          ),
        ];

        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Voice Notes',
          'Recorded some thoughts',
          DateTime.now().toUtc(),
        );

        // Set audio recordings using the helper setter
        journalEntry.audioRecordings = audioRecordings;

        final entryId = await dbHelper.insertJournalEntry(journalEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        expect(retrieved!.audioRecordings, hasLength(2));

        final retrievedAudio = retrieved.audioRecordings;
        expect(retrievedAudio[0].path, equals('/storage/audio/recording1.m4a'));
        expect(
          retrievedAudio[0].duration,
          equals(const Duration(minutes: 2, seconds: 30)),
        );
        expect(retrievedAudio[1].path, equals('/storage/audio/recording2.wav'));
        expect(retrievedAudio[1].duration, equals(const Duration(seconds: 45)));
      });

      test('should handle empty audio recordings', () async {
        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Silent Entry',
          'No audio today',
          DateTime.now().toUtc(),
        );

        final entryId = await dbHelper.insertJournalEntry(journalEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        expect(retrieved!.audioRecordings, isEmpty);
        expect(retrieved.audioRecordingsString, isNull);
      });

      test('should handle mixed media (images and audio)', () async {
        final imagePaths = ['/storage/img1.jpg', '/storage/img2.png'];
        final audioRecordings = [
          AudioRecordingData(
            path: '/storage/voice1.m4a',
            duration: const Duration(minutes: 1),
            timestamp: DateTime.now(),
          ),
        ];

        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Mixed Media Entry',
          'Photos and voice notes',
          DateTime.now().toUtc(),
        );

        journalEntry.imagePaths = imagePaths;
        journalEntry.audioRecordings = audioRecordings;

        final entryId = await dbHelper.insertJournalEntry(journalEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        expect(retrieved!.imagePaths, equals(imagePaths));
        expect(retrieved.audioRecordings, hasLength(1));
        expect(
          retrieved.audioRecordings[0].path,
          equals('/storage/voice1.m4a'),
        );
      });

      test('should handle corrupted audio recordings gracefully', () async {
        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Corrupted Audio Test',
          'Testing error handling',
          DateTime.now().toUtc(),
          audioRecordingsString: 'invalid_json|||{"malformed":}|||',
        );

        final entryId = await dbHelper.insertJournalEntry(journalEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        // Should gracefully handle corrupted JSON and return empty list
        expect(retrieved!.audioRecordings, isEmpty);
      });

      test('should handle legacy comma-separated image paths', () async {
        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Legacy Format',
          'Old image format',
          DateTime.now().toUtc(),
          imagePathsString: '/path1.jpg,/path2.png,/path3.gif',
        );

        final entryId = await dbHelper.insertJournalEntry(journalEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        expect(
          retrieved!.imagePaths,
          equals(['/path1.jpg', '/path2.png', '/path3.gif']),
        );
      });

      test('should update media files correctly', () async {
        // Create entry with initial media
        final originalEntry = JournalEntryRealm(
          ObjectId(),
          'Original Entry',
          'Original content',
          DateTime.now().toUtc(),
        );

        originalEntry.imagePaths = ['/original/img1.jpg'];
        originalEntry.audioRecordings = [
          AudioRecordingData(
            path: '/original/audio1.m4a',
            duration: const Duration(seconds: 30),
            timestamp: DateTime.now(),
          ),
        ];

        final entryId = await dbHelper.insertJournalEntry(originalEntry);

        // Update with new media
        final updatedEntry = JournalEntryRealm(
          entryId,
          'Updated Entry',
          'Updated content',
          originalEntry.createdAt,
        );

        updatedEntry.imagePaths = ['/updated/img1.jpg', '/updated/img2.png'];
        updatedEntry.audioRecordings = [
          AudioRecordingData(
            path: '/updated/audio1.wav',
            duration: const Duration(minutes: 1),
            timestamp: DateTime.now(),
          ),
          AudioRecordingData(
            path: '/updated/audio2.m4a',
            duration: const Duration(seconds: 45),
            timestamp: DateTime.now(),
          ),
        ];

        await dbHelper.updateJournalEntry(updatedEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        expect(retrieved!.imagePaths, hasLength(2));
        expect(retrieved.imagePaths, contains('/updated/img1.jpg'));
        expect(retrieved.imagePaths, contains('/updated/img2.png'));
        expect(retrieved.audioRecordings, hasLength(2));
        expect(
          retrieved.audioRecordings[0].path,
          equals('/updated/audio1.wav'),
        );
        expect(
          retrieved.audioRecordings[1].path,
          equals('/updated/audio2.m4a'),
        );
      });

      test('should handle special characters in file paths', () async {
        final specialPaths = [
          '/storage/photos/IMG_2023-12-25_15:30:45.jpg',
          '/storage/voice/Recording (1) - Copy.m4a',
          '/storage/documents/My File & Notes.pdf',
        ];

        final journalEntry = JournalEntryRealm(
          ObjectId(),
          'Special Characters',
          'Testing special file names',
          DateTime.now().toUtc(),
        );

        journalEntry.imagePaths = specialPaths;

        final entryId = await dbHelper.insertJournalEntry(journalEntry);
        final retrieved = await dbHelper.getJournalEntry(entryId);

        expect(retrieved, isNotNull);
        expect(retrieved!.imagePaths, equals(specialPaths));
      });
    });

    group('Database Maintenance', () {
      test('should reset database successfully', () async {
        // Add some data
        final moodEntry = MoodEntryRealm(
          ObjectId(),
          'Happy',
          DateTime.now().toUtc(),
        );
        await dbHelper.insertMoodEntry(moodEntry);

        // Reset database
        await dbHelper.resetDatabase();

        // Verify data is gone
        final allMoods = await dbHelper.getAllMoodEntries();
        expect(allMoods, isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle getting mood for non-existent date', () async {
        final futureDate = DateTime(2030, 1, 1);
        final moods = await dbHelper.getAllMoodsForDate(futureDate);
        expect(moods, isEmpty);
      });

      test('should handle getting non-existent journal entry', () async {
        final fakeId = ObjectId();
        final journal = await dbHelper.getJournalEntry(fakeId);
        expect(journal, isNull);
      });

      test('should handle updating non-existent mood entry', () async {
        final fakeMood = MoodEntryRealm(
          ObjectId(),
          'Fake',
          DateTime.now().toUtc(),
        );

        // Should not throw exception
        await dbHelper.updateMoodEntry(fakeMood);
      });

      test('should handle deleting non-existent entries', () async {
        final fakeId = ObjectId();

        // Should not throw exceptions
        await dbHelper.deleteMoodEntry(fakeId);
        await dbHelper.deleteJournalEntry(fakeId);
      });
    });
  });

  group('Integration: JournalMoodIntegration media save/retrieve', () {
    test(
      'should save journal with images and audio and retrieve via DB helper',
      () async {
        // Ensure bindings and fake path provider
        TestWidgetsFlutterBinding.ensureInitialized();
        final tempDir = Directory.systemTemp.createTempSync(
          'mirei_integration_media_',
        );
        PathProviderPlatform.instance = _FakePathProvider(tempDir.path);

        // Arrange
        final integration = JournalMoodIntegration();
        final dbHelper = RealmDatabaseHelper();

        final images = ['/storage/pictures/j1.jpg', '/storage/pictures/j2.png'];
        final audio = [
          {
            'path': '/storage/audio/a1.m4a',
            'duration': const Duration(seconds: 12).inMilliseconds,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          },
          {
            'path': '/storage/audio/a2.wav',
            'duration': const Duration(seconds: 7).inMilliseconds,
            'timestamp': DateTime.now()
                .subtract(const Duration(minutes: 2))
                .millisecondsSinceEpoch,
          },
        ];

        // Act
        final id = await integration.saveJournalWithMoodContext(
          title: 'Integration Media Test',
          content: 'Testing media through integration service',
          entryMood: 'Happy',
          entryMoodContext: 'Felt good writing this',
          imagePaths: images,
          audioRecordings: audio,
        );

        final saved = await dbHelper.getJournalEntry(id);

        // Assert
        expect(saved, isNotNull);
        expect(saved!.imagePaths, equals(images));
        expect(saved.audioRecordings, hasLength(2));
        expect(saved.audioRecordings[0].path, equals('/storage/audio/a1.m4a'));
        expect(saved.audioRecordings[1].path, equals('/storage/audio/a2.wav'));

        // Cleanup
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      },
    );
  });
}

/// Test wrapper that creates an isolated test database
class TestRealmDatabaseWrapper {
  final String testDbPath;
  Realm? _testRealm;

  TestRealmDatabaseWrapper(this.testDbPath);

  Future<Realm> get realm async {
    if (_testRealm != null) return _testRealm!;

    final schemas = [
      MoodEntryRealm.schema,
      JournalEntryRealm.schema,
      UserProfileRealm.schema,
    ];

    final config = Configuration.local(
      schemas,
      path: testDbPath,
      schemaVersion: 7,
    );

    _testRealm = Realm(config);
    return _testRealm!;
  }

  // Delegate methods to actual RealmDatabaseHelper logic
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

  Future<MoodEntryRealm?> getTodaysMoodEntry() async {
    final now = DateTime.now();
    return getMoodsForDate(now);
  }

  Future<MoodEntryRealm?> getMoodsForDate(DateTime date) async {
    final realmDb = await realm;

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

    final results = realmDb.all<MoodEntryRealm>().query(
      'createdAt >= \$0 AND createdAt <= \$1',
      [startOfDay, endOfDay],
    );

    return results.isEmpty ? null : results.first;
  }

  Future<List<MoodEntryRealm>> getAllMoodsForDate(DateTime date) async {
    final realmDb = await realm;

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

  Future<MoodEntryRealm?> getLatestMoodToday() async {
    final todaysMoods = await getAllMoodsForDate(DateTime.now());
    return todaysMoods.isEmpty ? null : todaysMoods.last;
  }

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

  Future<void> updateMoodEntry(MoodEntryRealm moodEntry) async {
    final realmDb = await realm;
    final existingEntry = realmDb.find<MoodEntryRealm>(moodEntry.id);

    if (existingEntry != null) {
      realmDb.write(() {
        existingEntry.mood = moodEntry.mood;
        existingEntry.createdAt = moodEntry.createdAt;
        existingEntry.note = moodEntry.note;
        existingEntry.intensity = moodEntry.intensity;
        existingEntry.context = moodEntry.context;
        existingEntry.triggers = moodEntry.triggers;
        existingEntry.activities = moodEntry.activities;
        existingEntry.location = moodEntry.location;
        existingEntry.checkInType = moodEntry.checkInType;
        existingEntry.sequenceNumber = moodEntry.sequenceNumber;
      });
    }
  }

  Future<MoodEntryRealm?> getMoodEntry(ObjectId id) async {
    final realmDb = await realm;
    return realmDb.find<MoodEntryRealm>(id);
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
      realmDb.write(() {
        existingEntry.title = entry.title;
        existingEntry.content = entry.content;
        existingEntry.imagePathsString = entry.imagePathsString;
        existingEntry.audioRecordingsString = entry.audioRecordingsString;
        existingEntry.entryMood = entry.entryMood;
        existingEntry.entryMoodIntensity = entry.entryMoodIntensity;
        existingEntry.entryMoodContext = entry.entryMoodContext;
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

  Future<void> resetDatabase() async {
    if (_testRealm != null) {
      _testRealm!.close();
      _testRealm = null;
    }

    final file = File(testDbPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> cleanup() async {
    if (_testRealm != null) {
      _testRealm!.close();
      _testRealm = null;
    }
  }

  // Convenience methods for tests
  Future<void> open() async {
    await realm; // Just ensures realm is initialized
  }

  Future<void> close() async {
    await cleanup();
  }

  Future<MoodEntryRealm?> getTodaysMood() async {
    return await getTodaysMoodEntry();
  }
}

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/journal_entry.dart';
import '../models/mood_entry.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mirei_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Create journal entries table
        await db.execute('''
          CREATE TABLE journal_entries(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            mood TEXT,
            image_paths TEXT,
            audio_recordings TEXT
          )
        ''');
        
        // Create moods table
        await db.execute('''
          CREATE TABLE moods(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mood TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            note TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertJournalEntry(JournalEntry entry) async {
    final db = await database;
    return await db.insert('journal_entries', entry.toMap());
  }

  // Mood-specific methods
  Future<int> insertMoodEntry(MoodEntry moodEntry) async {
    final db = await database;
    return await db.insert('moods', moodEntry.toMap());
  }

  Future<List<MoodEntry>> getAllMoodEntries() async {
    final db = await database;
    final maps = await db.query('moods', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) {
      return MoodEntry.fromMap(maps[i]);
    });
  }

  Future<List<MoodEntry>> getMoodEntriesForPeriod(DateTime start, DateTime end) async {
    final db = await database;
    final maps = await db.query(
      'moods',
      where: 'created_at >= ? AND created_at <= ?',
      whereArgs: [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) {
      return MoodEntry.fromMap(maps[i]);
    });
  }

  Future<void> deleteMoodEntry(int id) async {
    final db = await database;
    await db.delete('moods', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<JournalEntry>> getAllJournalEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'journal_entries',
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return JournalEntry.fromMap(maps[i]);
    });
  }

  Future<JournalEntry?> getJournalEntry(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return JournalEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateJournalEntry(JournalEntry entry) async {
    final db = await database;
    return await db.update(
      'journal_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteJournalEntry(int id) async {
    final db = await database;
    return await db.delete(
      'journal_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

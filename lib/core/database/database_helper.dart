import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'word_ping.db');

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wordbooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE word_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word TEXT NOT NULL,
        phonetic TEXT NOT NULL DEFAULT '',
        wordbook_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (wordbook_id) REFERENCES wordbooks(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE meanings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_entry_id INTEGER NOT NULL,
        part_of_speech TEXT NOT NULL,
        definition TEXT NOT NULL,
        example TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (word_entry_id) REFERENCES word_entries(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE alarms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hour INTEGER NOT NULL,
        minute INTEGER NOT NULL,
        repeat_days TEXT NOT NULL DEFAULT '',
        sound_name TEXT NOT NULL DEFAULT 'default_alarm',
        is_enabled INTEGER NOT NULL DEFAULT 1,
        is_quiz_enabled INTEGER NOT NULL DEFAULT 0,
        wordbook_id INTEGER,
        quiz_word_count INTEGER NOT NULL DEFAULT 3,
        created_at TEXT NOT NULL,
        FOREIGN KEY (wordbook_id) REFERENCES wordbooks(id) ON DELETE SET NULL
      )
    ''');
  }
}

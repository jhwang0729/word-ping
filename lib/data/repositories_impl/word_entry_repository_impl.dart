import 'package:sqflite/sqflite.dart';
import '../models/word_entry.dart';
import '../models/meaning.dart';
import '../repositories/word_entry_repository.dart';

class WordEntryRepositoryImpl implements WordEntryRepository {
  final Database db;

  WordEntryRepositoryImpl(this.db);

  @override
  Future<List<WordEntry>> getByWordbookId(int wordbookId) async {
    final entryMaps = await db.query(
      'word_entries',
      where: 'wordbook_id = ?',
      whereArgs: [wordbookId],
      orderBy: 'created_at DESC',
    );

    final entries = <WordEntry>[];
    for (final map in entryMaps) {
      final meaningMaps = await db.query(
        'meanings',
        where: 'word_entry_id = ?',
        whereArgs: [map['id']],
        orderBy: 'order_index ASC',
      );
      final meanings = meaningMaps.map((m) => Meaning.fromMap(m)).toList();
      entries.add(WordEntry.fromMap(map, meanings: meanings));
    }
    return entries;
  }

  @override
  Future<WordEntry?> getById(int id) async {
    final maps = await db.query('word_entries', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final meaningMaps = await db.query(
      'meanings',
      where: 'word_entry_id = ?',
      whereArgs: [id],
      orderBy: 'order_index ASC',
    );
    final meanings = meaningMaps.map((m) => Meaning.fromMap(m)).toList();
    return WordEntry.fromMap(maps.first, meanings: meanings);
  }

  @override
  Future<int> getCountByWordbookId(int wordbookId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM word_entries WHERE wordbook_id = ?',
      [wordbookId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<bool> existsInWordbook(String word, int wordbookId) async {
    final result = await db.query(
      'word_entries',
      where: 'word = ? AND wordbook_id = ?',
      whereArgs: [word.toLowerCase(), wordbookId],
    );
    return result.isNotEmpty;
  }

  @override
  Future<int> insert(WordEntry entry) async {
    final entryId = await db.insert('word_entries', entry.toMap());
    for (final meaning in entry.meanings) {
      await db.insert('meanings', meaning.copyWith(wordEntryId: entryId).toMap());
    }
    return entryId;
  }

  @override
  Future<void> delete(int id) async {
    await db.delete('word_entries', where: 'id = ?', whereArgs: [id]);
  }
}

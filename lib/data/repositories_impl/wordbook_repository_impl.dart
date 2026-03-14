import 'package:sqflite/sqflite.dart';
import '../models/wordbook.dart';
import '../repositories/wordbook_repository.dart';

class WordbookRepositoryImpl implements WordbookRepository {
  final Database db;

  WordbookRepositoryImpl(this.db);

  @override
  Future<List<Wordbook>> getAll() async {
    final maps = await db.query('wordbooks', orderBy: 'created_at DESC');
    return maps.map((m) => Wordbook.fromMap(m)).toList();
  }

  @override
  Future<Wordbook?> getById(int id) async {
    final maps = await db.query('wordbooks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Wordbook.fromMap(maps.first);
  }

  @override
  Future<int> insert(Wordbook wordbook) async {
    return await db.insert('wordbooks', wordbook.toMap());
  }

  @override
  Future<void> delete(int id) async {
    await db.delete('wordbooks', where: 'id = ?', whereArgs: [id]);
  }
}

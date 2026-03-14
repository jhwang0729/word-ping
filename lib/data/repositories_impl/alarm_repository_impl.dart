import 'package:sqflite/sqflite.dart';
import '../models/alarm.dart';
import '../repositories/alarm_repository.dart';

class AlarmRepositoryImpl implements AlarmRepository {
  final Database db;

  AlarmRepositoryImpl(this.db);

  @override
  Future<List<Alarm>> getAll() async {
    final maps = await db.query('alarms', orderBy: 'hour ASC, minute ASC');
    return maps.map((m) => Alarm.fromMap(m)).toList();
  }

  @override
  Future<Alarm?> getById(int id) async {
    final maps = await db.query('alarms', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Alarm.fromMap(maps.first);
  }

  @override
  Future<List<Alarm>> getByWordbookId(int wordbookId) async {
    final maps = await db.query(
      'alarms',
      where: 'wordbook_id = ?',
      whereArgs: [wordbookId],
    );
    return maps.map((m) => Alarm.fromMap(m)).toList();
  }

  @override
  Future<int> insert(Alarm alarm) async {
    return await db.insert('alarms', alarm.toMap());
  }

  @override
  Future<void> update(Alarm alarm) async {
    await db.update(
      'alarms',
      alarm.toMap(),
      where: 'id = ?',
      whereArgs: [alarm.id],
    );
  }

  @override
  Future<void> updateEnabled(int id, bool isEnabled) async {
    await db.update(
      'alarms',
      {'is_enabled': isEnabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> delete(int id) async {
    await db.delete('alarms', where: 'id = ?', whereArgs: [id]);
  }
}

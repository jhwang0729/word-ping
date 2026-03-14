import '../models/alarm.dart';

abstract class AlarmRepository {
  Future<List<Alarm>> getAll();
  Future<Alarm?> getById(int id);
  Future<List<Alarm>> getByWordbookId(int wordbookId);
  Future<int> insert(Alarm alarm);
  Future<void> update(Alarm alarm);
  Future<void> updateEnabled(int id, bool isEnabled);
  Future<void> delete(int id);
}

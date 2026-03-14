import '../models/wordbook.dart';

abstract class WordbookRepository {
  Future<List<Wordbook>> getAll();
  Future<Wordbook?> getById(int id);
  Future<int> insert(Wordbook wordbook);
  Future<void> delete(int id);
}

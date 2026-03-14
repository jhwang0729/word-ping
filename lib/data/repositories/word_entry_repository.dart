import '../models/word_entry.dart';

abstract class WordEntryRepository {
  Future<List<WordEntry>> getByWordbookId(int wordbookId);
  Future<WordEntry?> getById(int id);
  Future<int> getCountByWordbookId(int wordbookId);
  Future<bool> existsInWordbook(String word, int wordbookId);
  Future<int> insert(WordEntry entry);
  Future<void> delete(int id);
}

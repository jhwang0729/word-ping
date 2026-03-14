import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database_provider.dart';
import '../data/datasources/dictionary_api.dart';
import '../data/repositories/wordbook_repository.dart';
import '../data/repositories/word_entry_repository.dart';
import '../data/repositories/alarm_repository.dart';
import '../data/repositories_impl/wordbook_repository_impl.dart';
import '../data/repositories_impl/word_entry_repository_impl.dart';
import '../data/repositories_impl/alarm_repository_impl.dart';

final wordbookRepositoryProvider = FutureProvider<WordbookRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return WordbookRepositoryImpl(db);
});

final wordEntryRepositoryProvider = FutureProvider<WordEntryRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return WordEntryRepositoryImpl(db);
});

final alarmRepositoryProvider = FutureProvider<AlarmRepository>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return AlarmRepositoryImpl(db);
});

final dictionaryApiProvider = Provider<DictionaryApi>((ref) {
  final api = DictionaryApi();
  ref.onDispose(() => api.dispose());
  return api;
});

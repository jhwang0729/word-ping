import 'meaning.dart';

class WordEntry {
  final int? id;
  final String word;
  final String phonetic;
  final int wordbookId;
  final DateTime createdAt;
  final List<Meaning> meanings;

  const WordEntry({
    this.id,
    required this.word,
    this.phonetic = '',
    required this.wordbookId,
    required this.createdAt,
    this.meanings = const [],
  });

  factory WordEntry.fromMap(Map<String, dynamic> map, {List<Meaning>? meanings}) {
    return WordEntry(
      id: map['id'] as int?,
      word: map['word'] as String,
      phonetic: map['phonetic'] as String? ?? '',
      wordbookId: map['wordbook_id'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      meanings: meanings ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'word': word,
      'phonetic': phonetic,
      'wordbook_id': wordbookId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  WordEntry copyWith({
    int? id,
    String? word,
    String? phonetic,
    int? wordbookId,
    DateTime? createdAt,
    List<Meaning>? meanings,
  }) {
    return WordEntry(
      id: id ?? this.id,
      word: word ?? this.word,
      phonetic: phonetic ?? this.phonetic,
      wordbookId: wordbookId ?? this.wordbookId,
      createdAt: createdAt ?? this.createdAt,
      meanings: meanings ?? this.meanings,
    );
  }
}

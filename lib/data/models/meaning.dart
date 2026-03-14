class Meaning {
  final int? id;
  final int wordEntryId;
  final String partOfSpeech;
  final String definition;
  final String? example;
  final int orderIndex;

  const Meaning({
    this.id,
    required this.wordEntryId,
    required this.partOfSpeech,
    required this.definition,
    this.example,
    this.orderIndex = 0,
  });

  factory Meaning.fromMap(Map<String, dynamic> map) {
    return Meaning(
      id: map['id'] as int?,
      wordEntryId: map['word_entry_id'] as int,
      partOfSpeech: map['part_of_speech'] as String,
      definition: map['definition'] as String,
      example: map['example'] as String?,
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'word_entry_id': wordEntryId,
      'part_of_speech': partOfSpeech,
      'definition': definition,
      'example': example,
      'order_index': orderIndex,
    };
  }

  Meaning copyWith({
    int? id,
    int? wordEntryId,
    String? partOfSpeech,
    String? definition,
    String? example,
    int? orderIndex,
  }) {
    return Meaning(
      id: id ?? this.id,
      wordEntryId: wordEntryId ?? this.wordEntryId,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      definition: definition ?? this.definition,
      example: example ?? this.example,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}

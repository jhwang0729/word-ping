class Wordbook {
  final int? id;
  final String name;
  final DateTime createdAt;

  const Wordbook({
    this.id,
    required this.name,
    required this.createdAt,
  });

  factory Wordbook.fromMap(Map<String, dynamic> map) {
    return Wordbook(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Wordbook copyWith({int? id, String? name, DateTime? createdAt}) {
    return Wordbook(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

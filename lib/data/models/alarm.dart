class Alarm {
  final int? id;
  final String name;
  final int hour;
  final int minute;
  final String repeatDays;
  final String soundName;
  final bool isEnabled;
  final bool isQuizEnabled;
  final int? wordbookId;
  final int quizWordCount;
  final DateTime createdAt;

  const Alarm({
    this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.repeatDays = '',
    this.soundName = 'default_alarm',
    this.isEnabled = true,
    this.isQuizEnabled = false,
    this.wordbookId,
    this.quizWordCount = 3,
    required this.createdAt,
  });

  factory Alarm.fromMap(Map<String, dynamic> map) {
    return Alarm(
      id: map['id'] as int?,
      name: map['name'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      repeatDays: map['repeat_days'] as String? ?? '',
      soundName: map['sound_name'] as String? ?? 'default_alarm',
      isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
      isQuizEnabled: (map['is_quiz_enabled'] as int? ?? 0) == 1,
      wordbookId: map['wordbook_id'] as int?,
      quizWordCount: map['quiz_word_count'] as int? ?? 3,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'hour': hour,
      'minute': minute,
      'repeat_days': repeatDays,
      'sound_name': soundName,
      'is_enabled': isEnabled ? 1 : 0,
      'is_quiz_enabled': isQuizEnabled ? 1 : 0,
      'wordbook_id': wordbookId,
      'quiz_word_count': quizWordCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Alarm copyWith({
    int? id,
    String? name,
    int? hour,
    int? minute,
    String? repeatDays,
    String? soundName,
    bool? isEnabled,
    bool? isQuizEnabled,
    int? wordbookId,
    bool clearWordbookId = false,
    int? quizWordCount,
    DateTime? createdAt,
  }) {
    return Alarm(
      id: id ?? this.id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
      soundName: soundName ?? this.soundName,
      isEnabled: isEnabled ?? this.isEnabled,
      isQuizEnabled: isQuizEnabled ?? this.isQuizEnabled,
      wordbookId: clearWordbookId ? null : (wordbookId ?? this.wordbookId),
      quizWordCount: quizWordCount ?? this.quizWordCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  List<int> get repeatDaysList {
    if (repeatDays.isEmpty) return [];
    return repeatDays.split(',').map((e) => int.parse(e.trim())).toList();
  }

  String get formattedTime {
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$period ${displayHour.toString().padLeft(2, '0')}:$displayMinute';
  }

  static const List<String> dayNames = ['일', '월', '화', '수', '목', '금', '토'];

  String get repeatDaysDisplay {
    final days = repeatDaysList;
    if (days.isEmpty) return '한 번';
    if (days.length == 7) return '매일';
    if (const [1, 2, 3, 4, 5].every(days.contains) && days.length == 5) return '평일';
    if (const [0, 6].every(days.contains) && days.length == 2) return '주말';
    return days.map((d) => dayNames[d]).join(' ');
  }
}

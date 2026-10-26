enum DayEventType { birthday, anniversary, exam, other }

class DayEvent {
  final String id;
  final DateTime date;
  final DayEventType type;
  final String title;
  final String description;
  final bool recurring;

  const DayEvent({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    this.description = '',
    this.recurring = false,
  });

  DayEvent copyWith({
    DateTime? date,
    DayEventType? type,
    String? title,
    String? description,
    bool? recurring,
  }) => DayEvent(
    id: id,
    date: date ?? this.date,
    type: type ?? this.type,
    title: title ?? this.title,
    description: description ?? this.description,
    recurring: recurring ?? this.recurring,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'type': type.name,
    'title': title,
    'description': description,
    'recurring': recurring,
  };

  factory DayEvent.fromJson(Map<String, dynamic> json) => DayEvent(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    type: DayEventType.values.byName(json['type'] as String),
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    recurring: json['recurring'] as bool? ?? false,
  );
}

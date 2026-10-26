enum HabitType { timed, regular }

class Habit {
  final String id;
  final String name;
  final HabitType type;
  final int? timeMinutes; // minutes since midnight, only for HabitType.timed
  final bool alarmEnabled;
  final DateTime createdAt;
  final String category;
  final bool active;

  const Habit({
    required this.id,
    required this.name,
    required this.type,
    this.timeMinutes,
    this.alarmEnabled = false,
    required this.createdAt,
    this.category = 'Personal',
    this.active = true,
  });

  Habit copyWith({
    String? name,
    HabitType? type,
    int? timeMinutes,
    bool? clearTime,
    bool? alarmEnabled,
    String? category,
    bool? active,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      timeMinutes: (clearTime ?? false)
          ? null
          : (timeMinutes ?? this.timeMinutes),
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      createdAt: createdAt,
      category: category ?? this.category,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'timeMinutes': timeMinutes,
    'alarmEnabled': alarmEnabled,
    'createdAt': createdAt.toIso8601String(),
    'category': category,
    'active': active,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String,
    type: HabitType.values.byName(json['type'] as String),
    timeMinutes: json['timeMinutes'] as int?,
    alarmEnabled: json['alarmEnabled'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    category: json['category'] as String? ?? 'Personal',
    active: json['active'] as bool? ?? true,
  );
}

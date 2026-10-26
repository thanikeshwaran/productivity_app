import 'reminder_option.dart';

enum TaskType { timed, undated }

class Task {
  final String id;
  final String name;
  final TaskType type;
  final DateTime date;
  final int? timeMinutes; // minutes since midnight, only when type == timed
  final bool flexible;
  final ReminderOption reminder;
  final bool completed;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    this.timeMinutes,
    this.flexible = false,
    this.reminder = ReminderOption.none,
    this.completed = false,
    required this.createdAt,
  });

  /// The task's effective due moment: its exact time when [TaskType.timed],
  /// or a default mid-morning anchor for [TaskType.undated] tasks (which
  /// have no time of their own) - used to compute when a reminder should
  /// fire.
  DateTime get dueDateTime {
    final minutes = type == TaskType.timed ? (timeMinutes ?? 9 * 60) : 9 * 60;
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(minutes: minutes));
  }

  Task copyWith({
    String? name,
    TaskType? type,
    DateTime? date,
    int? timeMinutes,
    bool? clearTime,
    bool? flexible,
    ReminderOption? reminder,
    bool? completed,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      date: date ?? this.date,
      timeMinutes: (clearTime ?? false)
          ? null
          : (timeMinutes ?? this.timeMinutes),
      flexible: flexible ?? this.flexible,
      reminder: reminder ?? this.reminder,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'date': date.toIso8601String(),
    'timeMinutes': timeMinutes,
    'flexible': flexible,
    'reminder': reminder.toJson(),
    'completed': completed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,
    name: json['name'] as String,
    type: TaskType.values.byName(json['type'] as String),
    date: DateTime.parse(json['date'] as String),
    timeMinutes: json['timeMinutes'] as int?,
    flexible: json['flexible'] as bool? ?? false,
    reminder: json['reminder'] == null
        ? ReminderOption.none
        : ReminderOption.fromJson(json['reminder'] as Map<String, dynamic>),
    completed: json['completed'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

enum HabitCompletionStatus { completed, missed, partial, notScheduled }

class HabitCompletion {
  final String id; // '{habitId}_{yyyy-MM-dd}'
  final String habitId;
  final DateTime date;
  final HabitCompletionStatus status;
  final DateTime? completedAt;

  const HabitCompletion({
    required this.id,
    required this.habitId,
    required this.date,
    required this.status,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'habitId': habitId,
    'date': date.toIso8601String(),
    'status': status.name,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory HabitCompletion.fromJson(Map<String, dynamic> json) =>
      HabitCompletion(
        id: json['id'] as String,
        habitId: json['habitId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: HabitCompletionStatus.values.byName(json['status'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );
}

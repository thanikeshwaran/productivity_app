class Achievement {
  final String id;
  final String type; // 'streak_milestone'
  final String habitId;
  final int milestoneDays;
  final DateTime unlockedAt;

  const Achievement({
    required this.id,
    this.type = 'streak_milestone',
    required this.habitId,
    required this.milestoneDays,
    required this.unlockedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'habitId': habitId,
    'milestoneDays': milestoneDays,
    'unlockedAt': unlockedAt.toIso8601String(),
  };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id: json['id'] as String,
    type: json['type'] as String? ?? 'streak_milestone',
    habitId: json['habitId'] as String,
    milestoneDays: json['milestoneDays'] as int,
    unlockedAt: DateTime.parse(json['unlockedAt'] as String),
  );
}

const kStreakMilestones = [3, 7, 14, 21, 25, 30, 50, 100];

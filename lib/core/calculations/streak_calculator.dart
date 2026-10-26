import '../../data/models/habit_completion.dart';
import '../utils/date_utils.dart';

class StreakResult {
  final int currentStreak;
  final int bestStreak;
  final int completedDays;
  final int totalScheduledDays;
  final double completionPercentage;

  const StreakResult({
    required this.currentStreak,
    required this.bestStreak,
    required this.completedDays,
    required this.totalScheduledDays,
    required this.completionPercentage,
  });

  static const empty = StreakResult(
    currentStreak: 0,
    bestStreak: 0,
    completedDays: 0,
    totalScheduledDays: 0,
    completionPercentage: 0,
  );
}

/// Computes streaks and completion stats fresh from stored completion
/// history every time - never incremented in place (CLAUDE.md Section 21).
///
/// A habit is considered "scheduled" every day from its creation date
/// through [today] inclusive (simplest daily-habit model - CLAUDE.md's data
/// model has no weekday-schedule field). Days before creation and days after
/// [today] never count for or against the habit.
StreakResult calculateStreaks({
  required List<HabitCompletion> completions,
  required DateTime habitCreatedAt,
  required DateTime today,
}) {
  final created = AppDateUtils.dateOnly(habitCreatedAt);
  final todayD = AppDateUtils.dateOnly(today);
  if (todayD.isBefore(created)) return StreakResult.empty;

  final statusByDate = <DateTime, HabitCompletionStatus>{
    for (final c in completions) AppDateUtils.dateOnly(c.date): c.status,
  };

  final totalScheduledDays = todayD.difference(created).inDays + 1;

  int completedDays = 0;
  int bestStreak = 0;
  int runningStreak = 0;

  for (int i = 0; i < totalScheduledDays; i++) {
    final day = created.add(Duration(days: i));
    final isCompleted = statusByDate[day] == HabitCompletionStatus.completed;
    if (isCompleted) {
      completedDays++;
      runningStreak++;
      if (runningStreak > bestStreak) bestStreak = runningStreak;
    } else {
      runningStreak = 0;
    }
  }

  int currentStreak = 0;
  DateTime cursor = todayD;
  while (!cursor.isBefore(created) &&
      statusByDate[cursor] == HabitCompletionStatus.completed) {
    currentStreak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final completionPercentage = totalScheduledDays == 0
      ? 0.0
      : (completedDays / totalScheduledDays) * 100;

  return StreakResult(
    currentStreak: currentStreak,
    bestStreak: bestStreak,
    completedDays: completedDays,
    totalScheduledDays: totalScheduledDays,
    completionPercentage: completionPercentage,
  );
}

/// Returns the highest milestone crossed by [bestStreak] that is <= it,
/// or null if no milestone has been reached yet.
int? highestMilestoneReached(int bestStreak, List<int> milestones) {
  int? highest;
  for (final m in milestones) {
    if (bestStreak >= m) highest = m;
  }
  return highest;
}

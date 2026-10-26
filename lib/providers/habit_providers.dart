import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/calculations/streak_calculator.dart';
import '../core/clock/clock.dart';
import '../core/notifications/notification_service.dart';
import '../core/utils/date_utils.dart';
import '../data/models/habit.dart';
import '../data/models/habit_completion.dart';
import '../data/repositories/habit_repository.dart';
import 'misc_providers.dart';

final habitRepositoryProvider = Provider<HabitRepository>(
  (ref) => LocalHabitRepository(),
);
final habitCompletionRepositoryProvider = Provider<HabitCompletionRepository>(
  (ref) => LocalHabitCompletionRepository(),
);

class HabitsNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() => ref.watch(habitRepositoryProvider).loadAll();

  Future<void> addHabit(Habit habit) async {
    final List<Habit> updated = [...?state.value, habit];
    state = AsyncData(updated);
    await ref.read(habitRepositoryProvider).saveAll(updated);
    await _syncAlarm(habit);
  }

  Future<void> updateHabit(Habit habit) async {
    final List<Habit> updated = (state.value ?? const <Habit>[])
        .map((h) => h.id == habit.id ? habit : h)
        .toList();
    state = AsyncData(updated);
    await ref.read(habitRepositoryProvider).saveAll(updated);
    await _syncAlarm(habit);
  }

  Future<void> deleteHabit(String id) async {
    final List<Habit> updated = (state.value ?? const <Habit>[])
        .where((h) => h.id != id)
        .toList();
    state = AsyncData(updated);
    await ref.read(habitRepositoryProvider).saveAll(updated);
    await NotificationService.instance.cancel(notificationIdFor(id));
  }

  /// Cancels any existing alarm for [habit] and reschedules a fresh daily
  /// alarm if it's still enabled - called after every create/update so
  /// editing the time or turning the alarm off never leaves a stale one
  /// behind.
  Future<void> _syncAlarm(Habit habit) async {
    final id = notificationIdFor(habit.id);
    await NotificationService.instance.cancel(id);
    if (!habit.active || !habit.alarmEnabled || habit.timeMinutes == null) {
      return;
    }
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.scheduleDailyAlarm(
      id: id,
      title: 'Time to ${habit.name} 🌱',
      body: "Let's keep the streak going.",
      hour: habit.timeMinutes! ~/ 60,
      minute: habit.timeMinutes! % 60,
    );
  }
}

final habitsProvider = AsyncNotifierProvider<HabitsNotifier, List<Habit>>(
  HabitsNotifier.new,
);

class HabitCompletionsNotifier extends AsyncNotifier<List<HabitCompletion>> {
  @override
  Future<List<HabitCompletion>> build() =>
      ref.watch(habitCompletionRepositoryProvider).loadAll();

  /// Returns the newly-unlocked milestone (days) if this completion just
  /// crossed one, so the caller can show the achievement dialog exactly once
  /// at the moment it's actually earned - not on unrelated navigation
  /// (corrections doc: "don't pop up when just clicking a habit").
  Future<int?> setCompleted({
    required String habitId,
    required DateTime date,
    required bool completed,
  }) async {
    final day = AppDateUtils.dateOnly(date);
    final id = '${habitId}_${AppDateUtils.key(day)}';
    final List<HabitCompletion> current =
        state.value ?? const <HabitCompletion>[];
    List<HabitCompletion> updated;
    if (completed) {
      final entry = HabitCompletion(
        id: id,
        habitId: habitId,
        date: day,
        status: HabitCompletionStatus.completed,
        completedAt: DateTime.now(),
      );
      final idx = current.indexWhere((c) => c.id == id);
      updated = idx >= 0
          ? (List.of(current)..[idx] = entry)
          : [...current, entry];
    } else {
      updated = current.where((c) => c.id != id).toList();
    }
    state = AsyncData(updated);
    await ref.read(habitCompletionRepositoryProvider).saveAll(updated);

    // Recompute from stored history and reconcile achievements every time a
    // completion is written, regardless of which screen triggered it
    // (CLAUDE.md Section 7: completing a habit must update streaks and
    // achievements, not just the checkbox).
    final habit = (ref.read(habitsProvider).value ?? [])
        .where((h) => h.id == habitId)
        .firstOrNull;
    if (habit == null) return null;
    final today = ref.read(todayProvider);
    final streak = calculateStreaks(
      completions: completionsForHabit(updated, habitId),
      habitCreatedAt: habit.createdAt,
      today: today,
    );
    return ref
        .read(achievementsProvider.notifier)
        .reconcile(habitId, streak.bestStreak);
  }
}

final habitCompletionsProvider =
    AsyncNotifierProvider<HabitCompletionsNotifier, List<HabitCompletion>>(
      HabitCompletionsNotifier.new,
    );

List<HabitCompletion> completionsForHabit(
  List<HabitCompletion> all,
  String habitId,
) => all.where((c) => c.habitId == habitId).toList();

bool isCompletedOn(List<HabitCompletion> all, String habitId, DateTime date) =>
    all.any(
      (c) =>
          c.habitId == habitId &&
          AppDateUtils.isSameDay(c.date, date) &&
          c.status == HabitCompletionStatus.completed,
    );

/// Derived, always recalculated from stored history - never a stored counter.
final habitStreakProvider = Provider.family<StreakResult, String>((
  ref,
  habitId,
) {
  final habits = ref.watch(habitsProvider).value ?? [];
  final completions = ref.watch(habitCompletionsProvider).value ?? [];
  final today = ref.watch(todayProvider);
  final habit = habits.where((h) => h.id == habitId).firstOrNull;
  if (habit == null) return StreakResult.empty;
  return calculateStreaks(
    completions: completionsForHabit(completions, habitId),
    habitCreatedAt: habit.createdAt,
    today: today,
  );
});

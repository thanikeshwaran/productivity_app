import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../core/clock/clock.dart';
import '../core/notifications/notification_service.dart';
import '../core/utils/date_utils.dart';
import '../data/models/reminder_option.dart';
import '../data/models/task.dart';
import '../data/repositories/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => LocalTaskRepository(),
);

class TasksNotifier extends AsyncNotifier<List<Task>> {
  @override
  Future<List<Task>> build() => ref.watch(taskRepositoryProvider).loadAll();

  Future<void> addTask(Task task) async {
    final List<Task> updated = [...?state.value, task];
    state = AsyncData(updated);
    await ref.read(taskRepositoryProvider).saveAll(updated);
    await _syncReminder(task);
  }

  Future<void> updateTask(Task task) async {
    final List<Task> updated = (state.value ?? const <Task>[])
        .map((t) => t.id == task.id ? task : t)
        .toList();
    state = AsyncData(updated);
    await ref.read(taskRepositoryProvider).saveAll(updated);
    await _syncReminder(task);
  }

  Future<void> deleteTask(String id) async {
    final List<Task> updated = (state.value ?? const <Task>[])
        .where((t) => t.id != id)
        .toList();
    state = AsyncData(updated);
    await ref.read(taskRepositoryProvider).saveAll(updated);
    await NotificationService.instance.cancel(notificationIdFor(id));
  }

  Future<void> toggleCompleted(String id) async {
    final List<Task> updated = (state.value ?? const <Task>[])
        .map((t) => t.id == id ? t.copyWith(completed: !t.completed) : t)
        .toList();
    state = AsyncData(updated);
    await ref.read(taskRepositoryProvider).saveAll(updated);
    final task = updated.where((t) => t.id == id).firstOrNull;
    if (task != null) await _syncReminder(task);
  }

  /// Cancels any existing scheduled reminder for [task] and reschedules one
  /// if it's still applicable - called after every create/update/completion
  /// toggle so edits never leave a stale notification behind.
  Future<void> _syncReminder(Task task) async {
    final id = notificationIdFor(task.id);
    await NotificationService.instance.cancel(id);
    if (task.completed || task.reminder.type == ReminderType.none) return;
    final leadTime = task.reminder.leadTime;
    if (leadTime == null) return;
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.scheduleOneOff(
      id: id,
      title: "Don't forget: ${task.name}",
      body: 'Coming up soon.',
      dateTime: task.dueDateTime.subtract(leadTime),
    );
  }
}

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<Task>>(
  TasksNotifier.new,
);

List<Task> tasksForDate(List<Task> all, DateTime date) =>
    all.where((t) => AppDateUtils.isSameDay(t.date, date)).toList()..sort(
      (a, b) => (a.timeMinutes ?? 1 << 30).compareTo(b.timeMinutes ?? 1 << 30),
    );

/// What the user should actually see for [date]: on today, incomplete tasks
/// originally dated before today carry forward alongside today's own tasks
/// (CLAUDE.md corrections §11 - "Tasks" backlog), so nothing planned but
/// missed silently disappears. Any other selected date shows its exact-date
/// tasks only, so past/future history is never rewritten.
List<Task> visibleTasksForDate(List<Task> all, DateTime date, DateTime today) {
  if (!AppDateUtils.isSameDay(date, today)) return tasksForDate(all, date);
  final carried = all.where(
    (t) =>
        !t.completed &&
        AppDateUtils.dateOnly(t.date).isBefore(AppDateUtils.dateOnly(today)),
  );
  final todays = tasksForDate(all, today);
  return [...carried, ...todays]..sort(
    (a, b) => (a.timeMinutes ?? 1 << 30).compareTo(b.timeMinutes ?? 1 << 30),
  );
}

/// Selected date for Day Planner / Mark a Day - defaults to today, but is a
/// plain overridable StateProvider so navigating the calendar doesn't drift
/// away from the real current date under the hood.
final selectedPlannerDateProvider = StateProvider<DateTime>(
  (ref) => ref.watch(todayProvider),
);

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/notifications/notification_service.dart';
import '../core/utils/date_utils.dart';
import '../data/models/day_event.dart';
import '../data/repositories/day_event_repository.dart';

final dayEventRepositoryProvider = Provider<DayEventRepository>(
  (ref) => LocalDayEventRepository(),
);

class DayEventsNotifier extends AsyncNotifier<List<DayEvent>> {
  @override
  Future<List<DayEvent>> build() =>
      ref.watch(dayEventRepositoryProvider).loadAll();

  Future<void> addEvent(DayEvent event) async {
    final List<DayEvent> updated = [...?state.value, event];
    state = AsyncData(updated);
    await ref.read(dayEventRepositoryProvider).saveAll(updated);
    await _syncReminder(event);
  }

  Future<void> updateEvent(DayEvent event) async {
    final List<DayEvent> updated = (state.value ?? const <DayEvent>[])
        .map((e) => e.id == event.id ? event : e)
        .toList();
    state = AsyncData(updated);
    await ref.read(dayEventRepositoryProvider).saveAll(updated);
    await _syncReminder(event);
  }

  Future<void> deleteEvent(String id) async {
    final List<DayEvent> updated = (state.value ?? const <DayEvent>[])
        .where((e) => e.id != id)
        .toList();
    state = AsyncData(updated);
    await ref.read(dayEventRepositoryProvider).saveAll(updated);
    await NotificationService.instance.cancel(notificationIdFor(id));
  }

  /// Schedules a 7:00 AM local notification on the event's next occurrence
  /// (this year's date if already passed, next year's for recurring events).
  /// Called on add/update so edits never leave a stale reminder behind.
  Future<void> _syncReminder(DayEvent event) async {
    final id = notificationIdFor(event.id);
    await NotificationService.instance.cancel(id);
    final now = DateTime.now();
    var occurrence = nextOccurrence(event, now);
    final reminderTime = DateTime(
      occurrence.year,
      occurrence.month,
      occurrence.day,
      7,
    );
    final effective = reminderTime.isBefore(now) && event.recurring
        ? DateTime(occurrence.year + 1, occurrence.month, occurrence.day, 7)
        : reminderTime;
    if (effective.isBefore(now)) return;
    await NotificationService.instance.requestPermissions();
    await NotificationService.instance.scheduleOneOff(
      id: id,
      title: event.title,
      body: 'Today is the day 🎉',
      dateTime: effective,
    );
  }
}

final dayEventsProvider =
    AsyncNotifierProvider<DayEventsNotifier, List<DayEvent>>(
      DayEventsNotifier.new,
    );

/// The next occurrence of [event] on/after [from] - handles yearly recurrence
/// for birthdays/anniversaries (Assumption #5 from the architecture review).
DateTime nextOccurrence(DayEvent event, DateTime from) {
  if (!event.recurring) return event.date;
  var next = DateTime(from.year, event.date.month, event.date.day);
  if (next.isBefore(AppDateUtils.dateOnly(from))) {
    next = DateTime(from.year + 1, event.date.month, event.date.day);
  }
  return next;
}

List<DayEvent> eventsOn(List<DayEvent> all, DateTime date) => all.where((e) {
  final occurrence = nextOccurrenceInYear(e, date.year);
  return AppDateUtils.isSameDay(occurrence, date);
}).toList();

DateTime nextOccurrenceInYear(DayEvent event, int year) {
  if (!event.recurring) return event.date;
  return DateTime(year, event.date.month, event.date.day);
}

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules local, on-device notifications for habit alarms (Section 6)
/// and task reminders (Section 5). Deliberately local-only - no backend or
/// push service involved, since these are personal, per-device reminders
/// (see Section 15 of the architecture review).
///
/// A no-op everywhere the plugin has no platform support (web, and any
/// platform before [initialize] has actually been called) so callers never
/// need their own platform checks.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> initialize() async {
    if (!isSupported || _ready) return;

    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );
    _ready = true;
  }

  /// Requests notification (and, on Android 12+, exact-alarm) permission.
  /// Call this once, right before the user creates their first
  /// habit-with-alarm or task-with-reminder - not at cold app launch.
  Future<bool> requestPermissions() async {
    if (!isSupported) return false;
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return granted ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    if (macos != null) {
      return await macos.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return false;
  }

  /// Schedules a notification that repeats every day at [hour]:[minute] -
  /// used for habit alarms.
  Future<void> scheduleDailyAlarm({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!isSupported) return;
    await initialize();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'habit_alarms',
          'Habit Alarms',
          channelDescription: 'Daily habit reminders',
          importance: Importance.max,
          priority: Priority.high,
          // Makes this behave like a real alarm (sound + heads-up even when
          // locked/silenced) instead of a plain notification - the
          // corrections doc's "habit alarms just pop as a notification"
          // fix.
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          fullScreenIntent: true,
          additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT
        ),
        iOS: const DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
        macOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Recurring end-of-day nudge ("gentle reminder to record your progress").
  /// Idempotent - safe to call on every app start.
  Future<void> scheduleEveningJournalReminder() async {
    if (!isSupported) return;
    await initialize();
    const id = 900000;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, 21);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id: id,
      title: 'How did today go?',
      body: 'A gentle reminder to jot down a quick summary of your day.',
      scheduledDate: scheduled,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_journal',
          'Daily Journal Reminder',
          channelDescription: 'End-of-day nudge to record a summary',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules a single, non-repeating notification - used for task
  /// reminders. Silently skipped if [dateTime] has already passed.
  Future<void> scheduleOneOff({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!isSupported) return;
    if (dateTime.isBefore(DateTime.now())) return;
    await initialize();

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(dateTime, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_reminders',
          'Task Reminders',
          channelDescription: 'Task due-date reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancel(int id) async {
    if (!isSupported) return;
    await _plugin.cancel(id: id);
  }
}

/// A deterministic 31-bit notification id derived from an entity's id
/// string, so edits/deletes can find and cancel the existing scheduled
/// notification before rescheduling a new one.
int notificationIdFor(String entityId) => entityId.hashCode & 0x7fffffff;

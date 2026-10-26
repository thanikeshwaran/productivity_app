import 'package:intl/intl.dart';

/// Date helpers used everywhere "today" or a date-key matters.
/// Always operate on the device's local date/time (Section 20 of CLAUDE.md) -
/// never UTC, never a hardcoded date.
class AppDateUtils {
  AppDateUtils._();

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Stable string key ('yyyy-MM-dd') used as a document/storage id.
  static String key(DateTime date) {
    final d = dateOnly(date);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime fromKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String formatLong(DateTime date) =>
      DateFormat('EEEE, MMMM d, y').format(date);

  static String formatMedium(DateTime date) =>
      DateFormat('MMM d, y').format(date);

  static String formatMonthYear(DateTime date) =>
      DateFormat('MMMM y').format(date);

  static String formatTimeOfDay(int minutesSinceMidnight) {
    final h = minutesSinceMidnight ~/ 60;
    final m = minutesSinceMidnight % 60;
    final dt = DateTime(2000, 1, 1, h, m);
    return DateFormat('h:mm a').format(dt);
  }

  static String relativeDescription(DateTime from, DateTime target) {
    final f = dateOnly(from);
    final t = dateOnly(target);
    final diff = t.difference(f).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff > 1 && diff < 7) return 'In $diff days';
    if (diff < -1 && diff > -7) return '${-diff} days ago';
    if (diff >= 7 && diff < 31) return 'In ${(diff / 7).floor()} weeks';
    if (diff >= 31 && diff < 365) return 'In ${(diff / 30).floor()} months';
    if (diff >= 365) return 'In ${(diff / 365).floor()} years';
    return AppDateUtils.formatMedium(target);
  }
}

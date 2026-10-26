import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/date_utils.dart';

/// Thin wrapper around DateTime.now() so streak/date logic is unit-testable
/// with a fixed "today" instead of the real wall clock.
class Clock {
  const Clock();
  DateTime now() => DateTime.now();
}

final clockProvider = Provider<Clock>((ref) => const Clock());

/// Ticks periodically so [todayProvider] re-evaluates across a real midnight
/// rollover without requiring the user to restart the app (Scenario 11).
final _midnightTickerProvider = StreamProvider<void>((ref) {
  return Stream<void>.periodic(const Duration(minutes: 1));
});

/// The current local calendar date (time-of-day stripped). This is the only
/// source of "today" the rest of the app should use.
final todayProvider = Provider<DateTime>((ref) {
  ref.watch(_midnightTickerProvider);
  final now = ref.watch(clockProvider).now();
  return AppDateUtils.dateOnly(now);
});

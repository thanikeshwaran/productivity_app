import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/calculations/streak_calculator.dart';
import '../core/utils/date_utils.dart';
import '../data/models/achievement.dart';
import '../data/models/daily_summary.dart';
import '../data/repositories/misc_repository.dart';

final dailySummaryRepositoryProvider = Provider<DailySummaryRepository>(
  (ref) => LocalDailySummaryRepository(),
);

class DailySummariesNotifier extends AsyncNotifier<List<DailySummary>> {
  @override
  Future<List<DailySummary>> build() =>
      ref.watch(dailySummaryRepositoryProvider).loadAll();

  Future<void> upsert(DateTime date, String summary) async {
    final id = AppDateUtils.key(date);
    final List<DailySummary> current = state.value ?? const <DailySummary>[];
    final entry = DailySummary(
      id: id,
      date: AppDateUtils.dateOnly(date),
      summary: summary,
    );
    final idx = current.indexWhere((s) => s.id == id);
    final List<DailySummary> updated = idx >= 0
        ? (List.of(current)..[idx] = entry)
        : [...current, entry];
    state = AsyncData(updated);
    await ref.read(dailySummaryRepositoryProvider).saveAll(updated);
  }
}

final dailySummariesProvider =
    AsyncNotifierProvider<DailySummariesNotifier, List<DailySummary>>(
      DailySummariesNotifier.new,
    );

final dailySummaryForDateProvider = Provider.family<DailySummary?, DateTime>((
  ref,
  date,
) {
  final all = ref.watch(dailySummariesProvider).value ?? [];
  final key = AppDateUtils.key(date);
  return all.where((s) => s.id == key).firstOrNull;
});

final achievementRepositoryProvider = Provider<AchievementRepository>(
  (ref) => LocalAchievementRepository(),
);

class AchievementsNotifier extends AsyncNotifier<List<Achievement>> {
  @override
  Future<List<Achievement>> build() =>
      ref.watch(achievementRepositoryProvider).loadAll();

  /// Creates a new achievement if [habitId] just crossed a new milestone that
  /// doesn't already have one recorded. Returns the newly unlocked milestone,
  /// or null if nothing new was reached. Called after every completion write.
  Future<int?> reconcile(String habitId, int bestStreak) async {
    final reached = highestMilestoneReached(bestStreak, kStreakMilestones);
    if (reached == null) return null;
    final List<Achievement> current = state.value ?? const <Achievement>[];
    final alreadyUnlocked = current.any(
      (a) => a.habitId == habitId && a.milestoneDays == reached,
    );
    if (alreadyUnlocked) return null;
    final achievement = Achievement(
      id: '${habitId}_$reached',
      habitId: habitId,
      milestoneDays: reached,
      unlockedAt: DateTime.now(),
    );
    final List<Achievement> updated = [...current, achievement];
    state = AsyncData(updated);
    await ref.read(achievementRepositoryProvider).saveAll(updated);
    return reached;
  }
}

final achievementsProvider =
    AsyncNotifierProvider<AchievementsNotifier, List<Achievement>>(
      AchievementsNotifier.new,
    );

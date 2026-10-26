import '../local/json_list_store.dart';
import '../models/achievement.dart';
import '../models/daily_summary.dart';

abstract class DailySummaryRepository {
  Future<List<DailySummary>> loadAll();
  Future<void> saveAll(List<DailySummary> summaries);
}

abstract class AchievementRepository {
  Future<List<Achievement>> loadAll();
  Future<void> saveAll(List<Achievement> achievements);
}

class LocalDailySummaryRepository implements DailySummaryRepository {
  final _store = JsonListStore<DailySummary>(
    prefsKey: 'daily_summaries',
    toJson: (s) => s.toJson(),
    fromJson: DailySummary.fromJson,
  );

  @override
  Future<List<DailySummary>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<DailySummary> summaries) =>
      _store.writeAll(summaries);
}

class LocalAchievementRepository implements AchievementRepository {
  final _store = JsonListStore<Achievement>(
    prefsKey: 'achievements',
    toJson: (a) => a.toJson(),
    fromJson: Achievement.fromJson,
  );

  @override
  Future<List<Achievement>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<Achievement> achievements) =>
      _store.writeAll(achievements);
}

import '../local/json_list_store.dart';
import '../models/habit.dart';
import '../models/habit_completion.dart';

/// Repository interfaces are the only seam that talks to storage. Screens
/// and controllers never import a concrete storage package directly, so a
/// Firestore-backed implementation can replace [LocalHabitRepository] /
/// [LocalHabitCompletionRepository] later without touching any UI code.
abstract class HabitRepository {
  Future<List<Habit>> loadAll();
  Future<void> saveAll(List<Habit> habits);
}

abstract class HabitCompletionRepository {
  Future<List<HabitCompletion>> loadAll();
  Future<void> saveAll(List<HabitCompletion> completions);
}

class LocalHabitRepository implements HabitRepository {
  final _store = JsonListStore<Habit>(
    prefsKey: 'habits',
    toJson: (h) => h.toJson(),
    fromJson: Habit.fromJson,
  );

  @override
  Future<List<Habit>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<Habit> habits) => _store.writeAll(habits);
}

class LocalHabitCompletionRepository implements HabitCompletionRepository {
  final _store = JsonListStore<HabitCompletion>(
    prefsKey: 'habit_completions',
    toJson: (c) => c.toJson(),
    fromJson: HabitCompletion.fromJson,
  );

  @override
  Future<List<HabitCompletion>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<HabitCompletion> completions) =>
      _store.writeAll(completions);
}

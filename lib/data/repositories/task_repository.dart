import '../local/json_list_store.dart';
import '../models/task.dart';

abstract class TaskRepository {
  Future<List<Task>> loadAll();
  Future<void> saveAll(List<Task> tasks);
}

class LocalTaskRepository implements TaskRepository {
  final _store = JsonListStore<Task>(
    prefsKey: 'tasks',
    toJson: (t) => t.toJson(),
    fromJson: Task.fromJson,
  );

  @override
  Future<List<Task>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<Task> tasks) => _store.writeAll(tasks);
}

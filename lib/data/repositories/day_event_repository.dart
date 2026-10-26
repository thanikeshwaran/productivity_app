import '../local/json_list_store.dart';
import '../models/day_event.dart';

abstract class DayEventRepository {
  Future<List<DayEvent>> loadAll();
  Future<void> saveAll(List<DayEvent> events);
}

class LocalDayEventRepository implements DayEventRepository {
  final _store = JsonListStore<DayEvent>(
    prefsKey: 'day_events',
    toJson: (e) => e.toJson(),
    fromJson: DayEvent.fromJson,
  );

  @override
  Future<List<DayEvent>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<DayEvent> events) => _store.writeAll(events);
}

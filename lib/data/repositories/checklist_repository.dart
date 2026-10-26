import '../local/json_list_store.dart';
import '../models/checklist.dart';
import '../models/checklist_item.dart';
import '../models/template.dart';

abstract class ChecklistRepository {
  Future<List<Checklist>> loadAll();
  Future<void> saveAll(List<Checklist> checklists);
}

abstract class ChecklistItemRepository {
  Future<List<ChecklistItem>> loadAll();
  Future<void> saveAll(List<ChecklistItem> items);
}

abstract class UserTemplateRepository {
  Future<List<ChecklistTemplate>> loadAll();
  Future<void> saveAll(List<ChecklistTemplate> templates);
}

class LocalChecklistRepository implements ChecklistRepository {
  final _store = JsonListStore<Checklist>(
    prefsKey: 'checklists',
    toJson: (c) => c.toJson(),
    fromJson: Checklist.fromJson,
  );

  @override
  Future<List<Checklist>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<Checklist> checklists) =>
      _store.writeAll(checklists);
}

class LocalChecklistItemRepository implements ChecklistItemRepository {
  final _store = JsonListStore<ChecklistItem>(
    prefsKey: 'checklist_items',
    toJson: (i) => i.toJson(),
    fromJson: ChecklistItem.fromJson,
  );

  @override
  Future<List<ChecklistItem>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<ChecklistItem> items) => _store.writeAll(items);
}

class LocalUserTemplateRepository implements UserTemplateRepository {
  final _store = JsonListStore<ChecklistTemplate>(
    prefsKey: 'user_templates',
    toJson: (t) => t.toJson(),
    fromJson: ChecklistTemplate.fromJson,
  );

  @override
  Future<List<ChecklistTemplate>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<ChecklistTemplate> templates) =>
      _store.writeAll(templates);
}

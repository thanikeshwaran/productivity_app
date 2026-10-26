import '../local/json_list_store.dart';
import '../models/note.dart';

abstract class NoteRepository {
  Future<List<Note>> loadAll();
  Future<void> saveAll(List<Note> notes);
}

class LocalNoteRepository implements NoteRepository {
  final _store = JsonListStore<Note>(
    prefsKey: 'notes',
    toJson: (n) => n.toJson(),
    fromJson: Note.fromJson,
  );

  @override
  Future<List<Note>> loadAll() => _store.readAll();

  @override
  Future<void> saveAll(List<Note> notes) => _store.writeAll(notes);
}

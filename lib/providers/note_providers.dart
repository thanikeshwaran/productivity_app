import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/models/note.dart';
import '../data/repositories/note_repository.dart';

final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => LocalNoteRepository(),
);

class NotesNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() => ref.watch(noteRepositoryProvider).loadAll();

  Future<void> addNote(Note note) async {
    final List<Note> updated = [...?state.value, note];
    state = AsyncData(updated);
    await ref.read(noteRepositoryProvider).saveAll(updated);
  }

  Future<void> updateNote(Note note) async {
    final List<Note> updated = (state.value ?? const <Note>[])
        .map((n) => n.id == note.id ? note : n)
        .toList();
    state = AsyncData(updated);
    await ref.read(noteRepositoryProvider).saveAll(updated);
  }

  Future<void> deleteNote(String id) async {
    final List<Note> updated = (state.value ?? const <Note>[])
        .where((n) => n.id != id)
        .toList();
    state = AsyncData(updated);
    await ref.read(noteRepositoryProvider).saveAll(updated);
  }

  Future<void> togglePinned(String id) async {
    final List<Note> updated = (state.value ?? const <Note>[])
        .map((n) => n.id == id ? n.copyWith(pinned: !n.pinned) : n)
        .toList();
    state = AsyncData(updated);
    await ref.read(noteRepositoryProvider).saveAll(updated);
  }
}

final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(
  NotesNotifier.new,
);

final noteSearchQueryProvider = StateProvider<String>((ref) => '');
final noteCategoryFilterProvider = StateProvider<String>((ref) => 'All');

final filteredNotesProvider = Provider<List<Note>>((ref) {
  final notes = ref.watch(notesProvider).value ?? [];
  final query = ref.watch(noteSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(noteCategoryFilterProvider);

  var result = notes;
  if (category != 'All') {
    result = result.where((n) => n.category == category).toList();
  }
  if (query.isNotEmpty) {
    result = result
        .where(
          (n) =>
              n.title.toLowerCase().contains(query) ||
              n.content.toLowerCase().contains(query),
        )
        .toList();
  }
  result = [...result]
    ..sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
  return result;
});

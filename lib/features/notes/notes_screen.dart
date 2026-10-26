import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/note.dart';
import '../../providers/note_providers.dart';

enum _NoteSort { newest, oldest, titleAz }

final _noteSortProvider = StateProvider<_NoteSort>((ref) => _NoteSort.newest);

class NotesScreen extends ConsumerWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = [...ref.watch(filteredNotesProvider)];
    final category = ref.watch(noteCategoryFilterProvider);
    final allNotesLoaded = ref.watch(notesProvider).hasValue;
    final sort = ref.watch(_noteSortProvider);

    switch (sort) {
      case _NoteSort.newest:
        notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case _NoteSort.oldest:
        notes.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      case _NoteSort.titleAz:
        notes.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search title or content...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) =>
                    ref.read(noteSearchQueryProvider.notifier).state = v,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_NoteSort>(
              icon: const Icon(Icons.sort),
              initialValue: sort,
              onSelected: (v) => ref.read(_noteSortProvider.notifier).state = v,
              itemBuilder: (context) => const [
                PopupMenuItem(value: _NoteSort.newest, child: Text('Newest')),
                PopupMenuItem(value: _NoteSort.oldest, child: Text('Oldest')),
                PopupMenuItem(
                  value: _NoteSort.titleAz,
                  child: Text('Title A-Z'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kNoteCategories.length + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final label = i == 0 ? 'All' : kNoteCategories[i - 1];
              final selected = category == label;
              return GestureDetector(
                onTap: () =>
                    ref.read(noteCategoryFilterProvider.notifier).state = label,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.navy : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        if (!allNotesLoaded)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (notes.isEmpty)
          const EmptyState(
            message: 'No notes yet.\nCreate your first note.',
            icon: Icons.description_outlined,
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: notes.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) => _NoteCard(note: notes[i]),
          ),
      ],
    );
  }
}

class _NoteCard extends ConsumerWidget {
  const _NoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => GoRouter.of(context).push('/notes/${note.id}'),
      onLongPress: () => _showActions(context, ref),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    note.category,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                if (note.pinned)
                  const Icon(Icons.push_pin, size: 14, color: AppColors.gold),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              note.title,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                note.content,
                style: AppTextStyles.bodyMuted,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              DateFormat('MMM d, h:mm a').format(note.updatedAt),
              style: const TextStyle(fontSize: 10, color: AppColors.navySoft),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                note.pinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(note.pinned ? 'Unpin' : 'Pin'),
              onTap: () => Navigator.of(context).pop('pin'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () => Navigator.of(context).pop('edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.red),
              title: const Text(
                'Delete',
                style: TextStyle(color: AppColors.red),
              ),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    if (action == 'pin') {
      await ref.read(notesProvider.notifier).togglePinned(note.id);
    } else if (action == 'edit') {
      GoRouter.of(context).push('/notes/${note.id}');
    } else if (action == 'delete') {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Delete note?',
        message: 'This removes "${note.title}".',
      );
      if (confirmed) await ref.read(notesProvider.notifier).deleteNote(note.id);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../data/models/note.dart';
import '../../providers/note_providers.dart';

const _uuid = Uuid();

/// Full-page note editor matching the reference mockup: a big date header,
/// an optional reminder link, a thin divider, then Title + full-space body.
/// Replaces the old bottom sheet per the corrections doc (Notes §3).
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, this.noteId});

  final String? noteId;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String _category = kNoteCategories.first;
  DateTime? _reminderAt;
  bool _initialized = false;

  Note? get _editing {
    if (widget.noteId == null) return null;
    final notes = ref.read(notesProvider).value ?? [];
    return notes.where((n) => n.id == widget.noteId).firstOrNull;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }

  void _initFromEditing() {
    if (_initialized) return;
    final editing = _editing;
    if (editing != null) {
      _titleController.text = editing.title;
      _contentController.text = editing.content;
      _category = editing.category;
      _reminderAt = editing.reminderAt;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
    );
    if (time == null) return;
    setState(
      () => _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note title is required')),
      );
      return;
    }
    final editing = _editing;
    final now = DateTime.now();
    final note = Note(
      id: editing?.id ?? _uuid.v4(),
      title: title,
      content: _contentController.text.trim(),
      category: _category,
      pinned: editing?.pinned ?? false,
      createdAt: editing?.createdAt ?? now,
      updatedAt: now,
      reminderAt: _reminderAt,
    );
    if (editing == null) {
      await ref.read(notesProvider.notifier).addNote(note);
    } else {
      await ref.read(notesProvider.notifier).updateNote(note);
    }
    if (_reminderAt != null && _reminderAt!.isAfter(DateTime.now())) {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleOneOff(
        id: notificationIdFor(note.id),
        title: note.title,
        body: 'Note reminder',
        dateTime: _reminderAt!,
      );
    } else {
      await NotificationService.instance.cancel(notificationIdFor(note.id));
    }
    if (!mounted) return;
    if (editing == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('1 Note created.')));
    }
    Navigator.of(context).maybePop();
  }

  Future<void> _showMenu() async {
    final editing = _editing;
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
              leading: const Icon(Icons.ios_share),
              title: const Text('Share'),
              onTap: () => Navigator.of(context).pop('share'),
            ),
            if (editing != null)
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
    if (!mounted || action == null) return;
    if (action == 'share') {
      final text =
          '${_titleController.text.trim()}\n\n${_contentController.text.trim()}';
      await SharePlus.instance.share(ShareParams(text: text));
    } else if (action == 'delete' && editing != null) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Delete note?',
        message: 'This removes "${editing.title}".',
      );
      if (confirmed) {
        await ref.read(notesProvider.notifier).deleteNote(editing.id);
        if (mounted) Navigator.of(context).maybePop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Reads through notesProvider once it's loaded so editing an existing
    // note is pre-filled even though this screen is pushed via go_router
    // (no constructor-time access to the note object itself).
    ref.watch(notesProvider);
    _initFromEditing();

    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _save),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${now.day}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM').format(now),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat('y, EEEE').format(now),
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickReminder,
                child: Row(
                  children: [
                    const Icon(Icons.alarm, size: 18, color: AppColors.blue),
                    const SizedBox(width: 6),
                    Text(
                      _reminderAt == null
                          ? 'Set Reminder'
                          : DateFormat(
                              'MMM d, h:mm a',
                            ).format(_reminderAt!),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: kNoteCategories.map((c) {
                  final selected = c == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.navy
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : AppColors.navy,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
                decoration: const InputDecoration(
                  hintText: 'Title',
                  filled: false,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Note here',
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

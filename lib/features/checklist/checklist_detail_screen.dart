import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/responsive_body.dart';
import '../../providers/checklist_providers.dart';

class ChecklistDetailScreen extends ConsumerStatefulWidget {
  const ChecklistDetailScreen({super.key, required this.checklistId});

  final String checklistId;

  @override
  ConsumerState<ChecklistDetailScreen> createState() =>
      _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends ConsumerState<ChecklistDetailScreen> {
  final _newItemController = TextEditingController();

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final checklists = ref.watch(checklistsProvider).value ?? [];
    final checklist = checklists
        .where((c) => c.id == widget.checklistId)
        .firstOrNull;
    final allItems = ref.watch(checklistItemsProvider).value ?? [];

    if (checklist == null) {
      return const Scaffold(body: Center(child: Text('List not found')));
    }

    final items = itemsForChecklist(allItems, checklist.id);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(checklist.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _renameDialog(checklist.name),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteList,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveBody(
          child: Column(
            children: [
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        message: 'No items yet.\nAdd your first item below.',
                        icon: Icons.checklist_rtl,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              child: const Icon(
                                Icons.delete,
                                color: AppColors.red,
                              ),
                            ),
                            onDismissed: (_) => ref
                                .read(checklistItemsProvider.notifier)
                                .deleteItem(item.id),
                            child: CheckboxListTile(
                              value: item.completed,
                              onChanged: (_) => ref
                                  .read(checklistItemsProvider.notifier)
                                  .toggleItem(item.id),
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(
                                item.text,
                                style: TextStyle(
                                  decoration: item.completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: item.completed
                                      ? AppColors.navySoft
                                      : AppColors.navy,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newItemController,
                        decoration: const InputDecoration(
                          hintText: 'Add item...',
                        ),
                        onSubmitted: (_) => _addItem(checklist.id),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      icon: const Icon(Icons.add),
                      onPressed: () => _addItem(checklist.id),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addItem(String checklistId) async {
    final text = _newItemController.text.trim();
    if (text.isEmpty) return;
    await ref.read(checklistItemsProvider.notifier).addItem(checklistId, text);
    _newItemController.clear();
  }

  Future<void> _renameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Rename list'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref
          .read(checklistsProvider.notifier)
          .rename(widget.checklistId, name);
    }
  }

  Future<void> _deleteList() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete list?',
      message: 'This removes the whole list and its items.',
    );
    if (confirmed) {
      await ref
          .read(checklistsProvider.notifier)
          .deleteChecklist(widget.checklistId);
      if (mounted) Navigator.of(context).maybePop();
    }
  }
}

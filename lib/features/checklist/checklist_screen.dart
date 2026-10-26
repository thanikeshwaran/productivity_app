import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/checklist.dart';
import '../../providers/checklist_providers.dart';
import 'new_list_dialog.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklistsAsync = ref.watch(checklistsProvider);
    final itemsAsync = ref.watch(checklistItemsProvider);
    final query = ref.watch(checklistSearchQueryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: _HubTile(
                label: 'NEW LIST',
                icon: Icons.add,
                color: AppColors.goldSoft,
                onTap: () => showNewChecklistDialog(context, ref),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HubTile(
                label: 'TEMPLATES',
                icon: Icons.folder_open,
                color: AppColors.blueSoft,
                onTap: () => context.push(Routes.checklistTemplates),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search checklists...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) =>
              ref.read(checklistSearchQueryProvider.notifier).state = v,
        ),
        const SizedBox(height: 16),
        checklistsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Text('Failed to load checklists: $e'),
          data: (checklists) {
            final filtered = query.trim().isEmpty
                ? checklists
                : checklists
                      .where(
                        (c) => c.name.toLowerCase().contains(
                          query.trim().toLowerCase(),
                        ),
                      )
                      .toList();
            if (filtered.isEmpty) {
              return const EmptyState(
                message:
                    'No checklists yet.\nCreate a checklist or use a template.',
                icon: Icons.checklist_rtl,
              );
            }
            final items = itemsAsync.value ?? [];
            return Column(
              children: filtered
                  .map(
                    (c) => _ChecklistRow(
                      checklist: c,
                      itemCount: items
                          .where((i) => i.checklistId == c.id)
                          .length,
                      completedCount: items
                          .where((i) => i.checklistId == c.id && i.completed)
                          .length,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.navy, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends ConsumerWidget {
  const _ChecklistRow({
    required this.checklist,
    required this.itemCount,
    required this.completedCount,
  });

  final Checklist checklist;
  final int itemCount;
  final int completedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(Routes.checklistDetail(checklist.id)),
      onLongPress: () async {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete list?',
          message: 'This removes "${checklist.name}" and its items.',
        );
        if (confirmed) {
          await ref
              .read(checklistsProvider.notifier)
              .deleteChecklist(checklist.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    checklist.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '$completedCount / $itemCount done · ${DateFormat('MMM d').format(checklist.updatedAt)}',
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.navySoft),
          ],
        ),
      ),
    );
  }
}

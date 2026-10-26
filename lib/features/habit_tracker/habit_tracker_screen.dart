import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/habit.dart';
import '../../providers/habit_providers.dart';
import 'habit_form_sheet.dart';

enum _HabitSort { name, streak, newest }

final _habitSearchProvider = StateProvider<String>((ref) => '');
final _habitSortProvider = StateProvider<_HabitSort>((ref) => _HabitSort.newest);

class HabitTrackerScreen extends ConsumerWidget {
  const HabitTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);
    final query = ref.watch(_habitSearchProvider);
    final sort = ref.watch(_habitSortProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search habits...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) =>
                    ref.read(_habitSearchProvider.notifier).state = v,
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<_HabitSort>(
              icon: const Icon(Icons.sort),
              initialValue: sort,
              onSelected: (v) => ref.read(_habitSortProvider.notifier).state = v,
              itemBuilder: (context) => const [
                PopupMenuItem(value: _HabitSort.newest, child: Text('Newest')),
                PopupMenuItem(value: _HabitSort.name, child: Text('Name')),
                PopupMenuItem(
                  value: _HabitSort.streak,
                  child: Text('Current streak'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        habitsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Text('Failed to load habits: $e'),
          data: (habits) {
            var filtered = query.trim().isEmpty
                ? habits
                : habits
                      .where(
                        (h) => h.name.toLowerCase().contains(
                          query.trim().toLowerCase(),
                        ),
                      )
                      .toList();
            filtered = [...filtered];
            switch (sort) {
              case _HabitSort.name:
                filtered.sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
              case _HabitSort.newest:
                filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
              case _HabitSort.streak:
                filtered.sort((a, b) {
                  final sa = ref.read(habitStreakProvider(a.id)).currentStreak;
                  final sb = ref.read(habitStreakProvider(b.id)).currentStreak;
                  return sb.compareTo(sa);
                });
            }
            return SectionCard(
              title: 'Current Habits',
              child: habits.isEmpty
                  ? const EmptyState(
                      message: "No habits added yet.\nClick '+' to create new.",
                      icon: Icons.track_changes_outlined,
                    )
                  : filtered.isEmpty
                  ? const EmptyState(
                      message: 'No habits match your search.',
                      icon: Icons.search_off,
                    )
                  : Column(
                      children: filtered.map((h) => _HabitRow(habit: h)).toList(),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _HabitRow extends ConsumerWidget {
  const _HabitRow({required this.habit});

  final Habit habit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(habitStreakProvider(habit.id));

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(Routes.habitDetail(habit.id)),
      onLongPress: () => _showActions(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Icon(
                habit.type == HabitType.timed ? Icons.access_time : Icons.loop,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    habit.type == HabitType.timed && habit.timeMinutes != null
                        ? AppDateUtils.formatTimeOfDay(habit.timeMinutes!)
                        : 'Any time',
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
            if (streak.currentStreak > 0)
              Container(
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '🔥 ${streak.currentStreak}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.bar_chart_outlined, size: 20),
              tooltip: 'Statistics',
              onPressed: () => context.push(Routes.habitDetail(habit.id)),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined, size: 20),
              tooltip: 'Calendar',
              onPressed: () => context.push(Routes.habitDetail(habit.id)),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Edit',
              onPressed: () => showHabitFormSheet(context, ref, editing: habit),
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
    if (action == 'edit') {
      await showHabitFormSheet(context, ref, editing: habit);
    } else if (action == 'delete') {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Delete habit?',
        message: 'This removes "${habit.name}" and its history.',
      );
      if (confirmed) {
        await ref.read(habitsProvider.notifier).deleteHabit(habit.id);
      }
    }
  }
}

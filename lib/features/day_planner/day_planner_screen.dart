import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock/clock.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/task.dart';
import '../../providers/task_providers.dart';
import 'task_form_sheet.dart';

class DayPlannerScreen extends ConsumerWidget {
  const DayPlannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedPlannerDateProvider);
    final today = ref.watch(todayProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                AppDateUtils.formatLong(selectedDate),
                style: AppTextStyles.title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  ref.read(selectedPlannerDateProvider.notifier).state = picked;
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _WeekStrip(selectedDate: selectedDate),
        const SizedBox(height: 20),
        tasksAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, st) => Text('Failed to load tasks: $e'),
          data: (all) {
            final tasks = visibleTasksForDate(all, selectedDate, today);
            return SectionCard(
              title: 'Tasks',
              child: tasks.isEmpty
                  ? const EmptyState(
                      message: "No tasks for this date.\nClick '+' to add.",
                      icon: Icons.event_note_outlined,
                    )
                  : Column(
                      children: tasks.map((t) => _TaskRow(task: t)).toList(),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(const Duration(days: 3));
    final days = List.generate(7, (i) => start.add(Duration(days: i)));

    return SizedBox(
      height: 72,
      child: Consumer(
        builder: (context, ref, _) => ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: days.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final day = days[i];
            final selected = AppDateUtils.isSameDay(day, selectedDate);
            return GestureDetector(
              onTap: () =>
                  ref.read(selectedPlannerDateProvider.notifier).state = day,
              child: Container(
                width: 52,
                decoration: BoxDecoration(
                  color: selected ? AppColors.navy : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _weekdayLabel(day.weekday),
                      style: TextStyle(
                        fontSize: 11,
                        color: selected ? Colors.white70 : AppColors.navySoft,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day.day}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: selected ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  String _weekdayLabel(int weekday) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
}

class _TaskRow extends ConsumerWidget {
  const _TaskRow({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showTaskFormSheet(
        context,
        ref,
        initialDate: task.date,
        editing: task,
      ),
      onLongPress: () => _showActions(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(
              value: task.completed,
              onChanged: (_) =>
                  ref.read(tasksProvider.notifier).toggleCompleted(task.id),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: task.completed
                          ? TextDecoration.lineThrough
                          : null,
                      color: task.completed
                          ? AppColors.navySoft
                          : AppColors.navy,
                    ),
                  ),
                  Text(
                    task.type == TaskType.timed && task.timeMinutes != null
                        ? AppDateUtils.formatTimeOfDay(task.timeMinutes!)
                        : 'Undated · Flexible',
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
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
      await showTaskFormSheet(
        context,
        ref,
        initialDate: task.date,
        editing: task,
      );
    } else if (action == 'delete') {
      final confirmed = await showConfirmDialog(
        context,
        title: 'Delete task?',
        message: 'This removes "${task.name}".',
      );
      if (confirmed) await ref.read(tasksProvider.notifier).deleteTask(task.id);
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock/clock.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../core/widgets/today_toggle.dart';
import '../../data/models/habit.dart';
import '../../providers/habit_providers.dart';
import '../../providers/misc_providers.dart';
import '../../providers/task_providers.dart';
import '../achievements/achievement_dialog.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  int _tabIndex = 0;
  late TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _summaryController = TextEditingController();
  }

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayProvider);
    final existingSummary = ref.watch(dailySummaryForDateProvider(today));
    if (_summaryController.text.isEmpty && existingSummary != null) {
      _summaryController.text = existingSummary.summary;
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            children: [
              Text(AppDateUtils.formatLong(today), style: AppTextStyles.body),
              const SizedBox(height: 20),
              TodayToggle(
                index: _tabIndex,
                onChanged: (i) => setState(() => _tabIndex = i),
              ),
              const SizedBox(height: 24),
              if (_tabIndex == 0) const _TodayHabits() else const _TodayTasks(),
            ],
          ),
        ),
        _DailySummaryBar(
          controller: _summaryController,
          existingSummary: existingSummary?.summary,
          onSubmit: (value) =>
              ref.read(dailySummariesProvider.notifier).upsert(today, value),
        ),
      ],
    );
  }
}

class _TodayHabits extends ConsumerWidget {
  const _TodayHabits();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final completions = ref.watch(habitCompletionsProvider).value ?? [];

    return habitsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Text('Failed to load habits: $e'),
      data: (habits) {
        final scheduled =
            habits
                .where(
                  (h) =>
                      h.active &&
                      !AppDateUtils.dateOnly(h.createdAt).isAfter(today),
                )
                .toList()
              ..sort(
                (a, b) => (a.timeMinutes ?? 1 << 30).compareTo(
                  b.timeMinutes ?? 1 << 30,
                ),
              );
        final incomplete = scheduled
            .where((h) => !isCompletedOn(completions, h.id, today))
            .toList();
        final done = scheduled
            .where((h) => isCompletedOn(completions, h.id, today))
            .toList();

        return SectionCard(
          title: 'Habit',
          child: scheduled.isEmpty
              ? const EmptyState(
                  message: "No habits added yet.\nClick '+' to create new.",
                  icon: Icons.track_changes_outlined,
                )
              : Column(
                  children: [
                    ...incomplete.map(
                      (habit) => _CheckRow(
                        title: habit.name,
                        subtitle:
                            habit.type == HabitType.timed &&
                                habit.timeMinutes != null
                            ? AppDateUtils.formatTimeOfDay(habit.timeMinutes!)
                            : null,
                        checked: false,
                        onTap: () =>
                            context.push(Routes.habitDetail(habit.id)),
                        onToggle: (value) =>
                            _toggle(context, ref, habit.id, today, value),
                      ),
                    ),
                    if (incomplete.isNotEmpty && done.isNotEmpty)
                      const Divider(height: 20, color: AppColors.divider),
                    ...done.map(
                      (habit) => _CheckRow(
                        title: habit.name,
                        subtitle:
                            habit.type == HabitType.timed &&
                                habit.timeMinutes != null
                            ? AppDateUtils.formatTimeOfDay(habit.timeMinutes!)
                            : null,
                        checked: true,
                        onTap: () =>
                            context.push(Routes.habitDetail(habit.id)),
                        onToggle: (value) =>
                            _toggle(context, ref, habit.id, today, value),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    String habitId,
    DateTime today,
    bool value,
  ) async {
    final habits = ref.read(habitsProvider).value ?? [];
    final habit = habits.where((h) => h.id == habitId).firstOrNull;
    final milestone = await ref
        .read(habitCompletionsProvider.notifier)
        .setCompleted(habitId: habitId, date: today, completed: value);
    if (milestone != null && habit != null && context.mounted) {
      await showAchievementUnlockedDialog(
        context,
        habitName: habit.name,
        milestoneDays: milestone,
      );
    }
  }
}

class _TodayTasks extends ConsumerWidget {
  const _TodayTasks();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return tasksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Text('Failed to load tasks: $e'),
      data: (all) {
        final todays = visibleTasksForDate(all, today, today);
        final incomplete = todays.where((t) => !t.completed).toList();
        final done = todays.where((t) => t.completed).toList();
        return SectionCard(
          title: "Today's Tasks",
          trailing: TextButton(
            onPressed: () => context.go(Routes.dayPlanner),
            child: const Text('View all tasks →'),
          ),
          child: todays.isEmpty
              ? const EmptyState(
                  message: 'No tasks for this date.\nClick \'+\' to add.',
                  icon: Icons.check_circle_outline,
                )
              : Column(
                  children: [
                    ...incomplete.map(
                      (task) => _CheckRow(
                        title: task.name,
                        subtitle: task.timeMinutes != null
                            ? AppDateUtils.formatTimeOfDay(task.timeMinutes!)
                            : null,
                        checked: false,
                        onToggle: (_) => ref
                            .read(tasksProvider.notifier)
                            .toggleCompleted(task.id),
                      ),
                    ),
                    if (incomplete.isNotEmpty && done.isNotEmpty)
                      const Divider(height: 20, color: AppColors.divider),
                    ...done.map(
                      (task) => _CheckRow(
                        title: task.name,
                        subtitle: task.timeMinutes != null
                            ? AppDateUtils.formatTimeOfDay(task.timeMinutes!)
                            : null,
                        checked: true,
                        onToggle: (_) => ref
                            .read(tasksProvider.notifier)
                            .toggleCompleted(task.id),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.title,
    this.subtitle,
    required this.checked,
    required this.onToggle,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool checked;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: checked ? 0.5 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Checkbox(value: checked, onChanged: (v) => onToggle(v ?? false)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailySummaryBar extends StatefulWidget {
  const _DailySummaryBar({
    required this.controller,
    required this.existingSummary,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? existingSummary;
  final ValueChanged<String> onSubmit;

  @override
  State<_DailySummaryBar> createState() => _DailySummaryBarState();
}

class _DailySummaryBarState extends State<_DailySummaryBar> {
  bool _expanded = false;
  bool? _submittedOverride;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final eligible = now.hour >= 18;
    if (!eligible) return const SizedBox.shrink();

    if (!_expanded) {
      return SafeArea(
        top: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () => setState(() => _expanded = true),
              child: Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final submitted =
        _submittedOverride ?? (widget.existingSummary != null);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: TextField(
        controller: widget.controller,
        readOnly: submitted,
        decoration: InputDecoration(
          hintText: 'Add a summary about the day',
          suffixIcon: IconButton(
            icon: Icon(
              submitted ? Icons.edit : Icons.check,
              color: submitted
                  ? AppColors.navySoft.withValues(alpha: 0.5)
                  : AppColors.navy,
            ),
            onPressed: () {
              if (submitted) {
                setState(() => _submittedOverride = false);
              } else {
                widget.onSubmit(widget.controller.text.trim());
                setState(() => _submittedOverride = true);
              }
            },
          ),
        ),
        onSubmitted: (v) {
          widget.onSubmit(v);
          setState(() => _submittedOverride = true);
        },
      ),
    );
  }
}

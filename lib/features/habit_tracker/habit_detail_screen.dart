import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/calculations/streak_calculator.dart';
import '../../core/clock/clock.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/responsive_body.dart';
import '../../data/models/achievement.dart';
import '../../providers/habit_providers.dart';
import '../../providers/misc_providers.dart';
import '../achievements/achievement_dialog.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({super.key, required this.habitId});

  final String habitId;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  // Seeded from the live value on first build (not left null) so opening a
  // habit that already has achievements never reads as "new" ones just
  // unlocked - achievements are only surfaced by the completion action
  // itself now (see today_screen.dart), this listener is a safety net for
  // achievements unlocked while this screen happens to be open.
  List<Achievement>? _previousAchievements;
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final habits = ref.watch(habitsProvider).value ?? [];
    final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;
    final completions = ref.watch(habitCompletionsProvider).value ?? [];
    final today = ref.watch(todayProvider);

    if (!_seeded) {
      _previousAchievements = ref.read(achievementsProvider).value ?? [];
      _seeded = true;
    }

    ref.listen(achievementsProvider, (previous, next) {
      final list = next.value;
      if (list == null) return;
      final mine = list.where((a) => a.habitId == widget.habitId).toList();
      final prevMine = (_previousAchievements ?? [])
          .where((a) => a.habitId == widget.habitId)
          .toList();
      _previousAchievements = list;
      if (mine.length > prevMine.length && habit != null) {
        final newest = mine.reduce(
          (a, b) => a.milestoneDays > b.milestoneDays ? a : b,
        );
        showAchievementUnlockedDialog(
          context,
          habitName: habit.name,
          milestoneDays: newest.milestoneDays,
        );
      }
    });

    if (habit == null) {
      return const Scaffold(body: Center(child: Text('Habit not found')));
    }

    final streak = calculateStreaks(
      completions: completionsForHabit(completions, habit.id),
      habitCreatedAt: habit.createdAt,
      today: today,
    );
    final milestone = highestMilestoneReached(
      streak.bestStreak,
      kStreakMilestones,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              Text(habit.name, style: AppTextStyles.heading),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${streak.completedDays} / ${streak.totalScheduledDays} Days',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${streak.completionPercentage.round()}% Complete',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navySoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: streak.totalScheduledDays == 0
                            ? 0
                            : streak.completedDays / streak.totalScheduledDays,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceMuted,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Current streak',
                          value: '${streak.currentStreak} days',
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Best streak',
                          value: '${streak.bestStreak} days',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: streak.totalScheduledDays,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, index) {
                  final day = habit.createdAt.add(Duration(days: index));
                  final completed = isCompletedOn(completions, habit.id, day);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: completed
                              ? AppColors.navy
                              : AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: completed
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 18,
                              )
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: AppColors.navySoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Day ${index + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.navySoft,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (milestone != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Congratulations!\n$milestone-Day Streak!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => showAchievementUnlockedDialog(
                          context,
                          habitName: habit.name,
                          milestoneDays: milestone,
                        ),
                        icon: const Icon(
                          Icons.ios_share,
                          color: Colors.white,
                          size: 16,
                        ),
                        label: const Text(
                          'Share',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.bodyMuted),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The overlapping "Habit / Todays Task" pill toggle from the Today mockup.
class TodayToggle extends StatelessWidget {
  const TodayToggle({super.key, required this.index, required this.onChanged});

  final int index; // 0 = Habit, 1 = Today's Task
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 56,
        width: 260,
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: _Segment(
                    label: 'Habit',
                    selected: index == 0,
                    onTap: () => onChanged(0),
                    background: AppColors.navy,
                    foreground: Colors.white,
                    alignRight: false,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Segment(
                    label: "Today's Task",
                    selected: index == 1,
                    onTap: () => onChanged(1),
                    background: AppColors.surface,
                    foreground: AppColors.navy,
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.background,
    required this.foreground,
    required this.alignRight,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color background;
  final Color foreground;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.horizontal(
      left: alignRight ? const Radius.circular(28) : const Radius.circular(28),
      right: alignRight ? const Radius.circular(28) : const Radius.circular(28),
    );
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? foreground : foreground.withValues(alpha: 0.45),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

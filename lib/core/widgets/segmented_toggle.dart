import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    this.leftSubtitle,
    this.rightSubtitle,
    required this.selectedLeft,
    required this.onSelect,
  });

  final String leftLabel;
  final String rightLabel;
  final String? leftSubtitle;
  final String? rightSubtitle;
  final bool selectedLeft;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _option(
              leftLabel,
              leftSubtitle,
              selectedLeft,
              () => onSelect(true),
            ),
          ),
          Expanded(
            child: _option(
              rightLabel,
              rightSubtitle,
              !selectedLeft,
              () => onSelect(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(
    String label,
    String? subtitle,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.navy,
              ),
            ),
            if (subtitle != null)
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.navySoft),
              ),
          ],
        ),
      ),
    );
  }
}

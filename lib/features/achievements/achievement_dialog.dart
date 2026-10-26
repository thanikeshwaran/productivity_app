import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'achievement_poster.dart';

Future<void> _sharePoster(
  BuildContext context, {
  required String habitName,
  required int milestoneDays,
}) async {
  final path = await generateAchievementPosterFile(
    context,
    habitName: habitName,
    milestoneDays: milestoneDays,
  );
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(path)],
      text:
          'I just hit a $milestoneDays day streak on "$habitName"! Consistent. Disciplined. Productive.',
    ),
  );
}

Future<void> showAchievementUnlockedDialog(
  BuildContext context, {
  required String habitName,
  required int milestoneDays,
}) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉 ACHIEVEMENT UNLOCKED 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '$milestoneDays Days',
              style: AppTextStyles.heading,
              textAlign: TextAlign.center,
            ),
            const Text(
              'Best Streak',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              habitName,
              style: AppTextStyles.body,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.goldSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag, color: AppColors.navy),
                  Text(
                    '$milestoneDays\nDays',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Consistent. Disciplined. Productive.',
              style: AppTextStyles.bodyMuted,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _sharePoster(
                  context,
                  habitName: habitName,
                  milestoneDays: milestoneDays,
                ),
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('Share on Instagram Stories'),
              ),
            ),
            TextButton(
              onPressed: () => _sharePoster(
                context,
                habitName: habitName,
                milestoneDays: milestoneDays,
              ),
              child: const Text('Share via...'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    ),
  );
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/responsive_body.dart';

/// Placeholder for menu entries that need a backend/IAP setup we don't have
/// yet (Customize Theme, Account & Backup, Get Premium, general Settings).
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ResponsiveBody(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.hourglass_top_outlined,
                    size: 40,
                    color: AppColors.navySoft,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Coming soon',
                    style: AppTextStyles.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "We're still building $title. Check back in a future update.",
                    style: AppTextStyles.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

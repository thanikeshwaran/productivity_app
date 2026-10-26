import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/theme/app_colors.dart';

/// Renders the achievement card to a PNG file and returns its path.
///
/// Sharing an *image* (rather than plain text, which is what the app did
/// before) is the actual fix for "Share on Instagram Stories... goes to
/// messages and asks to select people": Instagram Stories only accepts
/// media shares, so a text-only share falls back to Android's generic
/// Direct-Message/contact flow. Attaching this poster makes Instagram show
/// up as a normal share-sheet target that opens straight into its Stories
/// composer, and gives WhatsApp status something attractive to show instead
/// of plain text.
Future<String> generateAchievementPosterFile(
  BuildContext context, {
  required String habitName,
  required int milestoneDays,
}) async {
  const size = Size(1080, 1350);
  final repaintKey = GlobalKey();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: -20000,
      top: 0,
      child: Material(
        color: Colors.transparent,
        child: RepaintBoundary(
          key: repaintKey,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: _PosterCard(habitName: habitName, milestoneDays: milestoneDays),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  // Two frames guarantees layout + paint have both completed before capture.
  await WidgetsBinding.instance.endOfFrame;
  await WidgetsBinding.instance.endOfFrame;

  final boundary =
      repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: 2);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  entry.remove();

  final bytes = byteData!.buffer.asUint8List();
  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/achievement_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File(path);
  await file.writeAsBytes(bytes);
  return file.path;
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.habitName, required this.milestoneDays});

  final String habitName;
  final int milestoneDays;

  @override
  Widget build(BuildContext context) {
    final flags = List.filled(
      milestoneDays.clamp(0, 10),
      '🚩',
    ).join(' ');
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'ACHIEVEMENT UNLOCKED',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 34,
              letterSpacing: 2,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              color: AppColors.goldSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$milestoneDays',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 96,
                color: AppColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'DAYS',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 28,
              letterSpacing: 4,
              color: AppColors.navySoft,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Best Streak',
            style: TextStyle(fontSize: 26, color: AppColors.navySoft),
          ),
          const SizedBox(height: 24),
          Text(
            habitName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 40,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 32),
          Text(flags, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 48),
          const Text(
            'Consistent. Disciplined. Productive.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 30,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Make it Easy',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: AppColors.navySoft,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Keeps this mobile-first layout from stretching edge-to-edge on wide
/// desktop browser widths (CLAUDE.md Section 2). AppShell applies this to
/// every shell-routed screen; standalone full-screen routes (pushed outside
/// the shell) wrap their own Scaffold body with this directly.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

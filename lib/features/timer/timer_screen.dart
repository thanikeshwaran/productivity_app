import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/notifications/notification_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'timer_controller.dart';

enum _TimerMode { stopwatch, countdown, intervals }

final _timerModeProvider = StateProvider<_TimerMode>(
  (ref) => _TimerMode.stopwatch,
);

class TimerScreen extends ConsumerWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(_timerModeProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        const Text('Timer', style: AppTextStyles.heading),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: _TimerMode.values.map((m) {
              final selected = m == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => ref.read(_timerModeProvider.notifier).state = m,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.navy : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      switch (m) {
                        _TimerMode.stopwatch => 'Stopwatch',
                        _TimerMode.countdown => 'Countdown',
                        _TimerMode.intervals => 'Intervals',
                      },
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.navy,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        switch (mode) {
          _TimerMode.stopwatch => const _StopwatchView(),
          _TimerMode.countdown => const _CountdownView(),
          _TimerMode.intervals => const _IntervalsView(),
        },
      ],
    );
  }
}

class _TimeDial extends StatelessWidget {
  const _TimeDial({required this.label, this.sublabel});

  final String label;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          if (sublabel != null) ...[
            const SizedBox(height: 8),
            Text(sublabel!, style: AppTextStyles.bodyMuted),
          ],
        ],
      ),
    );
  }
}

class _ControlRow extends StatelessWidget {
  const _ControlRow({
    required this.running,
    required this.onStartPause,
    required this.onReset,
  });

  final bool running;
  final VoidCallback onStartPause;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.replay),
            label: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: onStartPause,
            icon: Icon(running ? Icons.pause : Icons.play_arrow),
            label: Text(running ? 'Pause' : 'Start'),
          ),
        ),
      ],
    );
  }
}

class _StopwatchView extends ConsumerWidget {
  const _StopwatchView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerTickerProvider);
    final state = ref.watch(stopwatchProvider);
    final notifier = ref.read(stopwatchProvider.notifier);
    final now = DateTime.now();
    final elapsed = state.elapsedAt(now);

    return Column(
      children: [
        _TimeDial(label: formatDuration(elapsed)),
        const SizedBox(height: 20),
        _ControlRow(
          running: state.running,
          onStartPause: state.running ? notifier.pause : notifier.start,
          onReset: notifier.reset,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: state.running ? notifier.lap : null,
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Lap'),
          ),
        ),
        if (state.laps.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...state.laps.reversed.toList().asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lap ${state.laps.length - e.key}',
                    style: AppTextStyles.bodyMuted,
                  ),
                  Text(
                    formatDuration(e.value),
                    style: AppTextStyles.body.copyWith(
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CountdownView extends ConsumerWidget {
  const _CountdownView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerTickerProvider);
    final state = ref.watch(countdownProvider);
    final notifier = ref.read(countdownProvider.notifier);
    final now = DateTime.now();
    final remaining = state.remainingAt(now);

    if (state.running && remaining == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.markFinished();
        NotificationService.instance.scheduleOneOff(
          id: 900001,
          title: "Time's up!",
          body: 'Your countdown timer finished.',
          dateTime: DateTime.now().add(const Duration(seconds: 1)),
        );
      });
    }

    return Column(
      children: [
        _TimeDial(
          label: formatDuration(remaining),
          sublabel: state.finished ? 'Finished' : null,
        ),
        const SizedBox(height: 20),
        if (!state.running)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [1, 5, 10, 15, 20, 30].map((mins) {
              final selected = state.total.inMinutes == mins;
              return ChoiceChip(
                label: Text('$mins min'),
                selected: selected,
                onSelected: (_) =>
                    notifier.setDuration(Duration(minutes: mins)),
              );
            }).toList(),
          ),
        const SizedBox(height: 20),
        _ControlRow(
          running: state.running,
          onStartPause: state.running ? notifier.pause : notifier.start,
          onReset: notifier.reset,
        ),
      ],
    );
  }
}

class _IntervalsView extends ConsumerWidget {
  const _IntervalsView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(timerTickerProvider);
    final state = ref.watch(intervalProvider);
    final notifier = ref.read(intervalProvider.notifier);
    final now = DateTime.now();
    final phase = state.phaseAt(now);

    if (state.running && phase == null && !state.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.markFinished();
        NotificationService.instance.scheduleOneOff(
          id: 900002,
          title: 'Intervals complete!',
          body: 'Great work — all rounds finished.',
          dateTime: DateTime.now().add(const Duration(seconds: 1)),
        );
      });
    }

    return Column(
      children: [
        _TimeDial(
          label: phase == null
              ? (state.finished ? '00:00' : formatDuration(state.config.total))
              : formatDuration(phase.remaining),
          sublabel: phase == null
              ? (state.finished ? 'Finished' : null)
              : '${phase.isWork ? 'Work' : 'Rest'} · Round ${phase.round} / ${state.config.rounds}',
        ),
        const SizedBox(height: 20),
        if (!state.running) ...[
          _IntervalConfigRow(
            label: 'Rounds',
            value: '${state.config.rounds}',
            onDecrement: () => notifier.setConfig(
              IntervalConfig(
                rounds: (state.config.rounds - 1).clamp(1, 99),
                work: state.config.work,
                rest: state.config.rest,
              ),
            ),
            onIncrement: () => notifier.setConfig(
              IntervalConfig(
                rounds: (state.config.rounds + 1).clamp(1, 99),
                work: state.config.work,
                rest: state.config.rest,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _IntervalConfigRow(
            label: 'Work (sec)',
            value: '${state.config.work.inSeconds}',
            onDecrement: () => notifier.setConfig(
              IntervalConfig(
                rounds: state.config.rounds,
                work: Duration(
                  seconds: (state.config.work.inSeconds - 5).clamp(5, 600),
                ),
                rest: state.config.rest,
              ),
            ),
            onIncrement: () => notifier.setConfig(
              IntervalConfig(
                rounds: state.config.rounds,
                work: Duration(
                  seconds: (state.config.work.inSeconds + 5).clamp(5, 600),
                ),
                rest: state.config.rest,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _IntervalConfigRow(
            label: 'Rest (sec)',
            value: '${state.config.rest.inSeconds}',
            onDecrement: () => notifier.setConfig(
              IntervalConfig(
                rounds: state.config.rounds,
                work: state.config.work,
                rest: Duration(
                  seconds: (state.config.rest.inSeconds - 5).clamp(0, 600),
                ),
              ),
            ),
            onIncrement: () => notifier.setConfig(
              IntervalConfig(
                rounds: state.config.rounds,
                work: state.config.work,
                rest: Duration(
                  seconds: (state.config.rest.inSeconds + 5).clamp(0, 600),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        _ControlRow(
          running: state.running,
          onStartPause: state.running ? notifier.pause : notifier.start,
          onReset: notifier.reset,
        ),
      ],
    );
  }
}

class _IntervalConfigRow extends StatelessWidget {
  const _IntervalConfigRow({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: onDecrement,
            ),
            SizedBox(
              width: 36,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticks while any timer mode is running, so the UI recomputes elapsed/
/// remaining time from wall-clock deltas (same resync pattern as
/// core/clock.dart's midnight ticker) rather than trusting an in-memory
/// counter that would desync after even a brief background pause.
final timerTickerProvider = StreamProvider<void>((ref) {
  return Stream<void>.periodic(const Duration(milliseconds: 200));
});

class StopwatchState {
  final bool running;
  final Duration baseElapsed;
  final DateTime? startedAt;
  final List<Duration> laps;

  const StopwatchState({
    this.running = false,
    this.baseElapsed = Duration.zero,
    this.startedAt,
    this.laps = const [],
  });

  Duration elapsedAt(DateTime now) =>
      running && startedAt != null
      ? baseElapsed + now.difference(startedAt!)
      : baseElapsed;
}

class StopwatchNotifier extends Notifier<StopwatchState> {
  @override
  StopwatchState build() => const StopwatchState();

  void start() {
    if (state.running) return;
    state = StopwatchState(
      running: true,
      baseElapsed: state.baseElapsed,
      startedAt: DateTime.now(),
      laps: state.laps,
    );
  }

  void pause() {
    if (!state.running) return;
    final now = DateTime.now();
    state = StopwatchState(baseElapsed: state.elapsedAt(now), laps: state.laps);
  }

  void reset() => state = const StopwatchState();

  void lap() {
    final now = DateTime.now();
    state = StopwatchState(
      running: state.running,
      baseElapsed: state.baseElapsed,
      startedAt: state.startedAt,
      laps: [...state.laps, state.elapsedAt(now)],
    );
  }
}

final stopwatchProvider = NotifierProvider<StopwatchNotifier, StopwatchState>(
  StopwatchNotifier.new,
);

class CountdownState {
  final bool running;
  final Duration total;
  final Duration remainingBase;
  final DateTime? startedAt;
  final bool finished;

  const CountdownState({
    this.running = false,
    this.total = const Duration(minutes: 1),
    this.remainingBase = const Duration(minutes: 1),
    this.startedAt,
    this.finished = false,
  });

  Duration remainingAt(DateTime now) {
    if (!running || startedAt == null) return remainingBase;
    final r = remainingBase - now.difference(startedAt!);
    return r.isNegative ? Duration.zero : r;
  }
}

class CountdownNotifier extends Notifier<CountdownState> {
  @override
  CountdownState build() => const CountdownState();

  void setDuration(Duration d) {
    if (state.running) return;
    state = CountdownState(total: d, remainingBase: d);
  }

  void start() {
    final now = DateTime.now();
    if (state.running || state.remainingAt(now) == Duration.zero) return;
    state = CountdownState(
      running: true,
      total: state.total,
      remainingBase: state.remainingBase,
      startedAt: now,
    );
  }

  void pause() {
    if (!state.running) return;
    final now = DateTime.now();
    state = CountdownState(
      total: state.total,
      remainingBase: state.remainingAt(now),
    );
  }

  void reset() =>
      state = CountdownState(total: state.total, remainingBase: state.total);

  /// Called by the UI once it observes remaining time hit zero.
  void markFinished() => state = CountdownState(
    total: state.total,
    remainingBase: Duration.zero,
    finished: true,
  );

  void acknowledgeFinished() =>
      state = CountdownState(total: state.total, remainingBase: state.total);
}

final countdownProvider = NotifierProvider<CountdownNotifier, CountdownState>(
  CountdownNotifier.new,
);

class IntervalConfig {
  final int rounds;
  final Duration work;
  final Duration rest;

  const IntervalConfig({
    this.rounds = 4,
    this.work = const Duration(seconds: 30),
    this.rest = const Duration(seconds: 15),
  });

  Duration get cycle => work + rest;
  Duration get total => cycle * rounds;
}

class IntervalPhase {
  final int round;
  final bool isWork;
  final Duration remaining;
  const IntervalPhase({
    required this.round,
    required this.isWork,
    required this.remaining,
  });
}

class IntervalState {
  final bool running;
  final IntervalConfig config;
  final Duration elapsedBase;
  final DateTime? startedAt;
  final bool finished;

  const IntervalState({
    this.running = false,
    this.config = const IntervalConfig(),
    this.elapsedBase = Duration.zero,
    this.startedAt,
    this.finished = false,
  });

  Duration elapsedAt(DateTime now) =>
      running && startedAt != null
      ? elapsedBase + now.difference(startedAt!)
      : elapsedBase;

  IntervalPhase? phaseAt(DateTime now) {
    final elapsed = elapsedAt(now);
    if (elapsed >= config.total) return null;
    final cycleSeconds = config.cycle.inSeconds;
    if (cycleSeconds <= 0) return null;
    final elapsedSeconds = elapsed.inSeconds;
    final round = (elapsedSeconds ~/ cycleSeconds) + 1;
    final intoCycle = Duration(seconds: elapsedSeconds % cycleSeconds);
    if (intoCycle < config.work) {
      return IntervalPhase(
        round: round,
        isWork: true,
        remaining: config.work - intoCycle,
      );
    }
    return IntervalPhase(
      round: round,
      isWork: false,
      remaining: config.cycle - intoCycle,
    );
  }
}

class IntervalNotifier extends Notifier<IntervalState> {
  @override
  IntervalState build() => const IntervalState();

  void setConfig(IntervalConfig config) {
    if (state.running) return;
    state = IntervalState(config: config);
  }

  void start() {
    final now = DateTime.now();
    if (state.running || state.elapsedAt(now) >= state.config.total) return;
    state = IntervalState(
      running: true,
      config: state.config,
      elapsedBase: state.elapsedBase,
      startedAt: now,
    );
  }

  void pause() {
    if (!state.running) return;
    final now = DateTime.now();
    state = IntervalState(
      config: state.config,
      elapsedBase: state.elapsedAt(now),
    );
  }

  void reset() => state = IntervalState(config: state.config);

  void markFinished() =>
      state = IntervalState(config: state.config, finished: true);

  void acknowledgeFinished() => state = IntervalState(config: state.config);
}

final intervalProvider = NotifierProvider<IntervalNotifier, IntervalState>(
  IntervalNotifier.new,
);

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  final ms = (d.inMilliseconds % 1000) ~/ 100;
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.$ms';
}

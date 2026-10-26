import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../core/clock/clock.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/section_card.dart';
import '../../data/models/day_event.dart';
import '../../providers/day_event_providers.dart';
import '../../providers/task_providers.dart';
import 'event_form_sheet.dart';

final _visibleMonthProvider = StateProvider<DateTime>((ref) {
  final today = ref.watch(todayProvider);
  return DateTime(today.year, today.month, 1);
});

class MarkADayScreen extends ConsumerWidget {
  const MarkADayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedPlannerDateProvider);
    final visibleMonth = ref.watch(_visibleMonthProvider);
    final events = ref.watch(dayEventsProvider).value ?? [];
    final today = ref.watch(todayProvider);

    final eventsThisMonth =
        events.where((e) {
          final occurrence = nextOccurrenceInYear(e, visibleMonth.year);
          return occurrence.year == visibleMonth.year &&
              occurrence.month == visibleMonth.month;
        }).toList()
          ..sort((a, b) {
            final oa = nextOccurrenceInYear(a, visibleMonth.year);
            final ob = nextOccurrenceInYear(b, visibleMonth.year);
            return oa.compareTo(ob);
          });

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.list_alt_outlined),
            tooltip: 'All events',
            onPressed: () => context.push(Routes.markADayEvents),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(ref, visibleMonth, -1),
            ),
            Text(
              AppDateUtils.formatMonthYear(visibleMonth),
              style: AppTextStyles.title,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(ref, visibleMonth, 1),
            ),
          ],
        ),
        _MonthGrid(
          visibleMonth: visibleMonth,
          selectedDate: selectedDate,
          today: today,
          hasEvent: (day) => eventsOn(events, day).isNotEmpty,
          onSelect: (day) =>
              ref.read(selectedPlannerDateProvider.notifier).state = day,
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Events planned for ${AppDateUtils.formatMonthYear(visibleMonth)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (eventsThisMonth.isEmpty)
                const Text(
                  'Nothing planned this month.',
                  style: AppTextStyles.bodyMuted,
                )
              else
                ...eventsThisMonth.map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '${AppDateUtils.formatMedium(nextOccurrenceInYear(e, visibleMonth.year))} · ${e.title}',
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SectionCard(
          title: 'Selected Date: ${AppDateUtils.formatMedium(selectedDate)}',
          child: Builder(
            builder: (context) {
              final dayEvents = eventsOn(events, selectedDate);
              if (dayEvents.isEmpty) {
                return const EmptyState(
                  message: 'No events for this date.\nTap \'+\' to add one.',
                  icon: Icons.event_outlined,
                );
              }
              return Column(
                children: dayEvents.map((e) => _EventRow(event: e)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  void _changeMonth(WidgetRef ref, DateTime visibleMonth, int delta) {
    final newMonth = DateTime(visibleMonth.year, visibleMonth.month + delta, 1);
    ref.read(_visibleMonthProvider.notifier).state = newMonth;
    // Keep the selection in step with the visible month, like a normal
    // calendar app (corrections doc: "date not switching when next month is
    // clicked").
    ref.read(selectedPlannerDateProvider.notifier).state = newMonth;
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDate,
    required this.today,
    required this.hasEvent,
    required this.onSelect,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final DateTime today;
  final bool Function(DateTime) hasEvent;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final leadingBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;

    final cells = <DateTime?>[
      ...List.filled(leadingBlanks, null),
      ...List.generate(
        daysInMonth,
        (i) => DateTime(visibleMonth.year, visibleMonth.month, i + 1),
      ),
    ];

    return Column(
      children: [
        Row(
          children: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
              .map(
                (d) => Expanded(
                  child: Center(child: Text(d, style: AppTextStyles.label)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cells.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, i) {
            final day = cells[i];
            if (day == null) return const SizedBox.shrink();
            final selected = AppDateUtils.isSameDay(day, selectedDate);
            final isToday = AppDateUtils.isSameDay(day, today);
            final marked = hasEvent(day);
            return GestureDetector(
              onTap: () => onSelect(day),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.navy
                        : (marked ? AppColors.goldSoft : Colors.transparent),
                    shape: BoxShape.circle,
                    // Today always keeps this ring regardless of selection,
                    // so it never "loses" its highlight once another date
                    // is picked (corrections doc, Mark a Day §1).
                    border: isToday
                        ? Border.all(color: AppColors.navy, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.navy,
                      fontWeight: marked || selected || isToday
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EventRow extends ConsumerWidget {
  const _EventRow({required this.event});

  final DayEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showEventFormSheet(
        context,
        ref,
        initialDate: event.date,
        editing: event,
      ),
      onLongPress: () async {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete event?',
          message: 'This removes "${event.title}".',
        );
        if (confirmed) {
          await ref.read(dayEventsProvider.notifier).deleteEvent(event.id);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(_iconFor(event.type), color: AppColors.navy),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (event.description.isNotEmpty)
                    Text(
                      'Note: ${event.description}',
                      style: AppTextStyles.bodyMuted,
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.navySoft),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(DayEventType type) {
    switch (type) {
      case DayEventType.birthday:
        return Icons.cake_outlined;
      case DayEventType.anniversary:
        return Icons.favorite_border;
      case DayEventType.exam:
        return Icons.school_outlined;
      case DayEventType.other:
        return Icons.event_outlined;
    }
  }
}

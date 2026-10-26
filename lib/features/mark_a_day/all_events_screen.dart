import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/empty_state.dart';
import '../../providers/day_event_providers.dart';
import 'event_form_sheet.dart';

enum _EventSort { date, title, type }

final _eventSortProvider = StateProvider<_EventSort>((ref) => _EventSort.date);

class AllEventsScreen extends ConsumerWidget {
  const AllEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(dayEventsProvider).value ?? [];
    final sort = ref.watch(_eventSortProvider);

    final sorted = [...events];
    switch (sort) {
      case _EventSort.date:
        sorted.sort((a, b) => a.date.compareTo(b.date));
      case _EventSort.title:
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case _EventSort.type:
        sorted.sort((a, b) => a.type.index.compareTo(b.type.index));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('All Events'),
        actions: [
          PopupMenuButton<_EventSort>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => ref.read(_eventSortProvider.notifier).state = v,
            itemBuilder: (context) => const [
              PopupMenuItem(value: _EventSort.date, child: Text('By date')),
              PopupMenuItem(value: _EventSort.title, child: Text('By title')),
              PopupMenuItem(value: _EventSort.type, child: Text('By type')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: sorted.isEmpty
            ? const EmptyState(
                message: 'No events planned yet.\nTap \'+\' to add one.',
                icon: Icons.event_outlined,
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const Divider(height: 20),
                itemBuilder: (context, i) {
                  final event = sorted[i];
                  return InkWell(
                    onTap: () => showEventFormSheet(
                      context,
                      ref,
                      initialDate: event.date,
                      editing: event,
                    ),
                    child: Row(
                      children: [
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
                              Text(
                                AppDateUtils.formatMedium(event.date) +
                                    (event.recurring ? ' · Yearly' : ''),
                                style: AppTextStyles.bodyMuted,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.navySoft,
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

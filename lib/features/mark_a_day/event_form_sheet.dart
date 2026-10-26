import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/picker_chip.dart';
import '../../data/models/day_event.dart';
import '../../providers/day_event_providers.dart';

const _uuid = Uuid();

Future<void> showEventFormSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime initialDate,
  DayEvent? editing,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: _EventFormSheet(initialDate: initialDate, editing: editing),
    ),
  );
}

class _EventFormSheet extends ConsumerStatefulWidget {
  const _EventFormSheet({required this.initialDate, this.editing});

  final DateTime initialDate;
  final DayEvent? editing;

  @override
  ConsumerState<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<_EventFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DayEventType _type;
  late DateTime _date;
  late bool _recurring;
  String? _error;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _titleController = TextEditingController(text: editing?.title ?? '');
    _descriptionController = TextEditingController(
      text: editing?.description ?? '',
    );
    _type = editing?.type ?? DayEventType.other;
    _date = editing?.date ?? widget.initialDate;
    _recurring =
        editing?.recurring ??
        (_type == DayEventType.birthday || _type == DayEventType.anniversary);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Event title is required');
      return;
    }
    final editing = widget.editing;
    final event = DayEvent(
      id: editing?.id ?? _uuid.v4(),
      date: _date,
      type: _type,
      title: title,
      description: _descriptionController.text.trim(),
      recurring: _recurring,
    );
    if (editing == null) {
      await ref.read(dayEventsProvider.notifier).addEvent(event);
    } else {
      await ref.read(dayEventsProvider.notifier).updateEvent(event);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              widget.editing == null ? 'Add Event' : 'Edit Event',
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Title', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(hintText: 'e.g., Birthday'),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.red, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Type', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DayEventType.values.map((t) {
              final selected = t == _type;
              return GestureDetector(
                onTap: () => setState(() {
                  _type = t;
                  if (t == DayEventType.birthday ||
                      t == DayEventType.anniversary) {
                    _recurring = true;
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.navy : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _typeLabel(t),
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Date', style: AppTextStyles.label),
          const SizedBox(height: 8),
          PickerChip(
            icon: Icons.calendar_today,
            label: AppDateUtils.formatMedium(_date),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          const Text('Note', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Optional details'),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Repeats every year', style: AppTextStyles.body),
              Switch(
                value: _recurring,
                onChanged: (v) => setState(() => _recurring = v),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Event'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _typeLabel(DayEventType t) {
    switch (t) {
      case DayEventType.birthday:
        return 'Birthday';
      case DayEventType.anniversary:
        return 'Anniversary';
      case DayEventType.exam:
        return 'Exam Date';
      case DayEventType.other:
        return 'Other';
    }
  }
}

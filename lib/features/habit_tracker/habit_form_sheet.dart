import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/picker_chip.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../data/models/habit.dart';
import '../../providers/habit_providers.dart';

const _uuid = Uuid();

Future<void> showHabitFormSheet(
  BuildContext context,
  WidgetRef ref, {
  Habit? editing,
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
      child: _HabitFormSheet(editing: editing),
    ),
  );
}

class _HabitFormSheet extends ConsumerStatefulWidget {
  const _HabitFormSheet({this.editing});

  final Habit? editing;

  @override
  ConsumerState<_HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<_HabitFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late HabitType _type;
  int _timeMinutes = 6 * 60; // default 6:00 AM per the mockup
  late bool _alarmEnabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _type = editing?.type ?? HabitType.timed;
    _timeMinutes = editing?.timeMinutes ?? 6 * 60;
    _alarmEnabled = editing?.alarmEnabled ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _timeMinutes ~/ 60,
        minute: _timeMinutes % 60,
      ),
    );
    if (result != null) {
      setState(() => _timeMinutes = result.hour * 60 + result.minute);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Habit name is required');
      return;
    }
    final editing = widget.editing;
    final habit = Habit(
      id: editing?.id ?? _uuid.v4(),
      name: name,
      type: _type,
      timeMinutes: _type == HabitType.timed ? _timeMinutes : null,
      alarmEnabled: _type == HabitType.timed ? _alarmEnabled : false,
      createdAt: editing?.createdAt ?? DateTime.now(),
      active: editing?.active ?? true,
      category: editing?.category ?? 'Personal',
    );
    if (editing == null) {
      await ref.read(habitsProvider.notifier).addHabit(habit);
    } else {
      await ref.read(habitsProvider.notifier).updateHabit(habit);
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (editing == null) {
      messenger.showSnackBar(const SnackBar(content: Text('1 Habit created.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _timeMinutes ~/ 60;
    final m = _timeMinutes % 60;
    final timeLabel = TimeOfDay(hour: h, minute: m).format(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Text(
                widget.editing == null ? 'Create New Habit' : 'Edit Habit',
                style: AppTextStyles.title,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Habit Name', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Enter habit name (e.g., Read a Book)',
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            if (_error != null) ...[
              const SizedBox(height: 6),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.red, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Type', style: AppTextStyles.label),
            const SizedBox(height: 8),
            SegmentedToggle(
              leftLabel: 'Timed',
              rightLabel: 'Any time',
              selectedLeft: _type == HabitType.timed,
              onSelect: (left) => setState(
                () => _type = left ? HabitType.timed : HabitType.regular,
              ),
            ),
            if (_type == HabitType.timed) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 18,
                    color: AppColors.navySoft,
                  ),
                  const SizedBox(width: 6),
                  const Text('Timed', style: AppTextStyles.label),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Time:', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 6),
              PickerChip(
                icon: Icons.access_time,
                label: timeLabel,
                onTap: _pickTime,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Alarm', style: AppTextStyles.body),
                  Switch(
                    value: _alarmEnabled,
                    onChanged: (v) => setState(() => _alarmEnabled = v),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.notifications_none, size: 18),
                label: Text(
                  widget.editing == null ? 'Create Habit' : 'Save Habit',
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

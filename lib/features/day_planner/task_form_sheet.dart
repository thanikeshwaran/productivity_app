import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/widgets/picker_chip.dart';
import '../../core/widgets/segmented_toggle.dart';
import '../../data/models/reminder_option.dart';
import '../../data/models/task.dart';
import '../../providers/task_providers.dart';

const _uuid = Uuid();

Future<void> showTaskFormSheet(
  BuildContext context,
  WidgetRef ref, {
  required DateTime initialDate,
  Task? editing,
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
      child: _TaskFormSheet(initialDate: initialDate, editing: editing),
    ),
  );
}

class _TaskFormSheet extends ConsumerStatefulWidget {
  const _TaskFormSheet({required this.initialDate, this.editing});

  final DateTime initialDate;
  final Task? editing;

  @override
  ConsumerState<_TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<_TaskFormSheet> {
  late final TextEditingController _nameController;
  late TaskType _type;
  late DateTime _date;
  int _timeMinutes = 12 * 60;
  late ReminderType _reminderType;
  int? _customAmount;
  ReminderUnit? _customUnit;
  String? _error;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    _nameController = TextEditingController(text: editing?.name ?? '');
    _type = editing?.type ?? TaskType.timed;
    _date = editing?.date ?? widget.initialDate;
    _timeMinutes = editing?.timeMinutes ?? 12 * 60;
    _reminderType = editing?.reminder.type ?? ReminderType.none;
    _customAmount = editing?.reminder.customAmount;
    _customUnit = editing?.reminder.customUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomReminder() async {
    var amount = _customAmount ?? 1;
    var unit = _customUnit ?? ReminderUnit.days;
    final result = await showDialog<(int, ReminderUnit)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Custom reminder'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 70,
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: '$amount'),
                  onChanged: (v) => amount = int.tryParse(v) ?? amount,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<ReminderUnit>(
                value: unit,
                items: const [
                  DropdownMenuItem(
                    value: ReminderUnit.minutes,
                    child: Text('Minutes'),
                  ),
                  DropdownMenuItem(
                    value: ReminderUnit.days,
                    child: Text('Days'),
                  ),
                  DropdownMenuItem(
                    value: ReminderUnit.weeks,
                    child: Text('Weeks'),
                  ),
                ],
                onChanged: (v) =>
                    setDialogState(() => unit = v ?? ReminderUnit.days),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop((amount, unit)),
              child: const Text('Set'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    setState(() {
      _reminderType = ReminderType.custom;
      _customAmount = result.$1;
      _customUnit = result.$2;
    });
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

  Future<void> _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (result != null) setState(() => _date = result);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Task name is required');
      return;
    }
    final reminder = ReminderOption(
      _reminderType,
      customAmount: _reminderType == ReminderType.custom ? _customAmount : null,
      customUnit: _reminderType == ReminderType.custom ? _customUnit : null,
    );
    final editing = widget.editing;
    final task = Task(
      id: editing?.id ?? _uuid.v4(),
      name: name,
      type: _type,
      date: _date,
      timeMinutes: _type == TaskType.timed ? _timeMinutes : null,
      flexible: _type == TaskType.undated,
      reminder: reminder,
      completed: editing?.completed ?? false,
      createdAt: editing?.createdAt ?? DateTime.now(),
    );
    if (editing == null) {
      await ref.read(tasksProvider.notifier).addTask(task);
    } else {
      await ref.read(tasksProvider.notifier).updateTask(task);
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    if (editing == null) {
      messenger.showSnackBar(const SnackBar(content: Text('1 Task created.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeLabel = TimeOfDay(
      hour: _timeMinutes ~/ 60,
      minute: _timeMinutes % 60,
    ).format(context);
    final dateLabel = AppDateUtils.formatMedium(_date);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Text(
              widget.editing == null ? 'Add Task' : 'Edit Task',
              style: AppTextStyles.title,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Task Name', style: AppTextStyles.label),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Enter task name (e.g., Catch Train)',
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
          const Text('Task Type:', style: AppTextStyles.label),
          const SizedBox(height: 8),
          SegmentedToggle(
            leftLabel: 'Timed',
            leftSubtitle: '(Fixed Time)',
            rightLabel: 'Undated',
            rightSubtitle: '(Flexible)',
            selectedLeft: _type == TaskType.timed,
            onSelect: (left) => setState(
              () => _type = left ? TaskType.timed : TaskType.undated,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Icon(Icons.access_time, size: 18, color: AppColors.navySoft),
              SizedBox(width: 6),
              Text('Task Specifics', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (_type == TaskType.timed) ...[
                Expanded(
                  child: _LabeledPicker(
                    label: 'Time:',
                    child: PickerChip(
                      icon: Icons.access_time,
                      label: timeLabel,
                      onTap: _pickTime,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _LabeledPicker(
                  label: 'Date:',
                  child: PickerChip(
                    icon: Icons.calendar_today,
                    label: dateLabel,
                    onTap: _pickDate,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Icon(
                Icons.notifications_none,
                size: 18,
                color: AppColors.navySoft,
              ),
              SizedBox(width: 6),
              Text('Reminder', style: AppTextStyles.label),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Notify Before:', style: AppTextStyles.bodyMuted),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _reminderChip('None', ReminderType.none),
              if (_type == TaskType.timed) ...[
                _reminderChip('5 mins', ReminderType.fiveMinutes),
                _reminderChip('15 mins', ReminderType.fifteenMinutes),
                _reminderChip('30 min', ReminderType.thirtyMinutes),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _reminderChip('1 day', ReminderType.oneDay),
              _reminderChip('2 day', ReminderType.twoDays),
              _reminderChip('1 week', ReminderType.oneWeek),
              _CustomReminderChip(
                selected: _reminderType == ReminderType.custom,
                label: _reminderType == ReminderType.custom
                    ? ReminderOption(
                        ReminderType.custom,
                        customAmount: _customAmount,
                        customUnit: _customUnit,
                      ).label
                    : 'Custom',
                onTap: _pickCustomReminder,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    widget.editing == null ? 'Save Task' : 'Update Task',
                  ),
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

  Widget _reminderChip(String label, ReminderType type) {
    final selected = _reminderType == type;
    return GestureDetector(
      onTap: () => setState(() => _reminderType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.navy,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _CustomReminderChip extends StatelessWidget {
  const _CustomReminderChip({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.navy : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.navy,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LabeledPicker extends StatelessWidget {
  const _LabeledPicker({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodyMuted),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

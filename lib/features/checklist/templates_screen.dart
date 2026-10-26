import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/responsive_body.dart';
import '../../data/models/template.dart';
import '../../providers/checklist_providers.dart';

const _uuid = Uuid();
const _cardColors = [
  AppColors.blueSoft,
  AppColors.goldSoft,
  AppColors.roseSoft,
];

class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(allTemplatesProvider);
    final query = ref.watch(templateSearchQueryProvider);
    final filtered = query.trim().isEmpty
        ? templates
        : templates
              .where(
                (t) =>
                    t.name.toLowerCase().contains(query.trim().toLowerCase()),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Templates')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createCustomTemplate(context, ref),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: ResponsiveBody(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search templates...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) =>
                    ref.read(templateSearchQueryProvider.notifier).state = v,
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < filtered.length; i++)
                _TemplateCard(
                  template: filtered[i],
                  color: _cardColors[i % _cardColors.length],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createCustomTemplate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final itemsController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('New Template'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: 'Template name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  hintText: 'Short description',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: itemsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'One item per line',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != true || nameController.text.trim().isEmpty) return;
    final lines = itemsController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final template = ChecklistTemplate(
      id: _uuid.v4(),
      name: nameController.text.trim(),
      description: descController.text.trim(),
      category: 'Custom',
      items: [
        for (var i = 0; i < lines.length; i++)
          TemplateItem(text: lines[i], order: i),
      ],
    );
    await ref.read(userTemplatesProvider.notifier).addTemplate(template);
  }
}

class _TemplateCard extends ConsumerWidget {
  const _TemplateCard({required this.template, required this.color});

  final ChecklistTemplate template;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _confirmCreate(context, ref),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(template.description, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.navy),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCreate(BuildContext context, WidgetRef ref) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _TemplatePreviewSheet(template: template),
    );
    if (added != true || !context.mounted) return;
    await createChecklistFromTemplate(ref, template);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${template.name}" added to Check List')),
      );
    }
  }
}

/// Read-only preview of a template's items with a single "Add Checklist"
/// action - replaces the old confirm-dialog-then-auto-navigate flow so the
/// user can see what's in the template first, and the new list simply shows
/// up on the Checklist home screen afterwards (corrections doc, Checklist
/// §1).
class _TemplatePreviewSheet extends StatelessWidget {
  const _TemplatePreviewSheet({required this.template});

  final ChecklistTemplate template;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(template.name, style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(template.description, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: template.items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_box_outline_blank,
                              size: 18,
                              color: AppColors.navySoft,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.text, style: AppTextStyles.body),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add Checklist'),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

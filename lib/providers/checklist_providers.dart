import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:uuid/uuid.dart';

import '../data/models/checklist.dart';
import '../data/models/checklist_item.dart';
import '../data/models/template.dart';
import '../data/repositories/checklist_repository.dart';

const _uuid = Uuid();

final checklistRepositoryProvider = Provider<ChecklistRepository>(
  (ref) => LocalChecklistRepository(),
);
final checklistItemRepositoryProvider = Provider<ChecklistItemRepository>(
  (ref) => LocalChecklistItemRepository(),
);
final userTemplateRepositoryProvider = Provider<UserTemplateRepository>(
  (ref) => LocalUserTemplateRepository(),
);

class ChecklistsNotifier extends AsyncNotifier<List<Checklist>> {
  @override
  Future<List<Checklist>> build() =>
      ref.watch(checklistRepositoryProvider).loadAll();

  Future<Checklist> createChecklist(
    String name, {
    String? sourceTemplateId,
  }) async {
    final now = DateTime.now();
    final checklist = Checklist(
      id: _uuid.v4(),
      name: name,
      sourceTemplateId: sourceTemplateId,
      createdAt: now,
      updatedAt: now,
    );
    final List<Checklist> updated = [...?state.value, checklist];
    state = AsyncData(updated);
    await ref.read(checklistRepositoryProvider).saveAll(updated);
    return checklist;
  }

  Future<void> rename(String id, String name) async {
    final List<Checklist> updated = (state.value ?? const <Checklist>[])
        .map(
          (c) => c.id == id
              ? c.copyWith(name: name, updatedAt: DateTime.now())
              : c,
        )
        .toList();
    state = AsyncData(updated);
    await ref.read(checklistRepositoryProvider).saveAll(updated);
  }

  Future<void> deleteChecklist(String id) async {
    final List<Checklist> updated = (state.value ?? const <Checklist>[])
        .where((c) => c.id != id)
        .toList();
    state = AsyncData(updated);
    await ref.read(checklistRepositoryProvider).saveAll(updated);
    await ref.read(checklistItemsProvider.notifier).deleteAllForChecklist(id);
  }
}

final checklistsProvider =
    AsyncNotifierProvider<ChecklistsNotifier, List<Checklist>>(
      ChecklistsNotifier.new,
    );

class ChecklistItemsNotifier extends AsyncNotifier<List<ChecklistItem>> {
  @override
  Future<List<ChecklistItem>> build() =>
      ref.watch(checklistItemRepositoryProvider).loadAll();

  Future<void> addItem(String checklistId, String text) async {
    final List<ChecklistItem> current = state.value ?? const <ChecklistItem>[];
    final order = current.where((i) => i.checklistId == checklistId).length;
    final item = ChecklistItem(
      id: _uuid.v4(),
      checklistId: checklistId,
      text: text,
      order: order,
    );
    final List<ChecklistItem> updated = [...current, item];
    state = AsyncData(updated);
    await ref.read(checklistItemRepositoryProvider).saveAll(updated);
  }

  Future<void> addItems(String checklistId, List<String> texts) async {
    final List<ChecklistItem> current = state.value ?? const <ChecklistItem>[];
    var order = current.where((i) => i.checklistId == checklistId).length;
    final newItems = [
      for (final text in texts)
        ChecklistItem(
          id: _uuid.v4(),
          checklistId: checklistId,
          text: text,
          order: order++,
        ),
    ];
    final List<ChecklistItem> updated = [...current, ...newItems];
    state = AsyncData(updated);
    await ref.read(checklistItemRepositoryProvider).saveAll(updated);
  }

  Future<void> toggleItem(String id) async {
    final List<ChecklistItem> updated = (state.value ?? const <ChecklistItem>[])
        .map((i) => i.id == id ? i.copyWith(completed: !i.completed) : i)
        .toList();
    state = AsyncData(updated);
    await ref.read(checklistItemRepositoryProvider).saveAll(updated);
  }

  Future<void> editItem(String id, String text) async {
    final List<ChecklistItem> updated = (state.value ?? const <ChecklistItem>[])
        .map((i) => i.id == id ? i.copyWith(text: text) : i)
        .toList();
    state = AsyncData(updated);
    await ref.read(checklistItemRepositoryProvider).saveAll(updated);
  }

  Future<void> deleteItem(String id) async {
    final List<ChecklistItem> updated = (state.value ?? const <ChecklistItem>[])
        .where((i) => i.id != id)
        .toList();
    state = AsyncData(updated);
    await ref.read(checklistItemRepositoryProvider).saveAll(updated);
  }

  Future<void> deleteAllForChecklist(String checklistId) async {
    final List<ChecklistItem> updated = (state.value ?? const <ChecklistItem>[])
        .where((i) => i.checklistId != checklistId)
        .toList();
    state = AsyncData(updated);
    await ref.read(checklistItemRepositoryProvider).saveAll(updated);
  }
}

final checklistItemsProvider =
    AsyncNotifierProvider<ChecklistItemsNotifier, List<ChecklistItem>>(
      ChecklistItemsNotifier.new,
    );

List<ChecklistItem> itemsForChecklist(
  List<ChecklistItem> all,
  String checklistId,
) =>
    all.where((i) => i.checklistId == checklistId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

final builtInTemplatesProvider = Provider<List<ChecklistTemplate>>(
  (ref) => const [
    ChecklistTemplate(
      id: 'builtin_flight_trip',
      name: 'Take a Flight Trip',
      description: 'Passport, tickets, packing list',
      category: 'Travel',
      builtIn: true,
      items: [
        TemplateItem(text: 'Passport', order: 0),
        TemplateItem(text: 'Flight tickets', order: 1),
        TemplateItem(text: 'Boarding pass', order: 2),
        TemplateItem(text: 'Pack luggage', order: 3),
        TemplateItem(text: 'Check-in online', order: 4),
      ],
    ),
    ChecklistTemplate(
      id: 'builtin_vacation',
      name: 'Vacation',
      description: 'Resort booking, itinerary, outfits',
      category: 'Travel',
      builtIn: true,
      items: [
        TemplateItem(text: 'Resort booking confirmation', order: 0),
        TemplateItem(text: 'Trip itinerary', order: 1),
        TemplateItem(text: 'Pack outfits', order: 2),
        TemplateItem(text: 'Sunscreen', order: 3),
        TemplateItem(text: 'Camera', order: 4),
      ],
    ),
    ChecklistTemplate(
      id: 'builtin_long_trip_car',
      name: 'Long Trip - Car',
      description: 'Car check, snacks, music playlist',
      category: 'Travel',
      builtIn: true,
      items: [
        TemplateItem(text: 'Car service check', order: 0),
        TemplateItem(text: 'Snacks', order: 1),
        TemplateItem(text: 'Music playlist', order: 2),
        TemplateItem(text: 'Water bottles', order: 3),
        TemplateItem(text: 'Emergency kit', order: 4),
      ],
    ),
    ChecklistTemplate(
      id: 'builtin_wedding',
      name: 'Wedding Occasion',
      description: 'RSVP, formal wear, gift ideas',
      category: 'Occasion',
      builtIn: true,
      items: [
        TemplateItem(text: 'RSVP', order: 0),
        TemplateItem(text: 'Formal wear', order: 1),
        TemplateItem(text: 'Gift', order: 2),
        TemplateItem(text: 'Transportation', order: 3),
        TemplateItem(text: 'Accommodation', order: 4),
      ],
    ),
    ChecklistTemplate(
      id: 'builtin_temple_visit',
      name: 'Temple Visit',
      description: 'Offerings, dress code, pooja timing',
      category: 'Occasion',
      builtIn: true,
      items: [
        TemplateItem(text: 'Offerings', order: 0),
        TemplateItem(text: 'Appropriate dress', order: 1),
        TemplateItem(text: 'Pooja timing', order: 2),
        TemplateItem(text: 'Footwear removal', order: 3),
        TemplateItem(text: 'Donation', order: 4),
      ],
    ),
    ChecklistTemplate(
      id: 'builtin_car_service',
      name: 'Car Service',
      description: 'Book appointment, filter check, oil change',
      category: 'Vehicle',
      builtIn: true,
      items: [
        TemplateItem(text: 'Book appointment', order: 0),
        TemplateItem(text: 'Oil change', order: 1),
        TemplateItem(text: 'Filter check', order: 2),
        TemplateItem(text: 'Tire rotation', order: 3),
        TemplateItem(text: 'Brake inspection', order: 4),
      ],
    ),
  ],
);

class UserTemplatesNotifier extends AsyncNotifier<List<ChecklistTemplate>> {
  @override
  Future<List<ChecklistTemplate>> build() =>
      ref.watch(userTemplateRepositoryProvider).loadAll();

  Future<void> addTemplate(ChecklistTemplate template) async {
    final List<ChecklistTemplate> updated = [...?state.value, template];
    state = AsyncData(updated);
    await ref.read(userTemplateRepositoryProvider).saveAll(updated);
  }

  Future<void> deleteTemplate(String id) async {
    final List<ChecklistTemplate> updated =
        (state.value ?? const <ChecklistTemplate>[])
            .where((t) => t.id != id)
            .toList();
    state = AsyncData(updated);
    await ref.read(userTemplateRepositoryProvider).saveAll(updated);
  }
}

final userTemplatesProvider =
    AsyncNotifierProvider<UserTemplatesNotifier, List<ChecklistTemplate>>(
      UserTemplatesNotifier.new,
    );

final allTemplatesProvider = Provider<List<ChecklistTemplate>>((ref) {
  final builtIn = ref.watch(builtInTemplatesProvider);
  final user = ref.watch(userTemplatesProvider).value ?? [];
  return [...builtIn, ...user];
});

final templateSearchQueryProvider = StateProvider<String>((ref) => '');
final checklistSearchQueryProvider = StateProvider<String>((ref) => '');

/// Creates a brand-new, independently-editable checklist from a template:
/// items are copied by value, never referenced, so editing the checklist
/// afterwards never mutates the template (Scenario 7).
Future<Checklist> createChecklistFromTemplate(
  WidgetRef ref,
  ChecklistTemplate template,
) async {
  final checklist = await ref
      .read(checklistsProvider.notifier)
      .createChecklist(template.name, sourceTemplateId: template.id);
  final sortedItems = [...template.items]
    ..sort((a, b) => a.order.compareTo(b.order));
  await ref
      .read(checklistItemsProvider.notifier)
      .addItems(checklist.id, sortedItems.map((e) => e.text).toList());
  return checklist;
}

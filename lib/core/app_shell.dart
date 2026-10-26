import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../features/checklist/new_list_dialog.dart';
import '../features/day_planner/task_form_sheet.dart';
import '../features/habit_tracker/habit_form_sheet.dart';
import '../features/mark_a_day/event_form_sheet.dart';
import '../providers/day_event_providers.dart';
import '../providers/task_providers.dart';
import 'clock/clock.dart';
import 'router/route_names.dart';
import 'theme/app_colors.dart';
import 'theme/app_text_styles.dart';
import 'utils/date_utils.dart';
import 'widgets/responsive_body.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _bottomTabs = [
    Routes.today,
    Routes.habitTracker,
    Routes.dayPlanner,
    Routes.notes,
    Routes.timer,
  ];

  int get _bottomIndex {
    final i = _bottomTabs.indexWhere((r) => location.startsWith(r));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = titleForLocation(location);
    return Scaffold(
      appBar: AppBar(title: Text(title, style: AppTextStyles.title)),
      drawer: _AppDrawer(location: location),
      body: SafeArea(top: false, child: ResponsiveBody(child: child)),
      floatingActionButton: _bottomTabs[_bottomIndex] == Routes.timer
          ? null
          : FloatingActionButton(
              onPressed: () => _handleFab(context, ref),
              child: const Icon(Icons.add, size: 28),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) => context.go(_bottomTabs[i]),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.navy,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny, color: Colors.white),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes, color: Colors.white),
            label: 'Habits',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle, color: Colors.white),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: Colors.white),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            selectedIcon: Icon(Icons.timer, color: Colors.white),
            label: 'Timer',
          ),
        ],
      ),
    );
  }

  Future<void> _handleFab(BuildContext context, WidgetRef ref) async {
    if (location.startsWith(Routes.dayPlanner)) {
      final date = ref.read(selectedPlannerDateProvider);
      await showTaskFormSheet(context, ref, initialDate: date);
    } else if (location.startsWith(Routes.habitTracker)) {
      await showHabitFormSheet(context, ref);
    } else if (location.startsWith(Routes.notes)) {
      GoRouter.of(context).push('/notes/new');
    } else if (location.startsWith(Routes.markADay)) {
      final date = ref.read(selectedPlannerDateProvider);
      await showEventFormSheet(context, ref, initialDate: date);
    } else if (location.startsWith(Routes.checklist)) {
      await showNewChecklistDialog(context, ref);
    } else {
      await _showTodayFabChooser(context, ref);
    }
  }

  Future<void> _showTodayFabChooser(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.track_changes_outlined),
                title: const Text('Add Habit'),
                onTap: () => Navigator.of(context).pop('habit'),
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Add Task'),
                onTap: () => Navigator.of(context).pop('task'),
              ),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    if (choice == 'habit') {
      await showHabitFormSheet(context, ref);
    } else {
      await showTaskFormSheet(
        context,
        ref,
        initialDate: ref.read(selectedPlannerDateProvider),
      );
    }
  }
}

class _AppDrawer extends ConsumerWidget {
  const _AppDrawer({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(dayEventsProvider).value ?? [];
    final today = ref.watch(todayProvider);
    final hasUpcoming = events.any((e) {
      final occurrence = nextOccurrence(e, today);
      final diff = AppDateUtils.dateOnly(
        occurrence,
      ).difference(today).inDays;
      return diff >= 0 && diff <= 3;
    });

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('Menu', style: AppTextStyles.label),
            ),
            _DrawerItem(
              icon: Icons.event_available_outlined,
              label: 'Mark a Day',
              selected: location.startsWith(Routes.markADay),
              badge: hasUpcoming,
              onTap: () => _go(context, Routes.markADay),
            ),
            _DrawerItem(
              icon: Icons.checklist_rtl,
              label: 'Check List',
              selected: location.startsWith(Routes.checklist),
              onTap: () => _go(context, Routes.checklist),
            ),
            _DrawerItem(
              icon: Icons.folder_open,
              label: 'Templates',
              selected: location.startsWith(Routes.checklistTemplates),
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.checklistTemplates);
              },
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),
            _DrawerItem(
              icon: Icons.palette_outlined,
              label: 'Customize Theme',
              selected: false,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.settingsTheme);
              },
            ),
            _DrawerItem(
              icon: Icons.cloud_outlined,
              label: 'Account and Backup',
              selected: false,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.settingsBackup);
              },
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              selected: false,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.settingsGeneral);
              },
            ),
            const Divider(height: 24, indent: 16, endIndent: 16),
            _DrawerItem(
              icon: Icons.workspace_premium_outlined,
              label: 'Get Premium',
              selected: false,
              onTap: () {
                Navigator.of(context).pop();
                context.push(Routes.settingsPremium);
              },
            ),
            _DrawerItem(
              icon: Icons.star_outline,
              label: 'Rate this app',
              selected: false,
              onTap: () async {
                Navigator.of(context).pop();
                const packageId = 'com.example.productivity_app';
                final marketUri = Uri.parse(
                  'market://details?id=$packageId',
                );
                final webUri = Uri.parse(
                  'https://play.google.com/store/apps/details?id=$packageId',
                );
                if (!await launchUrl(marketUri)) {
                  await launchUrl(webUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            _DrawerItem(
              icon: Icons.share_outlined,
              label: 'Share this app',
              selected: false,
              onTap: () {
                Navigator.of(context).pop();
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Check out Make it Easy — a simple habit & task tracker: '
                        'https://play.google.com/store/apps/details?id=com.example.productivity_app',
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceMuted : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, color: AppColors.navy),
            if (badge)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.navy,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

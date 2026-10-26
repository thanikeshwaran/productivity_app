import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/checklist/checklist_detail_screen.dart';
import '../../features/checklist/checklist_screen.dart';
import '../../features/checklist/templates_screen.dart';
import '../../features/day_planner/day_planner_screen.dart';
import '../../features/habit_tracker/habit_detail_screen.dart';
import '../../features/habit_tracker/habit_tracker_screen.dart';
import '../../features/mark_a_day/all_events_screen.dart';
import '../../features/mark_a_day/mark_a_day_screen.dart';
import '../../features/notes/note_editor_screen.dart';
import '../../features/notes/notes_screen.dart';
import '../../features/settings/coming_soon_screen.dart';
import '../../features/timer/timer_screen.dart';
import '../../features/today/today_screen.dart';
import '../app_shell.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.today,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: Routes.today,
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: Routes.dayPlanner,
            builder: (context, state) => const DayPlannerScreen(),
          ),
          GoRoute(
            path: Routes.habitTracker,
            builder: (context, state) => const HabitTrackerScreen(),
          ),
          GoRoute(
            path: Routes.notes,
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: Routes.markADay,
            builder: (context, state) => const MarkADayScreen(),
          ),
          GoRoute(
            path: Routes.checklist,
            builder: (context, state) => const ChecklistScreen(),
          ),
          GoRoute(
            path: Routes.timer,
            builder: (context, state) => const TimerScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/habit-tracker/:habitId',
        builder: (context, state) =>
            HabitDetailScreen(habitId: state.pathParameters['habitId']!),
      ),
      GoRoute(
        path: Routes.checklistTemplates,
        builder: (context, state) => const TemplatesScreen(),
      ),
      GoRoute(
        path: '/checklist/:checklistId',
        builder: (context, state) => ChecklistDetailScreen(
          checklistId: state.pathParameters['checklistId']!,
        ),
      ),
      GoRoute(
        path: Routes.markADayEvents,
        builder: (context, state) => const AllEventsScreen(),
      ),
      GoRoute(
        path: '/notes/new',
        builder: (context, state) => const NoteEditorScreen(),
      ),
      GoRoute(
        path: '/notes/:noteId',
        builder: (context, state) =>
            NoteEditorScreen(noteId: state.pathParameters['noteId']!),
      ),
      GoRoute(
        path: Routes.settingsTheme,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Customize Theme'),
      ),
      GoRoute(
        path: Routes.settingsBackup,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Account and Backup'),
      ),
      GoRoute(
        path: Routes.settingsGeneral,
        builder: (context, state) => const ComingSoonScreen(title: 'Settings'),
      ),
      GoRoute(
        path: Routes.settingsPremium,
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Get Premium'),
      ),
    ],
  );
});

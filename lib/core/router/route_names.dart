class Routes {
  Routes._();

  static const today = '/today';
  static const dayPlanner = '/day-planner';
  static const habitTracker = '/habit-tracker';
  static const notes = '/notes';
  static const markADay = '/mark-a-day';
  static const checklist = '/checklist';
  static const checklistTemplates = '/checklist/templates';
  static const timer = '/timer';
  static const markADayEvents = '/mark-a-day/events';
  static const settingsTheme = '/settings/theme';
  static const settingsBackup = '/settings/backup';
  static const settingsGeneral = '/settings/general';
  static const settingsPremium = '/settings/premium';

  static String habitDetail(String habitId) => '/habit-tracker/$habitId';
  static String checklistDetail(String checklistId) =>
      '/checklist/$checklistId';
  static String noteEditor({String? noteId}) =>
      noteId == null ? '/notes/new' : '/notes/$noteId';
}

String titleForLocation(String location) {
  if (location.startsWith(Routes.today)) return 'Today';
  if (location.startsWith(Routes.dayPlanner)) return 'Tasks';
  if (location.startsWith(Routes.habitTracker)) return 'Habits';
  if (location.startsWith(Routes.notes)) return 'Notes';
  if (location.startsWith(Routes.markADay)) return 'Mark a Day';
  if (location.startsWith(Routes.checklist)) return 'Check List';
  if (location.startsWith(Routes.timer)) return 'Timer';
  return '';
}

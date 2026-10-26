# Handoff prompt for continuing "Make it Easy" (productivity_app)

Copy everything below the line into the new LLM / coding assistant as the first message.

---

You are taking over development of an existing Flutter app called **"Make it Easy"** (package `productivity_app`), a personal productivity and habit-tracking app. Another AI assistant built the current version. **Do not modify any code until you have completed the "Phase 0: Orient" steps below and reported back to me.** After that, wait for my approval before each phase.

## 1. Ground rules
1. Do NOT change code, dependencies, or file structure during Phase 0. Reading and running read-only commands (`flutter analyze`, `flutter test`, `git log`) is fine.
2. Make small, reviewable changes. One feature or fix per commit. Never rewrite working files wholesale.
3. Never fake functionality. If a button exists it must work; if a number or chart is shown it must be computed from stored data; if something persists it must survive an app restart.
4. Preserve the existing architecture and visual language (see sections 4 and 6). Do not "improve" the design or swap libraries unless I ask.
5. If something is ambiguous, choose the simplest option that fits the existing code and **tell me the assumption you made**.
6. Do not add attribution lines or co-author trailers to commits unless I ask.
7. Before finishing any task, run `flutter analyze` and `flutter test` and report the results honestly, including failures.

## 2. Project facts (verified)
- Location: `/Users/thanikesh/develop/productivity_app`
- Git: repo exists, branch `main`, remote `https://github.com/thanikeshwaran/productivity_app.git`, single commit "Initial commit", working tree clean at time of writing.
- Platform targets: Flutter (Dart SDK `^3.13.2`), mobile-first; web/desktop must stay usable via a responsive layout (`ResponsiveBody`).
- Size: about 57 Dart files, about 7,900 lines under `lib/`.
- Tech stack (from `pubspec.yaml`):
  - State: `flutter_riverpod ^3.4.3` (AsyncNotifier / Provider)
  - Routing: `go_router ^18.0.1` (ShellRoute + pushed detail routes)
  - Persistence: `shared_preferences` through a generic `JsonListStore<T>`
  - Charts: `fl_chart ^1.2.0`
  - Notifications: `flutter_local_notifications`, `timezone`, `flutter_timezone` (local only; no-op on web/desktop)
  - Misc: `share_plus`, `url_launcher`, `path_provider`, `intl`, `uuid`; dev: `flutter_lints`, `flutter_launcher_icons`
- **There is NO Firebase and NO backend.** Any older notes claiming Firebase are outdated. Persistence is local only, deliberately structured so a backend can be swapped in later.

## 3. Source-of-truth documents (read these first, in this order)
1. `CLAUDE.md` in the project root: the original 34-section product spec (about 19 KB). It defines every screen, the data model, streak rules, date rules, empty-state copy, FAB behavior per screen, and 12 acceptance scenarios (section 32). **Treat it as the requirements document.**
2. `design/Design.pdf`: the visual reference (mockups). The spec says the mockups are the visual source of truth. Open and study the relevant page before touching any screen's UI.
3. `pubspec.yaml`, `analysis_options.yaml`.
4. `lib/` (map below).

Note: `CLAUDE.md` mentions a "corrections doc" in code comments (e.g. do not show the achievement dialog just because a habit is opened). That doc is not in the repo. If a comment cites it, preserve the behavior described in the comment.

## 4. Architecture map (`lib/`)
- `main.dart`, `app.dart`: bootstrap. `main()` initializes `NotificationService`, schedules an evening-journal reminder, then runs `ProviderScope(ProductivityApp)`.
- `core/`
  - `app_shell.dart`: Scaffold with AppBar, **drawer**, **bottom NavigationBar** (Today, Habits, Tasks, Notes, Timer), and the context-sensitive **FAB** (hidden on Timer; on Today it asks "Add Habit / Add Task").
  - `router/app_router.dart`, `route_names.dart`: `Routes` constants plus `titleForLocation`.
  - `theme/` (`app_colors`, `app_text_styles`, `app_theme`), `widgets/` (shared: `section_card`, `empty_state`, `segmented_toggle`, `picker_chip`, `confirm_dialog`, `today_toggle`, `responsive_body`).
  - `calculations/streak_calculator.dart`: **pure functions** `calculateStreaks(...)` and `highestMilestoneReached(...)`. Streaks are always recomputed from stored completion history, never incremented. A habit counts as scheduled every day from `createdAt` through today. This is the correct place for any new habit statistics.
  - `clock/clock.dart` (injectable "today"), `utils/date_utils.dart` (`AppDateUtils.dateOnly`, `key`), `notifications/notification_service.dart`.
- `data/`
  - `models/`: habit, habit_completion (status enum: completed, missed, partial, notScheduled), task, note, checklist, checklist_item, template, day_event, daily_summary, achievement (milestones `[3,7,14,21,25,30,50,100]`), reminder_option.
  - `repositories/`: abstract repository plus `Local*Repository` implementations. **This is the seam for a future backend: replace the Local implementations, not the UI.**
  - `local/json_list_store.dart`: reads and writes a whole list as one JSON string under one SharedPreferences key.
- `providers/`: Riverpod notifiers per domain (`habit_`, `task_`, `note_`, `day_event_`, `checklist_`, `misc_providers`). `HabitCompletionsNotifier.setCompleted` writes the completion, recomputes streaks, and reconciles achievements, returning a newly-unlocked milestone so the UI can show the dialog exactly once.
- `features/`: `today`, `day_planner` (+ task form sheet), `habit_tracker` (list, detail, form sheet), `notes` (list, editor), `mark_a_day` (calendar, all events, event form), `checklist` (list, detail, new-list dialog, templates), `achievements` (dialog, poster/share), `timer`, `settings` (placeholders only).

## 5. Current status (my best assessment; VERIFY, do not trust blindly)
**Appears implemented** (verify each by reading the code and running the app): Today, Day Planner/Tasks with reminders, Habit Tracker with create/detail/streaks, Habit completion with achievements and share poster, Notes with CRUD/search/category filter, Mark a Day with events, Checklists and Templates, a Timer screen, and local notifications for habit alarms and task reminders.

**Known gaps / likely work to do:**
1. **Analytics & Insights screen does not exist** (spec sections 14-17). No analytics route, screen, or provider was found. It needs: Week / Month / All Time filter, Completion Rate, Best Streak, Consistency Heatmap (100% / partial / missed, shades of one accent color), Effort by Category (Health, Work, Personal, Routines), and Weekly Focus Trend (Mon-Sun). All numbers must be computed from real completion/task data. `fl_chart` is already a dependency. It needs a drawer or navigation entry point, since the spec requires Analytics to be reachable.
2. **Settings screens are placeholders** (`ComingSoonScreen`): Customize Theme, Account and Backup, Settings, Get Premium. Decide with me whether to build, hide, or leave them.
3. **Tests are minimal**: `test/widget_test.dart` is only a boot smoke test. The spec's 12 quality scenarios (CLAUDE.md section 32) have no automated coverage. Unit tests for `calculateStreaks` (consecutive days, missed day resets current streak but keeps best, habits created mid-month, month and year boundaries, future dates ignored) are the highest-value first tests.
4. `README.md` is still the Flutter boilerplate.
5. The Rate-this-app drawer item uses the placeholder package id `com.example.productivity_app`. The Android application id is also still the default `com.example...`; this must be changed before any Play Store release.
6. `.gitignore` may not exclude `.DS_Store` or `.claude/settings.local.json`. Check `git ls-files` and clean up if they are tracked.
7. Habit categories: the model has a `category` field defaulting to `'Personal'`. Verify the habit form lets the user choose it, since Effort by Category depends on it.
8. Data is stored as one JSON blob per entity type in SharedPreferences. Fine for v1; flag (do not fix unprompted) any performance or migration concerns, and note there is no schema versioning or migration strategy yet.

## 6. Design and UX constraints
- Warm off-white background, dark navy/charcoal text, rounded cards, subtle shadows, soft pastel accents, large headings, rounded buttons, "+" FAB, spacious layout. No extra gradients, heavy animation, or dashboard styling.
- Use existing tokens in `core/theme/` and shared widgets in `core/widgets/` instead of creating new one-off styles.
- Accessibility: large touch targets, readable contrast, labels, and **never rely on color alone** for completed/missed states (use icons/text too).
- Forms must validate required fields with helpful messages; empty states must use the copy defined in CLAUDE.md section 23.
- Dates: always the user's local date via the injectable clock/`todayProvider`; never hardcode dates.

## 7. Phase 0: Orient (do this now, change nothing)
1. Read `CLAUDE.md` fully and open `design/Design.pdf`.
2. Run `flutter pub get`, `flutter analyze`, `flutter test` and report exact results.
3. Read the files listed in section 4 (at minimum: router, app_shell, streak_calculator, all models, all repositories, all providers, and every screen file).
4. Produce a **gap analysis table**: for each of the 34 CLAUDE.md sections, mark Done / Partial / Missing / Unverified, with the file(s) that implement it and one line of evidence. Do not mark anything Done without having read the code.
5. Walk through the 12 acceptance scenarios in CLAUDE.md section 32 and state, per scenario, whether the code supports it and how you verified that.
6. List any bugs, risks or inconsistencies you found (especially around date handling, streak edge cases, notification scheduling, and state refresh after create/edit/delete).
7. Propose an ordered plan for the remaining work, with effort estimates and any decisions you need from me. Suggested order: (a) unit tests for streak and date logic, (b) Analytics & Insights, (c) fix gaps found in the audit, (d) widget/integration tests for the 12 scenarios, (e) settings placeholders, (f) repo hygiene, README and release config.
8. Stop and wait for my approval.

## 8. How to work after approval
- Branch per feature (`feature/analytics`, etc.); commit small; explain each change in plain language.
- For Analytics: put all aggregation logic in pure, unit-tested functions under `core/calculations/` (like `streak_calculator.dart`), expose it through a provider, and keep the chart widgets dumb. Verify numbers against hand-computed fixtures.
- After each feature, re-run `flutter analyze` and `flutter test`, and manually click through the affected flows on at least one mobile-width and one desktop-width viewport. Tell me what you could and could not verify.
- If you discover that something in this prompt is wrong, say so and correct it rather than working around it.

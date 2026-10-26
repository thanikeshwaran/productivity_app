I want you to build a complete mobile-first personal productivity and habit tracking application based on the UI/UX concept and screen flow I provide.

I have attached reference screenshots/mockups showing the intended design, screens and interactions.

IMPORTANT:
The attached screenshots are the primary visual reference. Do not replace the design with a generic habit-tracker design.

Study the screenshots carefully before implementing anything.

The application should feel like a polished, modern, premium personal productivity app rather than a basic CRUD application.

==================================================
1. CORE APP CONCEPT
   ==================================================

The app combines:

1. Today
2. Day Planner / Tasks
3. Habit Tracker
4. Notes
5. Mark a Day
6. Check Lists
7. Templates
8. Analytics & Insights
9. Habit details and streaks
10. Achievements

The user should be able to move between these sections easily from the main navigation/menu.

The application must have real working interactions and persistent data.

Do NOT create static screens where buttons only look clickable.

Every major button, card, floating action button, tab, menu item, checkbox, calendar date, filter and navigation element should perform the appropriate action.

==================================================
2. DESIGN LANGUAGE
   ==================================================

Use the attached screenshots as the visual source of truth.

Design characteristics visible in the reference:

- Mobile-first layout
- Clean minimalist interface
- Soft warm/off-white background
- Dark navy/charcoal typography
- Rounded cards
- Subtle shadows
- Soft pastel accent colors
- Large readable headings
- Rounded buttons
- Floating action buttons
- Spacious layout
- Modern iOS/Android-style mobile UI
- Friendly but premium appearance
- Clear hierarchy
- Minimal visual clutter

Do not introduce unnecessary gradients, excessive animations, excessive colors, or generic dashboard styling.

The UI should closely resemble the supplied mockups.

Make the application responsive so it works well on mobile and desktop browser widths.

==================================================
3. MAIN NAVIGATION
   ==================================================

The hamburger menu should open navigation containing:

- Today
- Day Planner
- Habit Tracker
- Notes
- Mark a Day
- Check List

The navigation should close after selecting a section.

The current section should be visually indicated.

==================================================
4. TODAY SCREEN
   ==================================================

The Today screen is the primary home screen.

It should contain:

- Header with hamburger menu
- "Today" title
- Habit / Today's Tasks selector or tabs
- Today's habit/task content
- Floating "+" button
- Quick summary area
- Daily summary input near the bottom

The Today screen should dynamically show information relevant to the current date.

Example:

Today's Habits
- Wake Up at 6:00 AM
- Exercise
- Read
- Drink Water

Today's Tasks
- Meeting
- Pay electricity bill
- Call customer

Completed items should visually change state.

The user must be able to mark habits/tasks as completed directly from Today.

The daily summary should allow the user to write a short summary about their day.

==================================================
5. DAY PLANNER / TASKS
   ==================================================

Create a Day Planner screen.

The reference design shows:

- Selected date
- "Tasks"
- Empty state when there are no tasks
- "+" button
- "Add Task"

The user can create tasks.

Task creation must support:

Task Name

Task Type:
- Timed
- Undated

For Timed tasks:

- Fixed Time
- Flexible
- Time
- Date

Example:
12:00 PM
October 15, 2024

Reminder:

- None
- 5 mins
- 1 day
- 3 days
- Specify

Allow editing and deleting tasks.

Tasks should be stored persistently.

Tasks should appear on the appropriate date.

The calendar/date selector must actually work.

==================================================
6. HABIT TRACKER
   ==================================================

Create a Habit Tracker section.

The reference design shows:

"Current Habits"

If there are no habits:

"No habits added yet.
Click '+' to create new."

Provide a floating "+" button.

Creating a habit should open a form containing:

Habit Name

Example:
"Wake Up at 6:00 AM"

Habit Type:
- Timed
- Regular

For timed habits:

Time

Alarm:
- Enable/disable

Allow the user to create the habit.

After creation, the habit should appear in Current Habits.

==================================================
7. HABIT COMPLETION
   ==================================================

Habits must support daily completion.

Each habit should maintain historical completion data.

For every date, the habit can have states such as:

- Completed
- Missed
- Partial / incomplete
- Not scheduled

When the user completes a habit:

- Save the completion
- Update the current streak
- Update the best streak
- Update completion percentage
- Update analytics
- Update calendar/heatmap data
- Update achievements when appropriate

Do not fake these values.

They must be calculated from actual stored data.

==================================================
8. HABIT DETAIL SCREEN
   ==================================================

When the user taps a habit such as:

"Wake Up at 6:00 AM"

open a detailed habit screen.

Show:

Wake Up at 6:00 AM

25 / 30 Days
83% Complete

Show the monthly/day completion calendar.

Each day should visually indicate whether the habit was completed.

Calculate:

- Completed days
- Total scheduled days
- Completion percentage
- Current streak
- Best streak

If the user reaches a milestone such as 25 consecutive days:

show:

"Congratulations!
25-Day Streak!"

Provide a Share button.

==================================================
9. ACHIEVEMENTS
   ==================================================

When a milestone is reached, create an achievement.

Example:

ACHIEVEMENT UNLOCKED

25 Days

Best Streak

Wake up at 6:00 AM

"Consistent. Disciplined. Productive."

Provide:

- Share on Instagram Stories
- Share via system share

The achievement must be generated from actual habit data.

==================================================
10. MARK A DAY
    ==================================================

Create the "Mark a Day" screen.

The reference shows a calendar interface.

The user can select a date.

Show important information/events associated with that date.

Examples:

- Birthday
- Marriage Anniversary
- Exam Date
- Other important events

Allow the user to add/edit/remove events.

Events should be stored persistently.

The selected date should be visually highlighted.

==================================================
11. NOTES
    ==================================================

Create a Notes screen based on the supplied mockup.

The screen should contain:

- Notes title
- Search
- Category/filter chips
- Personal
- Work
- Health
- etc.
- Note cards
- Floating "+" button

Each note card should show:

- Title
- Short content preview
- Category
- Date/time

Allow:

- Create note
- Edit note
- Delete note
- Search notes
- Filter notes by category

Example categories:

Personal
Work
Health
Finance
Ideas
Other

Notes must persist.

==================================================
12. CHECK LIST
    ==================================================

Create a Check List screen.

The reference shows:

- NEW LIST
- TEMPLATES

New List should allow the user to create a checklist.

A checklist contains:

- List name
- Checklist items
- Checkbox for each item

The user can:

- Add item
- Edit item
- Delete item
- Check/uncheck item
- Rename list
- Delete list

Completed items should visually change.

==================================================
13. CHECKLIST TEMPLATES
    ==================================================

Create a Templates screen.

The reference shows template cards such as:

- Take a Flight Trip
- Vacation
- Long Trip - Car
- Wedding Occasion
- Temple Visit
- Car Service

Each template should contain predefined checklist items.

When the user taps a template:

Ask or allow them to create a new checklist from that template.

The new checklist should be editable after creation.

The user should also be able to create their own templates.

==================================================
14. ANALYTICS & INSIGHTS
    ==================================================

Create an Analytics & Insights screen.

The reference design shows:

Analytics & Insights

Filters:

- Week
- Month
- All Time

Show:

Completion Rate
Best Streak

Example:

84%
Completion Rate

25 Days
Best Streak

Also show:

- Consistency Heatmap
- Effort by Category
- Weekly Focus Trend

Categories can include:

Health
Work
Personal
Routines

The charts must use actual habit/task completion data.

Do not hardcode the example numbers.

==================================================
15. CONSISTENCY HEATMAP
    ==================================================

Create a calendar heatmap showing daily consistency.

States:

- 100% completed
- Partial
- Missed

Use progressively different shades of the same accent color.

The heatmap should be generated from actual completion data.

Allow the user to switch:

Week
Month
All Time

==================================================
16. EFFORT BY CATEGORY
    ==================================================

Create a chart showing effort by category.

Example categories:

Health
Work
Personal
Routines

Calculate values from actual user activity.

==================================================
17. WEEKLY FOCUS TREND
    ==================================================

Show a line/bar chart representing the user's focus/completion trend across:

Mon
Tue
Wed
Thu
Fri
Sat
Sun

The chart must update based on actual data.

==================================================
18. DATA MODEL
    ==================================================

Create a proper data model.

At minimum include:

User

Habit
- id
- name
- type
- time
- alarmEnabled
- createdAt
- category
- active

HabitCompletion
- id
- habitId
- date
- status
- completedAt

Task
- id
- name
- type
- date
- time
- flexible
- reminder
- completed
- createdAt

Note
- id
- title
- content
- category
- createdAt
- updatedAt

Checklist
- id
- name
- createdAt
- updatedAt

ChecklistItem
- id
- checklistId
- text
- completed
- order

Template
- id
- name
- description
- category
- items

DayEvent
- id
- date
- type
- title
- description

DailySummary
- id
- date
- summary

Achievement
- id
- type
- habitId
- unlockedAt

Use a clean architecture so this can later be connected to a real backend/database.

==================================================
19. PERSISTENCE
    ==================================================

Data must not disappear when the page/app is refreshed.

For the initial version, use an appropriate local persistence mechanism if a backend is not yet configured.

Structure the application so that a real backend/database can be added later without rewriting the entire UI.

==================================================
20. DATE LOGIC
    ==================================================

Date handling is extremely important.

Use the user's local date.

Do not rely on hardcoded dates.

"Today" must always mean the actual current date.

Habit streak calculations must correctly handle:

- consecutive days
- missed days
- future dates
- habits created after the beginning of a month
- month boundaries
- year boundaries

==================================================
21. STREAK LOGIC
    ==================================================

Implement proper streak calculation.

Example:

Completed:
Monday
Tuesday
Wednesday
Thursday

Current streak = 4

If Friday is missed:

Current streak resets appropriately.

Best streak should remain 4.

Do not simply increment a number without checking historical completion data.

==================================================
22. SEARCH AND FILTERING
    ==================================================

Implement real search.

Notes:
Search title/content.

Checklists:
Search checklist names.

Habits:
Search/filter if useful.

Filtering must update the displayed data immediately.

==================================================
23. EMPTY STATES
    ==================================================

Every section needs a useful empty state.

Examples:

No habits added yet.
Click '+' to create new.

No tasks for this date.
Click '+' to add.

No notes yet.
Create your first note.

No checklists yet.
Create a checklist or use a template.

Do not leave blank screens.

==================================================
24. FLOATING ACTION BUTTON
    ==================================================

Use the "+" floating action button shown in the reference designs.

Its action depends on the current section.

Today:
Add task/habit

Tasks:
Add task

Habit Tracker:
Create habit

Notes:
Create note

Check List:
Create list

Mark a Day:
Add event

==================================================
25. NAVIGATION BEHAVIOR
    ==================================================

Every interaction shown in the reference images should be functional.

Examples:

Hamburger menu → navigation drawer

Habit Tracker → Habit Tracker screen

Notes → Notes screen

Mark a Day → Calendar/events

Check List → Checklist screen

Templates → Templates

Habit card → Habit detail

Analytics → Analytics

"+" → appropriate creation screen/modal

Back → return to previous screen

Save/Create → persist data and return to relevant screen

Cancel → discard changes

==================================================
26. MODALS / FORMS
    ==================================================

Forms should be clean and mobile friendly.

Validate required fields.

Do not allow empty habit names, task names, checklist names or note titles where inappropriate.

Show useful validation messages.

After successful creation:

- Save data
- Close modal/form
- Refresh relevant screen
- Show the new item immediately

==================================================
27. ACCESSIBILITY
    ==================================================

Use:

- readable font sizes
- sufficient contrast
- large touch targets
- accessible labels
- keyboard-friendly forms
- visible focus states

Do not rely only on color to indicate completed/missed status.

==================================================
28. PERFORMANCE
    ==================================================

Keep the application lightweight.

Avoid unnecessary re-renders.

Keep components modular.

Do not put the entire application into one giant component.

==================================================
29. CODE STRUCTURE
    ==================================================

Use a clean component architecture.

Separate:

- UI components
- pages/screens
- state management
- data models
- persistence
- calculations
- analytics
- utility functions

Habit calculations such as streaks and completion percentages should be isolated into reusable functions.

==================================================
30. IMPORTANT DEVELOPMENT RULE
    ==================================================

DO NOT try to fake functionality just to make the screenshots look correct.

The application must actually work.

If a button exists, make it functional.

If a chart exists, calculate its data.

If a streak exists, calculate it.

If a checklist exists, persist it.

If a habit is completed, update analytics.

If a note is created, it must still exist after refreshing the app.

==================================================
31. IMPLEMENTATION STRATEGY
    ==================================================

Do NOT build the entire application blindly in one step.

First:

1. Analyze the attached reference screenshots.
2. Identify every screen.
3. Identify navigation paths.
4. Identify every interactive element.
5. Identify the data required by each screen.
6. Create the application architecture.
7. Build the main navigation and Today screen.
8. Build Habit Tracker.
9. Build Task/Day Planner.
10. Build Notes.
11. Build Mark a Day.
12. Build Check Lists and Templates.
13. Build Analytics.
14. Build Habit Details.
15. Build Achievements.
16. Connect all persistence.
17. Test every click-through flow.
18. Fix inconsistencies.
19. Polish the UI to match the screenshots.

At the beginning, give me a concise implementation plan and proposed project structure.

Then begin implementing the first working version.

==================================================
32. QUALITY CONTROL
    ==================================================

Before considering the application complete, test these scenarios:

Scenario 1:
Create a habit → complete it → refresh → completion remains.

Scenario 2:
Complete a habit for several consecutive days → streak updates correctly.

Scenario 3:
Miss a day → current streak changes correctly while best streak remains.

Scenario 4:
Create a task → assign date → task appears on that date.

Scenario 5:
Create a note → refresh → note remains.

Scenario 6:
Create checklist → add items → check items → refresh → state remains.

Scenario 7:
Create checklist from template → edit it independently.

Scenario 8:
Create a Mark a Day event → select another date → return → event remains.

Scenario 9:
Habit completion changes Analytics.

Scenario 10:
Achievement is unlocked when the actual milestone is reached.

Scenario 11:
Today screen always reflects the actual current date.

Scenario 12:
Navigation works from every screen.

==================================================
33. VISUAL FIDELITY
    ==================================================

## DESIGN REFERENCES

The primary UI/UX references are stored in:

design/

Before implementing or significantly modifying a screen:

1. Inspect the relevant reference image.
2. Compare layout, spacing, typography, colors, cards,
   buttons, navigation, forms and interactions.
3. Preserve the visual language of the reference.
4. Do not replace the design with a generic Flutter UI.
5. Do not redesign the product unnecessarily.

The attached screenshots are the design reference.

Before changing any major visual element, compare the implementation against the reference.

Pay particular attention to:

- spacing
- card shapes
- typography
- button shapes
- floating action button
- navigation drawer
- calendar appearance
- chips/tabs
- colors
- empty states
- modal forms
- charts
- mobile proportions

Do not redesign the product unnecessarily.

==================================================
34. FINAL REQUIREMENT
    ==================================================

Build this as a real usable application, not a static prototype.

The first priority is:

FUNCTIONALITY + CORRECT DATA + NAVIGATION

The second priority is:

VISUAL FIDELITY TO THE ATTACHED MOCKUPS

The third priority is:

POLISH + ACCESSIBILITY + PERFORMANCE

When you encounter ambiguity in the screenshots, choose the simplest implementation that preserves the visual design and overall product concept, and clearly tell me what assumption you made.

Start by analyzing the attached screenshots and giving me:

1. Screen inventory
2. Navigation map
3. Data model
4. Component architecture
5. Implementation phases

Then begin Phase 1.
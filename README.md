# Gigly

A Flutter task management app with Firebase Auth, Cloud Firestore, Clean Architecture, and Riverpod state management.

---

## Features

- **Authentication** — Email/password login and registration with Firebase Auth. Persistent auth state across app restarts. Auth-route redirect guards.
- **Task CRUD** — Create, read, update, and delete tasks with real-time Firestore synchronization.
- **Completion Toggle** — Mark tasks as complete or pending with a single tap.
- **Due Dates** — Optional due dates with overdue detection. Relative labels ("Today", "Tomorrow", "Overdue").
- **Priority Levels** — Low, Medium, High priority assignment per task.
- **Search** — Case-insensitive title search with real-time results.
- **Status Filter** — Filter by All, Pending, or Completed tasks.
- **Priority Filter** — Filter by any priority level.
- **Task Statistics** — Dashboard cards showing total, completed, pending, and overdue counts.
- **Delete with Undo** — Confirmation dialog before delete; SnackBar with undo support.
- **Add/Edit Bottom Sheet** — Combined modal bottom sheet for creating and editing tasks.
- **Error Handling** — User-friendly error messages via SnackBars. Firebase internals never reach the UI.

---

## Architecture

Clean Architecture with three layers per feature:

```
┌─────────────────────────────────────────┐
│           Presentation Layer             │
│  Pages, Providers, Widgets (Riverpod)    │
├─────────────────────────────────────────┤
│            Domain Layer                  │
│  Entities, Repository Interfaces,        │
│  Failure Classes (sealed)                │
├─────────────────────────────────────────┤
│            Data Layer                    │
│  Remote DataSources (Firebase),          │
│  Models (JSON serialization),            │
│  Repository Implementations              │
└─────────────────────────────────────────┘
```

State management uses **Riverpod 3** throughout:

- `StreamProvider` for real-time Firestore queries and auth state
- `NotifierProvider` for mutable UI state (filters, search, action loading)
- `Provider` for derived/computed state (filtered list, stats)
- `AsyncValue` pattern (AsyncLoading / AsyncData / AsyncError) for all async state

Navigation uses **GoRouter** with a single redirect callback that guards routes by auth state:

| Route | Access |
|---|---|
| `/` (Splash) | Public — determines auth state |
| `/login` | Unauthenticated only |
| `/register` | Unauthenticated only |
| `/home` | Authenticated only |

---

## Folder Structure

```
lib/
├── core/
│   ├── errors/            # AuthFailure, TaskFailure sealed hierarchies
│   ├── router/            # GoRouter configuration with auth redirect
│   ├── theme/             # Material 3 theme
│   └── utils/             # Shared utilities
├── features/
│   ├── auth/              # Login, Register, Splash screens
│   │   ├── data/          # FirebaseAuth datasource, AuthException mapping
│   │   ├── domain/        # UserEntity, AuthRepository interface
│   │   └── presentation/  # Screens, AuthNotifier provider
│   ├── tasks/             # Task list, add/edit, delete, search, filter
│   │   ├── data/          # Firestore datasource, TaskModel, TaskException
│   │   ├── domain/        # TaskEntity, TaskRepository interface
│   │   └── presentation/  # HomeScreen, BottomSheet, providers
│   └── dashboard/         # Task statistics widget
│       └── presentation/  # TaskStatsCards widget
├── firebase_options.dart  # FlutterFire-generated config
└── main.dart              # App entry point with Firebase init
```

```
test/
└── features/
    ├── auth/
    │   └── data/repositories/     # AuthRepositoryImpl tests (7)
    └── tasks/
        ├── data/repositories/     # TasksRepositoryImpl tests (14)
        └── presentation/providers/ # TaskFilter, TaskSearch, filteredTasks, TaskActionsNotifier tests (27)
```

---

## Firebase Setup

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com).
2. Enable **Authentication** → **Sign-in method** → **Email/Password**.
3. Enable **Cloud Firestore** in production mode.
4. Register your app (Android, iOS, Web) and download `google-services.json`, `GoogleService-Info.plist`, etc.
5. Run FlutterFire CLI to generate `lib/firebase_options.dart`:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=your-project-id
```

6. Deploy Firestore security rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

> **Note:** This repository does not include private Firebase credentials (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`). You must generate these for your own Firebase project via `flutterfire configure`.

---

## Running Locally

**Prerequisites:** Flutter SDK 3.11+, Firebase project configured.

```bash
# Clone the repository
git clone https://github.com/PrithviKaushik/gigly
cd gigly

# Install dependencies
flutter pub get

# Generate Firebase options (after configuring your project)
flutterfire configure

# Run on a device or emulator
flutter run
```

---

## Testing

The project uses `flutter_test` + `mocktail` for unit testing. Tests cover:

| Layer | Tests |
|---|---|
| `TasksRepositoryImpl` | 14 (CRUD delegation, timestamp stamping, UUID gen, error mapping) |
| `AuthRepositoryImpl` | 7 (login/register/logout success, error mapping, authStateChanges) |
| `TaskFilterNotifier` | 6 (initial state, showCompleted, showPending, showAll, filterByPriority) |
| `TaskSearchNotifier` | 3 (initial, search, clear) |
| `filteredTasksProvider` | 7 (filters, search, combined, case insensitive) |
| `TaskActionsNotifier` | 11 (create/update/delete/toggle/undo/clearState, loading states, error states) |

**Not covered:** widget tests, integration tests, Firestore security rules tests.

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/features/tasks/data/repositories/tasks_repository_impl_test.dart
```

---

## Firestore Rules

Security rules enforce **ownership isolation** — users can only access their own task documents (`/users/{userId}/tasks/{taskId}`).

Key validations:
- **Ownership gate** — `request.auth.uid == userId` on all operations
- **Create** — requires all fields (`id`, `title`, `description`, `priority`, `isCompleted`, `createdAt`, `updatedAt`), valid types, and non-empty strings
- **Read** — ownership only
- **Update** — valid types + immutable field guard (`createdAt` and document `id` cannot change after creation)
- **Delete** — ownership only
- **Deny all** — catch-all rule blocks unowned access

Indexes are defined in `firestore.indexes.json`:
- `dueDate ASCENDING` — sort by due date
- `isCompleted ASCENDING, dueDate ASCENDING` — filter by status + sort
- `priority ASCENDING, dueDate ASCENDING` — filter by priority + sort
- `isCompleted ASCENDING, priority ASCENDING, dueDate ASCENDING` — combined

---

## Screenshots

_Screenshots to be added after building and running on a device._

---

## Future Improvements

- **Material 3 Theming** — Full color scheme, typography, and component theming.
- **Loading Overlay** — Visual loading indicator during task create/update/delete operations.
- **Empty State** — Illustrated placeholder when no tasks exist or no search results match.
- **Due Date Calendar View** — Month/week/day view of tasks by due date.
- **Push Notifications** — Firebase Cloud Messaging for due date reminders.
- **Task Reordering** — Drag-to-reorder with sort-order field.
- **Image Attachments** — Upload images to Cloud Storage and attach to tasks.
- **Offline Support** — Firestore offline persistence for full offline CRUD.
- **Theme Toggle** — Dark mode / light mode switch.
- **Integration Tests** — End-to-end tests covering login → create task → edit → delete → undo.
- **Dedicated Dashboard Screen** — Separate dashboard page with charts and trends (currently the stats widget is embedded in HomeScreen).

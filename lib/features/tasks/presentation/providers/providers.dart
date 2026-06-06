import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/providers.dart';
import '../../data/datasources/datasources.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

final _firestoreTaskDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return FirestoreTaskRemoteDataSource();
});

final taskRepositoryProvider = Provider<TasksRepository>((ref) {
  return TasksRepositoryImpl(
    dataSource: ref.watch(_firestoreTaskDataSourceProvider),
  );
});

final tasksStreamProvider = StreamProvider<List<TaskEntity>>((ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(taskRepositoryProvider).getTasks();
});

final filteredTasksProvider = Provider<AsyncValue<List<TaskEntity>>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  final filter = ref.watch(taskFilterProvider);
  final query = ref.watch(taskSearchProvider);

  return tasksAsync.whenData((tasks) {
    var result = tasks;

    if (filter.showCompleted != null) {
      result = result.where((t) => t.isCompleted == filter.showCompleted).toList();
    }

    if (filter.priority != null) {
      result = result.where((t) => t.priority == filter.priority).toList();
    }

    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      result = result
          .where((t) => t.title.toLowerCase().contains(lowerQuery))
          .toList();
    }

    return result;
  });
});

class TaskFilterNotifier extends Notifier<TaskFilterState> {
  @override
  TaskFilterState build() => const TaskFilterState();

  void showAll() => state = const TaskFilterState();
  void showCompleted() => state = state.copyWith(showCompleted: true);
  void showPending() => state = state.copyWith(showCompleted: false);
  void filterByPriority(TaskPriority? priority) {
    state = state.copyWith(priority: priority);
  }
  void clearPriority() => state = state.copyWith(clearPriority: true);
}

final taskFilterProvider =
    NotifierProvider<TaskFilterNotifier, TaskFilterState>(
  TaskFilterNotifier.new,
);

class TaskSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void search(String query) => state = query;
  void clear() => state = '';
}

final taskSearchProvider =
    NotifierProvider<TaskSearchNotifier, String>(
  TaskSearchNotifier.new,
);

final taskStatsProvider = Provider<AsyncValue<TaskStats>>((ref) {
  final tasksAsync = ref.watch(tasksStreamProvider);
  return tasksAsync.whenData((tasks) {
    final now = DateTime.now();
    var completed = 0;
    var overdue = 0;
    final byPriority = <TaskPriority, int>{};

    for (final task in tasks) {
      if (task.isCompleted) {
        completed++;
      } else if (task.dueDate != null && task.dueDate!.isBefore(now)) {
        overdue++;
      }
      byPriority.update(task.priority, (v) => v + 1, ifAbsent: () => 1);
    }

    return TaskStats(
      total: tasks.length,
      completed: completed,
      pending: tasks.length - completed,
      overdue: overdue,
      byPriority: Map.unmodifiable(byPriority),
    );
  });
});

class TaskActionsNotifier extends Notifier<AsyncValue<void>?> {
  @override
  AsyncValue<void>? build() => null;

  void clearState() => state = null;

  TaskEntity? _lastDeletedTask;

  TasksRepository get _repository => ref.read(taskRepositoryProvider);

  Future<void> createTask({
    required String title,
    String description = '',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now();
      await _repository.createTask(
        TaskEntity(
          id: '',
          title: title,
          description: description,
          dueDate: dueDate,
          priority: priority,
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateTask(TaskEntity task) async {
    state = const AsyncLoading();
    try {
      await _repository.updateTask(task);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleCompletion(TaskEntity task) async {
    await updateTask(task.copyWith(isCompleted: !task.isCompleted));
  }

  Future<void> deleteTask(TaskEntity task) async {
    state = const AsyncLoading();
    _lastDeletedTask = task;
    try {
      await _repository.deleteTask(task.id);
      state = const AsyncData(null);
    } catch (e, st) {
      _lastDeletedTask = null;
      state = AsyncError(e, st);
    }
  }

  Future<void> undoDelete() async {
    final task = _lastDeletedTask;
    if (task == null) return;
    _lastDeletedTask = null;
    state = const AsyncLoading();
    try {
      await _repository.restoreTask(task);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final taskActionsNotifier =
    NotifierProvider<TaskActionsNotifier, AsyncValue<void>?>(
  TaskActionsNotifier.new,
);

class TaskFilterState {
  final bool? showCompleted;
  final TaskPriority? priority;

  const TaskFilterState({this.showCompleted, this.priority});

  TaskFilterState copyWith({
    bool? showCompleted,
    bool clearCompleted = false,
    TaskPriority? priority,
    bool clearPriority = false,
  }) {
    return TaskFilterState(
      showCompleted: clearCompleted ? null : (showCompleted ?? this.showCompleted),
      priority: clearPriority ? null : (priority ?? this.priority),
    );
  }
}

class TaskStats {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final Map<TaskPriority, int> byPriority;

  const TaskStats({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.byPriority,
  });
}

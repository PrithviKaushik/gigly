import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import 'package:gigly/features/auth/domain/entities/entities.dart' as auth;
import 'package:gigly/features/auth/presentation/providers/providers.dart';
import 'package:gigly/features/tasks/domain/entities/entities.dart';
import 'package:gigly/features/tasks/domain/repositories/repositories.dart';
import 'package:gigly/features/tasks/presentation/providers/providers.dart';

class _MockTasksRepository extends Mock implements TasksRepository {}

void main() {
  late _MockTasksRepository mockRepository;
  late List<TaskEntity> tasks;

  setUp(() {
    mockRepository = _MockTasksRepository();
    final now = DateTime.now();
    tasks = [
      TaskEntity(
        id: '1',
        title: 'High pending',
        priority: TaskPriority.high,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
      TaskEntity(
        id: '2',
        title: 'Medium done',
        priority: TaskPriority.medium,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      ),
      TaskEntity(
        id: '3',
        title: 'Low pending',
        priority: TaskPriority.low,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
      TaskEntity(
        id: '4',
        title: 'High done',
        priority: TaskPriority.high,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  });

  Future<void> waitForStream(ProviderContainer container) async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.value();
      final value = container.read(tasksStreamProvider);
      if (value is AsyncData) return;
    }
    throw StateError('tasksStreamProvider did not emit data');
  }

  ProviderContainer createContainer({List<TaskEntity>? overrideTasks}) {
    final testTasks = overrideTasks ?? tasks;
    when(() => mockRepository.getTasks())
        .thenAnswer((_) => Stream.value(testTasks));

    final container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(mockRepository),
        authStateProvider.overrideWith(
          (_) => Stream<auth.UserEntity>.value(
            const auth.UserEntity(id: 'test-uid', email: 'test@test.com'),
          ),
        ),
      ],
    );
    final sub = container.listen(tasksStreamProvider, (_, _) {});
    addTearDown(sub.close);
    addTearDown(container.dispose);
    return container;
  }

  group('filterCountsProvider', () {
    test('unfiltered counts all tasks', () async {
      final container = createContainer();
      await waitForStream(container);

      final counts = container.read(filterCountsProvider).asData!.value;

      expect(counts.statusAll, 4);
      expect(counts.statusPending, 2);
      expect(counts.statusCompleted, 2);
      expect(counts.priorityAll, 4);
      expect(counts.priorityLow, 1);
      expect(counts.priorityMedium, 1);
      expect(counts.priorityHigh, 2);
    });

    test('status row sees active priority filter', () async {
      final container = createContainer();
      await waitForStream(container);

      container
          .read(taskFilterProvider.notifier)
          .filterByPriority(TaskPriority.high);

      await Future<void>.value();

      final counts = container.read(filterCountsProvider).asData!.value;

      expect(counts.statusAll, 2);
      expect(counts.statusPending, 1);
      expect(counts.statusCompleted, 1);
    });

    test('priority row sees active status filter', () async {
      final container = createContainer();
      await waitForStream(container);

      container.read(taskFilterProvider.notifier).showPending();

      await Future<void>.value();

      final counts = container.read(filterCountsProvider).asData!.value;

      expect(counts.priorityAll, 2);
      expect(counts.priorityLow, 1);
      expect(counts.priorityMedium, 0);
      expect(counts.priorityHigh, 1);
    });

    test('empty task list returns zero counts', () async {
      final container = createContainer(overrideTasks: <TaskEntity>[]);
      await waitForStream(container);

      final counts = container.read(filterCountsProvider).asData!.value;

      expect(counts.statusAll, 0);
      expect(counts.statusPending, 0);
      expect(counts.statusCompleted, 0);
      expect(counts.priorityAll, 0);
      expect(counts.priorityLow, 0);
      expect(counts.priorityMedium, 0);
      expect(counts.priorityHigh, 0);
    });
  });
}

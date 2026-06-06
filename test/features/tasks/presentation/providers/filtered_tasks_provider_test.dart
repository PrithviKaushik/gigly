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
        title: 'Buy groceries',
        priority: TaskPriority.high,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
      TaskEntity(
        id: '2',
        title: 'Pay bills',
        priority: TaskPriority.medium,
        isCompleted: true,
        createdAt: now,
        updatedAt: now,
      ),
      TaskEntity(
        id: '3',
        title: 'Walk dog',
        priority: TaskPriority.low,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
      TaskEntity(
        id: '4',
        title: 'GROCERIES delivery',
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

  ProviderContainer createContainer() {
    when(() => mockRepository.getTasks())
        .thenAnswer((_) => Stream.value(tasks));

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

  group('filteredTasksProvider', () {
    test('no filters returns all tasks', () async {
      final container = createContainer()
;
      await waitForStream(container);

      final result = container.read(filteredTasksProvider).asData!.value;

      expect(result, hasLength(4));
    });

    test('completed filter returns only completed tasks', () async {
      final container = createContainer()
;
      container.read(taskFilterProvider.notifier).showCompleted();
      await waitForStream(container);

      final result = container.read(filteredTasksProvider).asData!.value;

      expect(result, hasLength(2));
      expect(result.every((t) => t.isCompleted), isTrue);
    });

    test('pending filter returns only pending tasks', () async {
      final container = createContainer()
;
      container.read(taskFilterProvider.notifier).showPending();
      await waitForStream(container);

      final result = container.read(filteredTasksProvider).asData!.value;

      expect(result, hasLength(2));
      expect(result.every((t) => !t.isCompleted), isTrue);
    });

    test('priority filter returns only matching priority', () async {
      final container = createContainer()
;
      container
          .read(taskFilterProvider.notifier)
          .filterByPriority(TaskPriority.high);
      await waitForStream(container);

      final result = container.read(filteredTasksProvider).asData!.value;

      expect(result, hasLength(2));
      expect(
        result.every((t) => t.priority == TaskPriority.high),
        isTrue,
      );
    });

    test('search filter returns matching titles', () async {
      final container = createContainer()
;
      container.read(taskSearchProvider.notifier).search('groceries');
      await waitForStream(container);

      final result = container.read(filteredTasksProvider).asData!.value;

      expect(result, hasLength(2));
      expect(result.map((t) => t.id), containsAll(['1', '4']));
    });

    test('search + priority combined filters', () async {
      final container = createContainer()
;
      container.read(taskSearchProvider.notifier).search('groceries');
      container
          .read(taskFilterProvider.notifier)
          .filterByPriority(TaskPriority.high);
      await waitForStream(container);

      final result = container.read(filteredTasksProvider).asData!.value;

      expect(result, hasLength(2));
      expect(result.map((t) => t.id), containsAll(['1', '4']));
      expect(
        result.every((t) => t.priority == TaskPriority.high),
        isTrue,
      );
    });

    test('search is case insensitive', () async {
      final container = createContainer()
;
      container.read(taskSearchProvider.notifier).search('GROCERIES');
      await waitForStream(container);

      final result = container.read(filteredTasksProvider).asData!.value;

      expect(result, hasLength(2));
      expect(result.map((t) => t.id), containsAll(['1', '4']));
    });
  });
}

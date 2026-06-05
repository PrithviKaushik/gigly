import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

import 'package:gigly/core/errors/errors.dart';
import 'package:gigly/features/tasks/domain/entities/entities.dart';
import 'package:gigly/features/tasks/domain/repositories/repositories.dart';
import 'package:gigly/features/tasks/presentation/providers/providers.dart';

class _MockTasksRepository extends Mock implements TasksRepository {}

void main() {
  late _MockTasksRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(TaskEntity(
      id: '',
      title: '',
      createdAt: DateTime(2000),
      updatedAt: DateTime(2000),
    ));
  });

  setUp(() {
    mockRepository = _MockTasksRepository();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        taskRepositoryProvider.overrideWithValue(mockRepository),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('createTask', () {
    test('success sets loading then data state', () async {
      when(() => mockRepository.createTask(any())).thenAnswer(
        (_) async => TaskEntity(
          id: 'generated-id',
          title: 'Test Task',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      );

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);

      expect(container.read(taskActionsNotifier), isNull);

      final future = notifier.createTask(title: 'Test Task');

      expect(container.read(taskActionsNotifier), isA<AsyncLoading<void>>());

      await future;

      expect(container.read(taskActionsNotifier), isA<AsyncData<void>>());
    });

    test('failure sets loading then error state (no rethrow)', () async {
      when(() => mockRepository.createTask(any()))
          .thenAnswer((_) => Future.error(const TaskPermissionDenied()));

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);

      final future = notifier.createTask(title: 'Test');

      expect(container.read(taskActionsNotifier), isA<AsyncLoading<void>>());

      await future;

      final state = container.read(taskActionsNotifier);
      expect(state, isA<AsyncError<void>>());
      expect((state as AsyncError<void>).error, isA<TaskPermissionDenied>());
    });
  });

  group('updateTask', () {
    test('success sets loading then data state', () async {
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);
      final task = TaskEntity(
        id: 'task-1',
        title: 'Update me',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final future = notifier.updateTask(task);

      expect(container.read(taskActionsNotifier), isA<AsyncLoading<void>>());

      await future;

      expect(container.read(taskActionsNotifier), isA<AsyncData<void>>());
      verify(() => mockRepository.updateTask(task)).called(1);
    });

    test('failure sets loading then error state (no rethrow)', () async {
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) => Future.error(const TaskNetworkError()));

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);
      final task = TaskEntity(
        id: 'task-1',
        title: 'Fail me',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await notifier.updateTask(task);

      final state = container.read(taskActionsNotifier);
      expect(state, isA<AsyncError<void>>());
      expect((state as AsyncError<void>).error, isA<TaskNetworkError>());
    });
  });

  group('toggleCompletion', () {
    test('calls updateTask on repository with isCompleted flipped', () async {
      when(() => mockRepository.updateTask(any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);
      final task = TaskEntity(
        id: 'task-1',
        title: 'Toggle me',
        isCompleted: false,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await notifier.toggleCompletion(task);

      final captured = verify(() => mockRepository.updateTask(captureAny()))
          .captured
          .single as TaskEntity;
      expect(captured.id, 'task-1');
      expect(captured.isCompleted, isTrue);
    });
  });

  group('deleteTask', () {
    test('success sets loading then data state and delegates to repository',
        () async {
      when(() => mockRepository.deleteTask(any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);
      final task = TaskEntity(
        id: 'task-1',
        title: 'Delete me',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final future = notifier.deleteTask(task);

      expect(container.read(taskActionsNotifier), isA<AsyncLoading<void>>());

      await future;

      expect(container.read(taskActionsNotifier), isA<AsyncData<void>>());
      verify(() => mockRepository.deleteTask('task-1')).called(1);
    });

    test('failure sets loading then error state (no rethrow)', () async {
      when(() => mockRepository.deleteTask(any()))
          .thenAnswer((_) => Future.error(const TaskNetworkError()));

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);
      final task = TaskEntity(
        id: 'task-1',
        title: 'Fail delete',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final future = notifier.deleteTask(task);

      expect(container.read(taskActionsNotifier), isA<AsyncLoading<void>>());

      await future;

      final state = container.read(taskActionsNotifier);
      expect(state, isA<AsyncError<void>>());
      expect((state as AsyncError<void>).error, isA<TaskNetworkError>());
    });
  });

  group('undoDelete', () {
    test('restores cached task on repository', () async {
      when(() => mockRepository.deleteTask(any()))
          .thenAnswer((_) async {});
      when(() => mockRepository.restoreTask(any()))
          .thenAnswer((_) async {});

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);
      final task = TaskEntity(
        id: 'task-1',
        title: 'Restore me',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await notifier.deleteTask(task);

      final future = notifier.undoDelete();

      expect(container.read(taskActionsNotifier), isA<AsyncLoading<void>>());

      await future;

      verify(() => mockRepository.restoreTask(task)).called(1);
      expect(container.read(taskActionsNotifier), isA<AsyncData<void>>());
    });

    test('no-op when no cached task (undoDelete before any delete)', () async {
      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);

      expect(container.read(taskActionsNotifier), isNull);

      await notifier.undoDelete();

      verifyNever(() => mockRepository.restoreTask(any()));
      expect(container.read(taskActionsNotifier), isNull);
    });

    test('no-op when cache cleared by failed delete', () async {
      when(() => mockRepository.deleteTask(any()))
          .thenAnswer((_) => Future.error(const TaskNetworkError()));

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);
      final task = TaskEntity(
        id: 'task-1',
        title: 'Fail then undo',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      await notifier.deleteTask(task);

      await notifier.undoDelete();

      verifyNever(() => mockRepository.restoreTask(any()));
      expect(container.read(taskActionsNotifier), isA<AsyncError<void>>());
    });
  });

  group('clearState', () {
    test('resets state to null after successful operation', () async {
      when(() => mockRepository.createTask(any())).thenAnswer(
        (_) async => TaskEntity(
          id: 'id',
          title: 'T',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      );

      final container = createContainer();
      final notifier = container.read(taskActionsNotifier.notifier);

      await notifier.createTask(title: 'T');

      expect(container.read(taskActionsNotifier), isA<AsyncData<void>>());

      notifier.clearState();

      expect(container.read(taskActionsNotifier), isNull);
    });
  });
}

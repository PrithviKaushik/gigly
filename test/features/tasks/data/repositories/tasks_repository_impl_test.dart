import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:gigly/core/errors/errors.dart';
import 'package:gigly/features/tasks/data/datasources/datasources.dart';
import 'package:gigly/features/tasks/data/datasources/task_exception.dart';
import 'package:gigly/features/tasks/data/models/models.dart';
import 'package:gigly/features/tasks/data/repositories/repositories.dart';
import 'package:gigly/features/tasks/domain/entities/entities.dart';

class _MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}

class _MockUuid extends Mock implements Uuid {}

void main() {
  late _MockTaskRemoteDataSource mockDataSource;
  late _MockUuid mockUuid;
  late TasksRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      TaskModel(id: '', title: '', createdAt: DateTime(2000), updatedAt: DateTime(2000)),
    );
  });

  setUp(() {
    mockDataSource = _MockTaskRemoteDataSource();
    mockUuid = _MockUuid();
    repository = TasksRepositoryImpl(
      dataSource: mockDataSource,
      uuid: mockUuid,
    );
  });

  group('createTask', () {
    final fixedDate = DateTime(2024, 6, 15, 10, 30, 0);

    setUp(() {
      when(() => mockUuid.v4()).thenReturn('generated-uuid');
      when(() => mockDataSource.createTask(any())).thenAnswer((_) async {});
    });

    test('generates UUID', () async {
      await repository.createTask(
        TaskEntity(
          id: '',
          title: 'Test',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      verify(() => mockUuid.v4()).called(1);
    });

    test('returns entity with generated UUID', () async {
      final result = await repository.createTask(
        TaskEntity(
          id: '',
          title: 'Test',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      expect(result.id, 'generated-uuid');
    });

    test('sets timestamps to now (not the input dates)', () async {
      final result = await repository.createTask(
        TaskEntity(
          id: '',
          title: 'Test',
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      expect(result.createdAt, isNot(fixedDate));
      expect(result.updatedAt, isNot(fixedDate));
    });

    test('delegates TaskModel with correct fields to datasource', () async {
      await repository.createTask(
        TaskEntity(
          id: '',
          title: 'Shopping list',
          description: 'Milk, eggs',
          priority: TaskPriority.high,
          isCompleted: false,
          createdAt: fixedDate,
          updatedAt: fixedDate,
        ),
      );

      final captured = verify(() => mockDataSource.createTask(captureAny()))
          .captured
          .single as TaskModel;
      expect(captured.id, 'generated-uuid');
      expect(captured.title, 'Shopping list');
      expect(captured.description, 'Milk, eggs');
      expect(captured.priority, TaskPriority.high);
      expect(captured.isCompleted, false);
    });
  });

  group('updateTask', () {
    test('delegates TaskModel with bumped updatedAt', () async {
      when(() => mockDataSource.updateTask(any())).thenAnswer((_) async {});

      await repository.updateTask(
        TaskEntity(
          id: 'task-1',
          title: 'Updated',
          createdAt: DateTime(2024, 1, 1),
          updatedAt: DateTime(2024, 1, 1),
        ),
      );

      final captured = verify(() => mockDataSource.updateTask(captureAny()))
          .captured
          .single as TaskModel;
      expect(captured.id, 'task-1');
      expect(captured.title, 'Updated');
      expect(captured.updatedAt.isAfter(DateTime(2024, 1, 1)), isTrue);
    });
  });

  group('deleteTask', () {
    test('delegates with correct id to datasource', () async {
      when(() => mockDataSource.deleteTask(any())).thenAnswer((_) async {});

      await repository.deleteTask('task-1');

      verify(() => mockDataSource.deleteTask('task-1')).called(1);
    });
  });

  group('getTasks', () {
    test('converts models to entities and emits single list', () async {
      final now = DateTime.now();
      final models = [
        TaskModel(id: '1', title: 'A', createdAt: now, updatedAt: now),
        TaskModel(id: '2', title: 'B', createdAt: now, updatedAt: now),
      ];

      when(() => mockDataSource.getTasks())
          .thenAnswer((_) => Stream.value(models));

      final snapshots = await repository.getTasks().toList();

      expect(snapshots, hasLength(1));
      final entities = snapshots.first;
      expect(entities, hasLength(2));
      expect(entities[0].id, '1');
      expect(entities[0].title, 'A');
      expect(entities[1].id, '2');
      expect(entities[1].title, 'B');
    });
  });

  group('TaskException mapping', () {
    setUp(() {
      when(() => mockUuid.v4()).thenReturn('id');
    });

    test('not-found maps to TaskNotFound', () async {
      when(() => mockDataSource.createTask(any()))
          .thenThrow(const TaskException(code: 'not-found'));

      expect(
        () => repository.createTask(
          TaskEntity(
            id: '',
            title: 'T',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ),
        throwsA(isA<TaskNotFound>()),
      );
    });

    test('permission-denied maps to TaskPermissionDenied', () async {
      when(() => mockDataSource.createTask(any()))
          .thenThrow(const TaskException(code: 'permission-denied'));

      expect(
        () => repository.createTask(
          TaskEntity(
            id: '',
            title: 'T',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ),
        throwsA(isA<TaskPermissionDenied>()),
      );
    });

    test('unavailable maps to TaskNetworkError', () async {
      when(() => mockDataSource.createTask(any()))
          .thenThrow(const TaskException(code: 'unavailable'));

      expect(
        () => repository.createTask(
          TaskEntity(
            id: '',
            title: 'T',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ),
        throwsA(isA<TaskNetworkError>()),
      );
    });

    test('network-request-failed maps to TaskNetworkError', () async {
      when(() => mockDataSource.createTask(any()))
          .thenThrow(const TaskException(code: 'network-request-failed'));

      expect(
        () => repository.createTask(
          TaskEntity(
            id: '',
            title: 'T',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ),
        throwsA(isA<TaskNetworkError>()),
      );
    });

    test('no-user maps to TaskPermissionDenied', () async {
      when(() => mockDataSource.createTask(any()))
          .thenThrow(const TaskException(code: 'no-user'));

      expect(
        () => repository.createTask(
          TaskEntity(
            id: '',
            title: 'T',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ),
        throwsA(isA<TaskPermissionDenied>()),
      );
    });

    test('unknown code maps to TaskUnknown with message', () async {
      when(() => mockDataSource.createTask(any())).thenThrow(
        const TaskException(code: 'weird', message: 'Something weird'),
      );

      expect(
        () => repository.createTask(
          TaskEntity(
            id: '',
            title: 'T',
            createdAt: DateTime(2024, 1, 1),
            updatedAt: DateTime(2024, 1, 1),
          ),
        ),
        throwsA(
          isA<TaskUnknown>()
              .having((e) => e.message, 'message', 'Something weird'),
        ),
      );
    });
  });

  group('Unknown exception handling', () {
    test('non-TaskException from datasource stream maps to TaskUnknown', () async {
      when(() => mockDataSource.getTasks())
          .thenAnswer((_) => Stream.error(Exception('unexpected')));

      expect(
        repository.getTasks().toList(),
        throwsA(isA<TaskUnknown>()),
      );
    });
  });
}

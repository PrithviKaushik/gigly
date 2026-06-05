import 'package:uuid/uuid.dart';

import '../../../../core/errors/errors.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/datasources.dart';
import '../datasources/task_exception.dart';
import '../models/models.dart';

class TasksRepositoryImpl implements TasksRepository {
  final TaskRemoteDataSource _dataSource;
  final Uuid _uuid;

  TasksRepositoryImpl({
    required TaskRemoteDataSource dataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Stream<List<TaskEntity>> getTasks() {
    return _dataSource.getTasks().map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Future<TaskEntity> getTask(String id) async {
    try {
      final model = await _dataSource.getTask(id);
      return model.toEntity();
    } on TaskException catch (e) {
      throw _mapToFailure(e);
    }
  }

  @override
  Future<TaskEntity> createTask(TaskEntity task) async {
    final now = DateTime.now();
    final entity = task.copyWith(
      id: _uuid.v4(),
      createdAt: now,
      updatedAt: now,
    );
    final model = TaskModel.fromEntity(entity);
    try {
      await _dataSource.createTask(model);
      return entity;
    } on TaskException catch (e) {
      throw _mapToFailure(e);
    }
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final now = DateTime.now();
    final entity = task.copyWith(updatedAt: now);
    final model = TaskModel.fromEntity(entity);
    try {
      await _dataSource.updateTask(model);
    } on TaskException catch (e) {
      throw _mapToFailure(e);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _dataSource.deleteTask(id);
    } on TaskException catch (e) {
      throw _mapToFailure(e);
    }
  }

  TaskFailure _mapToFailure(TaskException e) {
    return switch (e.code) {
      'not-found' => const TaskNotFound(),
      'permission-denied' => const TaskPermissionDenied(),
      'unavailable' || 'network-request-failed' => const TaskNetworkError(),
      'no-user' => const TaskPermissionDenied(),
      _ => TaskUnknown(e.message ?? 'An unexpected error occurred.'),
    };
  }
}

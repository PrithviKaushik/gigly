import '../entities/entities.dart';

abstract class TasksRepository {
  Stream<List<TaskEntity>> getTasks();
  Future<TaskEntity> getTask(String id);
  Future<TaskEntity> createTask(TaskEntity task);
  Future<void> updateTask(TaskEntity task);
  Future<void> deleteTask(String id);
  Future<void> restoreTask(TaskEntity task);
}

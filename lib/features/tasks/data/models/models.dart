import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/entities.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      dueDate: entity.dueDate,
      priority: entity.priority,
      isCompleted: entity.isCompleted,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      dueDate: (json['dueDate'] as Timestamp?)?.toDate(),
      priority: _priorityFromJson(json['priority']),
      isCompleted: (json['isCompleted'] as bool?) ?? false,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      updatedAt: (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'priority': _priorityToJson(priority),
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TaskEntity toEntity() {
    return TaskEntity(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      isCompleted: isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static TaskPriority _priorityFromJson(dynamic value) {
    if (value is String) {
      return TaskPriority.values.firstWhere(
        (p) => p.name == value,
        orElse: () => TaskPriority.medium,
      );
    }
    return TaskPriority.medium;
  }

  static String _priorityToJson(TaskPriority priority) => priority.name;
}

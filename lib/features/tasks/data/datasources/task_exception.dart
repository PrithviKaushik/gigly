import 'package:cloud_firestore/cloud_firestore.dart';

class TaskException implements Exception {
  final String code;
  final String? message;

  const TaskException({required this.code, this.message});

  factory TaskException.fromFirebase(FirebaseException e) {
    return TaskException(code: e.code, message: e.message);
  }

  factory TaskException.noCurrentUser() {
    return TaskException(
      code: 'no-user',
      message: 'User is not authenticated.',
    );
  }

  factory TaskException.notFound() {
    return const TaskException(code: 'not-found', message: 'Task not found.');
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;

import 'task_exception.dart';
import '../models/models.dart';

abstract class TaskRemoteDataSource {
  Stream<List<TaskModel>> getTasks();
  Future<TaskModel> getTask(String id);
  Future<void> createTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
}

class FirestoreTaskRemoteDataSource implements TaskRemoteDataSource {
  final FirebaseFirestore _firestore;
  final fa.FirebaseAuth _auth;

  FirestoreTaskRemoteDataSource({
    FirebaseFirestore? firestore,
    fa.FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? fa.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _tasksRef() {
    final user = _auth.currentUser;
    if (user == null) {
      throw TaskException.noCurrentUser();
    }
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snapshot, _) => snapshot.data() ?? <String, dynamic>{},
          toFirestore: (data, _) => data,
        );
  }

  @override
  Stream<List<TaskModel>> getTasks() {
    return _tasksRef()
        .orderBy('dueDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.exists)
          .map((doc) {
            final data = doc.data();
            return TaskModel.fromJson({...data, 'id': doc.id});
          })
          .toList();
    }).handleError((Object error) {
      if (error is TaskException) throw error;
      if (error is FirebaseException) throw TaskException.fromFirebase(error);
      throw TaskException(code: 'unknown', message: error.toString());
    });
  }

  @override
  Future<TaskModel> getTask(String id) async {
    try {
      final doc = await _tasksRef().doc(id).get();
      if (!doc.exists) {
        throw TaskException.notFound();
      }
      final data = doc.data()!;
      return TaskModel.fromJson({...data, 'id': doc.id});
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  @override
  Future<void> createTask(TaskModel task) async {
    try {
      await _tasksRef().doc(task.id).set(task.toJson());
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    try {
      await _tasksRef().doc(task.id).update(task.toJson());
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _tasksRef().doc(id).delete();
    } on FirebaseException catch (e) {
      throw TaskException.fromFirebase(e);
    }
  }
}

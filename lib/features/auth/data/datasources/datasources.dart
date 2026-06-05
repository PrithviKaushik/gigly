import 'package:firebase_auth/firebase_auth.dart' as fa;

import 'auth_exception.dart';
import '../models/models.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({required String email, required String password});
  Future<void> logout();
}

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final fa.FirebaseAuth _auth;

  FirebaseAuthRemoteDataSource({fa.FirebaseAuth? auth})
      : _auth = auth ?? fa.FirebaseAuth.instance;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapUser(credential.user);
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  @override
  Future<UserModel> register({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapUser(credential.user);
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  UserModel _mapUser(fa.User? user) {
    if (user == null) {
      throw AuthException.unexpectedError(
        'User returned null after successful authentication.',
      );
    }
    final email = user.email;
    if (email == null) {
      throw AuthException.unexpectedError(
        'Email is null after email/password authentication.',
      );
    }
    return UserModel(
      id: user.uid,
      email: email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}

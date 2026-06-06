import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_exception.dart';
import '../models/models.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({required String email, required String password});
  Future<UserModel> signInWithGoogle();
  Future<void> logout();
  Stream<UserModel?> authStateChanges();
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
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = fa.GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      return _mapUser(result.user);
    } on GoogleSignInException catch (e) {
      final code = switch (e.code) {
        GoogleSignInExceptionCode.canceled ||
        GoogleSignInExceptionCode.interrupted ||
        GoogleSignInExceptionCode.uiUnavailable =>
          'popup-closed-by-user',
        _ => 'google-sign-in-failed',
      };
      throw AuthException(
        code: code,
        message: e.description ?? 'Google Sign-In failed.',
      );
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    } catch (e) {
      throw AuthException(
        code: 'google-sign-in-failed',
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await GoogleSignIn.instance.signOut();
    } on fa.FirebaseAuthException catch (e) {
      throw AuthException.fromFirebase(e);
    }
  }

  @override
  Stream<UserModel?> authStateChanges() {
    return _auth.authStateChanges().map(_mapFirebaseUser);
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

  UserModel? _mapFirebaseUser(fa.User? user) {
    if (user == null) return null;
    final email = user.email;
    if (email == null) return null;
    return UserModel(
      id: user.uid,
      email: email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}

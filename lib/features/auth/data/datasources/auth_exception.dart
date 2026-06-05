import 'package:firebase_auth/firebase_auth.dart';

class AuthException implements Exception {
  final String code;
  final String? message;

  const AuthException({required this.code, this.message});

  factory AuthException.fromFirebase(FirebaseAuthException e) {
    return AuthException(code: e.code, message: e.message);
  }

  factory AuthException.unexpectedError(String message) {
    return AuthException(code: 'unexpected-error', message: message);
  }
}

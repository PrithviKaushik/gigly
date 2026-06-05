import '../../../../core/errors/errors.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/auth_exception.dart';
import '../datasources/datasources.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _dataSource;

  AuthRepositoryImpl({required AuthRemoteDataSource dataSource})
      : _dataSource = dataSource;

  @override
  Future<UserEntity> login({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _dataSource.login(email: email, password: password);
      return model.toEntity();
    } on AuthException catch (e) {
      throw _mapToFailure(e);
    }
  }

  @override
  Future<UserEntity> register({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _dataSource.register(email: email, password: password);
      return model.toEntity();
    } on AuthException catch (e) {
      throw _mapToFailure(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dataSource.logout();
    } on AuthException catch (e) {
      throw _mapToFailure(e);
    }
  }

  AuthFailure _mapToFailure(AuthException e) {
    return switch (e.code) {
      'invalid-email' => const AuthInvalidEmail(),
      'wrong-password' => const AuthWrongPassword(),
      'invalid-credential' => const AuthInvalidCredentials(),
      'invalid-login-credentials' => const AuthInvalidCredentials(),
      'user-not-found' => const AuthUserNotFound(),
      'email-already-in-use' => const AuthEmailAlreadyInUse(),
      'weak-password' => const AuthWeakPassword(),
      'network-request-failed' => const AuthNetworkError(),
      _ => AuthUnknown(e.message ?? 'An unexpected error occurred.'),
    };
  }
}

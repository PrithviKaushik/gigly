import '../entities/entities.dart';

abstract class AuthRepository {
  Future<UserEntity> login({required String email, required String password});
  Future<UserEntity> register({required String email, required String password});
  Future<void> logout();
  Stream<UserEntity?> authStateChanges();
}

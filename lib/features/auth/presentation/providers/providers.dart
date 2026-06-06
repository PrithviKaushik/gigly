import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/errors.dart';
import '../../data/datasources/datasources.dart';
import '../../data/repositories/repositories.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

final _authDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return FirebaseAuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    dataSource: ref.watch(_authDataSourceProvider),
  );
});

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

class AuthNotifier extends Notifier<AsyncValue<void>?> {
  @override
  AsyncValue<void>? build() => null;

  void clearState() => state = null;

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repository.login(email: email, password: password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _repository.register(email: email, password: password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      await _repository.signInWithGoogle();
      state = const AsyncData(null);
    } on AuthPopupClosed {
      state = null;
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repository.logout();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<void>?>(
  AuthNotifier.new,
);

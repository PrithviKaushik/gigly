import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:gigly/core/errors/errors.dart';
import 'package:gigly/features/auth/data/datasources/auth_exception.dart';
import 'package:gigly/features/auth/data/datasources/datasources.dart';
import 'package:gigly/features/auth/data/models/models.dart';
import 'package:gigly/features/auth/data/repositories/repositories.dart';
import 'package:gigly/features/auth/domain/entities/entities.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

void main() {
  late _MockAuthRemoteDataSource mockDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockDataSource = _MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(dataSource: mockDataSource);
  });

  group('login', () {
    test('returns UserEntity on success', () async {
      when(() => mockDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => const UserModel(id: 'uid-1', email: 'a@b.com'),
      );

      final result = await repository.login(
        email: 'a@b.com',
        password: 'secret',
      );

      expect(result, isA<UserEntity>());
      expect(result.id, 'uid-1');
      expect(result.email, 'a@b.com');
      verify(() => mockDataSource.login(
            email: 'a@b.com',
            password: 'secret',
          )).called(1);
    });

    test('throws AuthInvalidEmail on invalid-email', () async {
      when(() => mockDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        const AuthException(code: 'invalid-email', message: 'Bad email'),
      );

      expect(
        () => repository.login(email: 'x', password: 'y'),
        throwsA(isA<AuthInvalidEmail>()),
      );
    });

    test('throws AuthWrongPassword on wrong-password', () async {
      when(() => mockDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        const AuthException(code: 'wrong-password', message: 'Wrong pw'),
      );

      expect(
        () => repository.login(email: 'x', password: 'y'),
        throwsA(isA<AuthWrongPassword>()),
      );
    });

    test('throws AuthUnknown on unknown AuthException code', () async {
      when(() => mockDataSource.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(
        const AuthException(code: 'weird', message: 'Something odd'),
      );

      expect(
        () => repository.login(email: 'x', password: 'y'),
        throwsA(
          isA<AuthUnknown>()
              .having((e) => e.message, 'message', 'Something odd'),
        ),
      );
    });
  });

  group('register', () {
    test('returns UserEntity on success', () async {
      when(() => mockDataSource.register(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer(
        (_) async => const UserModel(id: 'uid-2', email: 'b@c.com'),
      );

      final result = await repository.register(
        email: 'b@c.com',
        password: 'secret',
      );

      expect(result, isA<UserEntity>());
      expect(result.id, 'uid-2');
      expect(result.email, 'b@c.com');
      verify(() => mockDataSource.register(
            email: 'b@c.com',
            password: 'secret',
          )).called(1);
    });
  });

  group('logout', () {
    test('calls datasource logout', () async {
      when(() => mockDataSource.logout()).thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockDataSource.logout()).called(1);
    });
  });

  group('authStateChanges', () {
    test('converts UserModel to UserEntity', () async {
      final streamController = StreamController<UserModel?>();

      when(() => mockDataSource.authStateChanges())
          .thenAnswer((_) => streamController.stream);

      final results = <UserEntity?>[];
      repository.authStateChanges().listen(results.add);

      streamController.add(
        const UserModel(id: 'uid-3', email: 'c@d.com'),
      );
      streamController.add(null);
      await streamController.close();

      expect(results, hasLength(2));
      expect(results[0], isA<UserEntity>());
      expect(results[0]!.id, 'uid-3');
      expect(results[0]!.email, 'c@d.com');
      expect(results[1], isNull);
    });
  });
}

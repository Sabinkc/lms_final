import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/auth/data/models/app_user.dart';
import 'package:cloud_lms/features/auth/data/models/auth_session.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository.dart';
import 'package:cloud_lms/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _session = AuthSession(
  user: AppUser(id: '1', fullName: 'Ada', email: 'ada@test.com', role: AppRole.teacher),
  accessToken: 'access',
  refreshToken: 'refresh',
);

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    // Every provider constructor call triggers restoreSession() — stub it
    // for every test so setup doesn't throw before the real assertions run.
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
  });

  test('starts unauthenticated once restoreSession() resolves with no session', () async {
    final provider = AuthProvider(repository);
    await Future<void>.delayed(Duration.zero);

    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.user, isNull);
  });

  test('login() success sets status to authenticated and exposes the user', () async {
    when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Result.success(_session));

    final provider = AuthProvider(repository);
    await Future<void>.delayed(Duration.zero);

    await provider.login(email: 'ada@test.com', password: 'secret');

    expect(provider.status, AuthStatus.authenticated);
    expect(provider.role, AppRole.teacher);
    expect(provider.isSubmitting, isFalse);
  });

  test('login() failure surfaces the AppException without authenticating', () async {
    when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Result.failure(ValidationException('bad creds')));

    final provider = AuthProvider(repository);
    await Future<void>.delayed(Duration.zero);

    await provider.login(email: 'ada@test.com', password: 'wrong');

    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.lastError, isA<ValidationException>());
  });

  test('logout() clears the session', () async {
    when(() => repository.login(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async => const Result.success(_session));
    when(() => repository.logout(any())).thenAnswer((_) async => const Result.success(null));

    final provider = AuthProvider(repository);
    await Future<void>.delayed(Duration.zero);
    await provider.login(email: 'ada@test.com', password: 'secret');
    expect(provider.status, AuthStatus.authenticated);

    await provider.logout();

    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.user, isNull);
  });
}

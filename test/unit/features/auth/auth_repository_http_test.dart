import 'dart:convert';

import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/local_prefs_service.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/auth/data/repositories/auth_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

class _MockLocalPrefsService extends Mock implements LocalPrefsService {}

const _loginSuccessBody = {
  'success': true,
  'token': 'access-token-1',
  'refreshToken': 'refresh-token-1',
  'role': 'admin',
  'data': {'_id': 'admin-1', 'fullName': 'Demo Admin', 'email': 'admin@greenwood-demo.test', 'role': 'admin'},
};

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late _MockSecureStorageService secureStorage;
  late _MockLocalPrefsService localPrefs;
  late AuthRepositoryHttp repository;

  setUp(() {
    fakeAdapter = FakeHttpClientAdapter();
    secureStorage = _MockSecureStorageService();
    localPrefs = _MockLocalPrefsService();

    when(() => secureStorage.readAccessToken()).thenAnswer((_) async => null);
    when(() => secureStorage.readRefreshToken()).thenAnswer((_) async => null);
    when(() => secureStorage.saveTokens(accessToken: any(named: 'accessToken'), refreshToken: any(named: 'refreshToken')))
        .thenAnswer((_) async {});
    when(() => secureStorage.clearTokens()).thenAnswer((_) async {});
    when(() => localPrefs.setCachedUserJson(any())).thenAnswer((_) async {});
    when(() => localPrefs.clearCachedUser()).thenAnswer((_) async {});
    when(() => localPrefs.cachedUserJson).thenReturn(null);

    final dio = Dio()..httpClientAdapter = fakeAdapter;
    final apiClient = ApiClient(
      env: const EnvConfig(environment: AppEnvironment.dev, baseUrl: 'http://test.local', verboseLogging: false),
      secureStorage: secureStorage,
      dio: dio,
    );

    repository = AuthRepositoryHttp(apiClient, secureStorage, localPrefs);
  });

  group('login()', () {
    test('success: parses the session and persists tokens + cached user', () async {
      fakeAdapter.when(
        '/auth/login',
        (_) => jsonResponseBody(_loginSuccessBody, 200));

      final result = await repository.login(email: 'admin@greenwood-demo.test', password: 'Admin@123');

      expect(result.isSuccess, isTrue);
      result.when(
        success: (session) {
          expect(session.accessToken, 'access-token-1');
          expect(session.refreshToken, 'refresh-token-1');
          expect(session.user.email, 'admin@greenwood-demo.test');
        },
        failure: (_) => fail('expected success'),
      );

      verify(() => secureStorage.saveTokens(accessToken: 'access-token-1', refreshToken: 'refresh-token-1')).called(1);
      verify(() => localPrefs.setCachedUserJson(any())).called(1);
    });

    test('failure: bare {message} envelope (confirmed real shape, no "success"/"errors" keys) maps to '
        'a ValidationException and persists nothing', () async {
      fakeAdapter.when(
        '/auth/login',
        (_) => jsonResponseBody({'message': 'Invalid credentials'}, 400));

      final result = await repository.login(email: 'admin@greenwood-demo.test', password: 'wrong');

      expect(result.isFailure, isTrue);
      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) {
          expect(error, isA<ValidationException>());
          expect(error.message, 'Invalid credentials');
        },
      );

      verifyNever(() => secureStorage.saveTokens(
          accessToken: any(named: 'accessToken'), refreshToken: any(named: 'refreshToken')));
      verifyNever(() => localPrefs.setCachedUserJson(any()));
    });

    test('failure: 403 SUBSCRIPTION_INACTIVE-style envelope maps to ForbiddenException with its code', () async {
      fakeAdapter.when(
        '/auth/login',
        (_) => jsonResponseBody({'message': 'Subscription inactive', 'code': 'SUBSCRIPTION_INACTIVE'}, 403),
      );

      final result = await repository.login(email: 'admin@greenwood-demo.test', password: 'Admin@123');

      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) {
          expect(error, isA<ForbiddenException>());
          expect(error.code, 'SUBSCRIPTION_INACTIVE');
        },
      );
    });
  });

  group('refreshToken()', () {
    test('success: parses the new session and re-persists tokens + cached user', () async {
      fakeAdapter.when(
        '/auth/refresh',
        (_) => jsonResponseBody({
          ..._loginSuccessBody,
          'token': 'access-token-2',
          'refreshToken': 'refresh-token-2',
        }, 200),
      );

      final result = await repository.refreshToken('refresh-token-1');

      result.when(
        success: (session) => expect(session.accessToken, 'access-token-2'),
        failure: (_) => fail('expected success'),
      );
      verify(() => secureStorage.saveTokens(accessToken: 'access-token-2', refreshToken: 'refresh-token-2'))
          .called(1);
    });

    test('failure: expired/invalid refresh token maps to UnauthorizedException', () async {
      fakeAdapter.when(
        '/auth/refresh',
        (_) => jsonResponseBody({'message': 'Invalid refresh token', 'code': 'TOKEN_INVALID'}, 401),
      );

      final result = await repository.refreshToken('stale-token');

      result.when(
        success: (_) => fail('expected failure'),
        failure: (error) {
          expect(error, isA<UnauthorizedException>());
          expect(error.code, 'TOKEN_INVALID');
        },
      );
    });
  });

  group('logout()', () {
    test('success: clears the local session', () async {
      fakeAdapter.when(
        '/auth/logout',
        (_) => jsonResponseBody({'success': true, 'message': 'Logged out'}, 200));

      final result = await repository.logout('refresh-token-1');

      expect(result.isSuccess, isTrue);
      verify(() => secureStorage.clearTokens()).called(1);
      verify(() => localPrefs.clearCachedUser()).called(1);
    });

    test('failure: still clears the local session even though the backend call failed '
        '(best-effort — never strand the device logged in)', () async {
      fakeAdapter.when(
        '/auth/logout',
        (_) => jsonResponseBody({'message': 'Server error'}, 500));

      final result = await repository.logout('refresh-token-1');

      expect(result.isFailure, isTrue);
      verify(() => secureStorage.clearTokens()).called(1);
      verify(() => localPrefs.clearCachedUser()).called(1);
    });
  });

  group('restoreSession()', () {
    test('returns null when no tokens are stored', () async {
      when(() => secureStorage.readAccessToken()).thenAnswer((_) async => null);
      when(() => secureStorage.readRefreshToken()).thenAnswer((_) async => null);

      expect(await repository.restoreSession(), isNull);
    });

    test('reconstructs the session from stored tokens + cached user JSON', () async {
      when(() => secureStorage.readAccessToken()).thenAnswer((_) async => 'access-token-1');
      when(() => secureStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token-1');
      when(() => localPrefs.cachedUserJson).thenReturn(
        jsonEncode({'id': 'admin-1', 'fullName': 'Demo Admin', 'email': 'admin@greenwood-demo.test', 'role': 'admin'}),
      );

      final session = await repository.restoreSession();

      expect(session, isNotNull);
      expect(session!.accessToken, 'access-token-1');
      expect(session.user.email, 'admin@greenwood-demo.test');
    });

    test('tokens present but no cached user: drops the orphaned tokens and returns null', () async {
      when(() => secureStorage.readAccessToken()).thenAnswer((_) async => 'access-token-1');
      when(() => secureStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token-1');
      when(() => localPrefs.cachedUserJson).thenReturn(null);

      final session = await repository.restoreSession();

      expect(session, isNull);
      verify(() => secureStorage.clearTokens()).called(1);
    });
  });
}

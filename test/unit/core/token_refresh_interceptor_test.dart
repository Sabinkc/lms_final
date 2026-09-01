import 'package:cloud_lms/core/network/interceptors/token_refresh_interceptor.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late _MockSecureStorageService secureStorage;
  late Dio dio;

  setUp(() {
    fakeAdapter = FakeHttpClientAdapter();
    secureStorage = _MockSecureStorageService();

    when(() => secureStorage.readRefreshToken()).thenAnswer((_) async => 'stale-refresh-token');
    when(() => secureStorage.saveTokens(accessToken: any(named: 'accessToken'), refreshToken: any(named: 'refreshToken')))
        .thenAnswer((_) async {});
    when(() => secureStorage.clearTokens()).thenAnswer((_) async {});

    dio = Dio(BaseOptions(baseUrl: 'http://test.local'))..httpClientAdapter = fakeAdapter;
    dio.interceptors.add(TokenRefreshInterceptor(dio: dio, secureStorage: secureStorage));
  });

  test('retries a TOKEN_EXPIRED 401 with the refreshed access token and resolves transparently', () async {
    fakeAdapter.when('/students/me', (callNumber) {
      if (callNumber == 1) return jsonResponseBody({'message': 'Token expired', 'code': 'TOKEN_EXPIRED'}, 401);
      return jsonResponseBody({'success': true, 'data': {'fullName': 'Sam Student'}}, 200);
    });
    fakeAdapter.when(
      '/auth/refresh',
      (_) => jsonResponseBody({'token': 'fresh-access-token', 'refreshToken': 'fresh-refresh-token'}, 200),
    );

    final response = await dio.get<Map<String, dynamic>>('/students/me');

    expect(response.statusCode, 200);
    expect(fakeAdapter.callCounts['/students/me'], 2);
    expect(fakeAdapter.callCounts['/auth/refresh'], 1);
    verify(() => secureStorage.saveTokens(accessToken: 'fresh-access-token', refreshToken: 'fresh-refresh-token'))
        .called(1);
  });

  test('single-flight: N concurrent TOKEN_EXPIRED 401s trigger exactly one /auth/refresh call', () async {
    fakeAdapter.when('/students/me', (callNumber) {
      if (callNumber <= 3) return jsonResponseBody({'message': 'Token expired', 'code': 'TOKEN_EXPIRED'}, 401);
      return jsonResponseBody({'success': true, 'data': {}}, 200);
    });
    fakeAdapter.when(
      '/auth/refresh',
      (_) => jsonResponseBody({'token': 'fresh-access-token', 'refreshToken': 'fresh-refresh-token'}, 200),
    );

    final responses = await Future.wait([
      dio.get<Map<String, dynamic>>('/students/me'),
      dio.get<Map<String, dynamic>>('/students/me'),
      dio.get<Map<String, dynamic>>('/students/me'),
    ]);

    expect(responses.every((r) => r.statusCode == 200), isTrue);
    expect(fakeAdapter.callCounts['/auth/refresh'], 1);
  });

  test('a 401 without TOKEN_EXPIRED (protectAdmin-style, no code at all) is not retried', () async {
    fakeAdapter.when('/admin/students', (_) => jsonResponseBody({'message': 'Not authorized'}, 401));

    await expectLater(
      dio.get<Map<String, dynamic>>('/admin/students'),
      throwsA(isA<DioException>()),
    );

    expect(fakeAdapter.callCounts['/admin/students'], 1);
    expect(fakeAdapter.callCounts['/auth/refresh'], isNull);
  });

  test('a dead refresh token clears local tokens and propagates the original 401', () async {
    fakeAdapter.when('/students/me', (_) => jsonResponseBody({'message': 'Token expired', 'code': 'TOKEN_EXPIRED'}, 401));
    fakeAdapter.when(
      '/auth/refresh',
      (_) => jsonResponseBody({'message': 'Invalid refresh token', 'code': 'TOKEN_INVALID'}, 401),
    );

    await expectLater(
      dio.get<Map<String, dynamic>>('/students/me'),
      throwsA(isA<DioException>()),
    );

    verify(() => secureStorage.clearTokens()).called(1);
  });
}

import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/id_cards/data/repositories/id_card_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late IdCardRepositoryHttp repository;

  setUp(() {
    fakeAdapter = FakeHttpClientAdapter();
    final secureStorage = _MockSecureStorageService();
    when(() => secureStorage.readAccessToken()).thenAnswer((_) async => 'access-token');

    final dio = Dio()..httpClientAdapter = fakeAdapter;
    final apiClient = ApiClient(
      env: const EnvConfig(environment: AppEnvironment.dev, baseUrl: 'http://test.local', verboseLogging: false),
      secureStorage: secureStorage,
      dio: dio,
    );

    repository = IdCardRepositoryHttp(apiClient);
  });

  test('generateStudentIdCard(): returns the raw PDF bytes', () async {
    fakeAdapter.when('/id-cards/student/s1', (_) => bytesResponseBody([37, 80, 68, 70], 200));

    final result = await repository.generateStudentIdCard('s1');

    result.when(
      success: (bytes) => expect(bytes, [37, 80, 68, 70]),
      failure: (_) => fail('expected success'),
    );
  });

  test('generateStudentIdCard(): a 404 fails, though the backend\'s custom message is unreadable here — '
      "`ResponseType.bytes` means Dio never JSON-decodes the error body, so `ErrorMapper` falls back to its "
      'generic 404 default rather than the controller\'s actual "Student not found for this school" text; same '
      'limitation applies to every other bytes-typed export/download method in this app', () async {
    fakeAdapter.when('/id-cards/student/s1', (_) => jsonResponseBody({'message': 'Student not found for this school'}, 404));

    final result = await repository.generateStudentIdCard('s1');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, 'Not found.'),
    );
  });

  test('generateMyIdCard(): returns the raw PDF bytes', () async {
    fakeAdapter.when('/id-cards/my', (_) => bytesResponseBody([37, 80, 68, 70], 200));

    final result = await repository.generateMyIdCard();

    result.when(
      success: (bytes) => expect(bytes, [37, 80, 68, 70]),
      failure: (_) => fail('expected success'),
    );
  });

  test('generateMyIdCard(): a 404 fails with the generic default message, same bytes-response limitation as above', () async {
    fakeAdapter.when('/id-cards/my', (_) => jsonResponseBody({'message': 'Student profile not found'}, 404));

    final result = await repository.generateMyIdCard();

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, 'Not found.'),
    );
  });
}

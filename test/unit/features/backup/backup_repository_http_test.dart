import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/backup/data/repositories/backup_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late BackupRepositoryHttp repository;

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

    repository = BackupRepositoryHttp(apiClient);
  });

  test('downloadSchoolBackup(): returns the raw zip bytes', () async {
    fakeAdapter.when('/backup/school', (_) => bytesResponseBody([80, 75, 3, 4], 200));

    final result = await repository.downloadSchoolBackup();

    result.when(
      success: (bytes) => expect(bytes, [80, 75, 3, 4]),
      failure: (_) => fail('expected success'),
    );
  });

  test('downloadSchoolBackup(): surfaces a server failure', () async {
    fakeAdapter.when(
      '/backup/school',
      (_) => jsonResponseBody({'message': 'Backup failed'}, 500),
    );

    final result = await repository.downloadSchoolBackup();

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, isNotEmpty),
    );
  });
}

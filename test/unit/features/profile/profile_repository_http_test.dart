import 'dart:typed_data';

import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/profile/data/repositories/profile_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late ProfileRepositoryHttp repository;

  setUp(() {
    fakeAdapter = FakeHttpClientAdapter();
    final secureStorage = _MockSecureStorageService();
    when(() => secureStorage.readAccessToken()).thenAnswer((_) async => 'access-token');
    final dio = Dio()..httpClientAdapter = fakeAdapter;
    repository = ProfileRepositoryHttp(
      ApiClient(
        env: const EnvConfig(environment: AppEnvironment.dev, baseUrl: 'http://test.local', verboseLogging: false),
        secureStorage: secureStorage,
        dio: dio,
      ),
    );
  });

  ResponseBody ok(Map<String, dynamic> data) => jsonResponseBody({'success': true, 'data': data}, 200);
  final someone = {'_id': 'x1', 'fullName': 'Someone', 'email': 's@x.com'};

  group('each role reads, edits and changes password on its own endpoint', () {
    final cases = {
      AppRole.admin: ('/admin/profile', '/admin/profile', '/admin/change-password'),
      AppRole.teacher: ('/teachers/me', '/teachers/update-profile', '/teachers/change-password'),
      AppRole.student: ('/students/me', '/students/me', '/students/me/password'),
      AppRole.parent: ('/parents/me', '/parents/me', '/parents/me/password'),
    };
    for (final MapEntry(key: role, value: (get, update, password)) in cases.entries) {
      test(role.name, () async {
        fakeAdapter.when(get, (_) => ok(someone));
        if (update != get) fakeAdapter.when(update, (_) => ok(someone));
        fakeAdapter.when(password, (_) => jsonResponseBody({'success': true}, 200));

        expect((await repository.getMyProfile(role)).dataOrNull?.fullName, 'Someone');
        expect((await repository.updateMyProfile(role, fullName: 'New')).isSuccess, isTrue);
        expect(
          (await repository.changePassword(role, currentPassword: 'old-pass', newPassword: 'new-pass-1')).isSuccess,
          isTrue,
        );
      });
    }
  });

  test('wrong current password: the server message is shown, not "session expired"', () async {
    fakeAdapter.when(
      '/students/me/password',
      (_) => jsonResponseBody({'success': false, 'message': 'Current password is incorrect'}, 401),
    );
    final result = await repository.changePassword(AppRole.student, currentPassword: 'a', newPassword: 'bbbbbb');
    expect(result.when(success: (_) => null, failure: (e) => e.message), 'Current password is incorrect');
  });

  test('photo: self-upload for teacher/student, by-id upload for admin', () async {
    fakeAdapter.when(
      '/upload/my-photo',
      (_) => jsonResponseBody({'success': true, 'photoUrl': 'https://img/t.jpg'}, 200),
    );
    fakeAdapter.when(
      '/upload/photo/admin/a1',
      (_) => jsonResponseBody({'success': true, 'photoUrl': 'https://img/a.jpg'}, 200),
    );
    final bytes = Uint8List.fromList([1, 2, 3]);

    final teacher = await repository.uploadMyPhoto(AppRole.teacher, profileId: 't1', bytes: bytes, filename: 'p.jpg');
    final admin = await repository.uploadMyPhoto(AppRole.admin, profileId: 'a1', bytes: bytes, filename: 'p.jpg');

    expect(teacher.dataOrNull, 'https://img/t.jpg');
    expect(admin.dataOrNull, 'https://img/a.jpg');
  });

  test('school: read and upload the logo', () async {
    final school = {'_id': 's1', 'name': 'Cloud Test Academy', 'logo': 'https://img/logo.png'};
    fakeAdapter.when('/schools/me', (_) => ok({...school, 'logo': ''}));
    fakeAdapter.when('/schools/me/branding', (_) => ok(school));

    expect((await repository.getMySchool()).dataOrNull?.logoUrl, isNull);
    final uploaded = await repository.uploadSchoolLogo(bytes: Uint8List.fromList([1]), filename: 'logo.png');
    expect(uploaded.dataOrNull?.logoUrl, 'https://img/logo.png');
  });
}

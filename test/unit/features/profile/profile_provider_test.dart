import 'dart:typed_data';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/auth/data/models/app_role.dart';
import 'package:cloud_lms/features/profile/data/models/my_profile.dart';
import 'package:cloud_lms/features/profile/data/repositories/profile_repository.dart';
import 'package:cloud_lms/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late _MockProfileRepository repository;
  late ProfileProvider provider;

  const amy = MyProfile(role: AppRole.student, id: 's1', fullName: 'Amy', email: 'amy@x.com');
  const amyRenamed = MyProfile(role: AppRole.student, id: 's1', fullName: 'Amy B', email: 'amy@x.com');

  setUpAll(() {
    registerFallbackValue(AppRole.student);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = _MockProfileRepository();
    provider = ProfileProvider(repository);
  });

  test('load(): success stores the profile', () async {
    when(() => repository.getMyProfile(AppRole.student)).thenAnswer((_) async => const Result.success(amy));
    await provider.load(AppRole.student);
    expect(provider.status, LoadStatus.success);
    expect(provider.profile?.fullName, 'Amy');
  });

  test('load(): a fresh load clears the previous login\'s profile first', () async {
    when(() => repository.getMyProfile(AppRole.student)).thenAnswer((_) async => const Result.success(amy));
    await provider.load(AppRole.student);

    when(
      () => repository.getMyProfile(AppRole.teacher),
    ).thenAnswer((_) async => const Result.failure(ServerException('down')));
    final pending = provider.load(AppRole.teacher);
    expect(provider.profile, isNull);
    await pending;
    expect(provider.status, LoadStatus.error);
  });

  test('updateDetails(): reloads from the server on success', () async {
    when(() => repository.getMyProfile(AppRole.student)).thenAnswer((_) async => const Result.success(amy));
    await provider.load(AppRole.student);
    when(
      () => repository.updateMyProfile(
        AppRole.student,
        fullName: any(named: 'fullName'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        address: any(named: 'address'),
        dob: any(named: 'dob'),
        occupation: any(named: 'occupation'),
      ),
    ).thenAnswer((_) async => const Result.success(null));
    when(() => repository.getMyProfile(AppRole.student)).thenAnswer((_) async => const Result.success(amyRenamed));

    final error = await provider.updateDetails(fullName: 'Amy B');

    expect(error, isNull);
    expect(provider.profile?.fullName, 'Amy B');
  });

  test('changePassword(): returns the server error', () async {
    when(() => repository.getMyProfile(AppRole.student)).thenAnswer((_) async => const Result.success(amy));
    await provider.load(AppRole.student);
    when(
      () => repository.changePassword(
        AppRole.student,
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async => const Result.failure(UnauthorizedException('Current password is incorrect')));

    final error = await provider.changePassword(currentPassword: 'x', newPassword: 'yyyyyy');

    expect(error?.message, 'Current password is incorrect');
  });

  test('uploadPhoto(): passes the profile id and reloads', () async {
    when(() => repository.getMyProfile(AppRole.student)).thenAnswer((_) async => const Result.success(amy));
    await provider.load(AppRole.student);
    when(
      () => repository.uploadMyPhoto(
        AppRole.student,
        profileId: 's1',
        bytes: any(named: 'bytes'),
        filename: 'me.jpg',
      ),
    ).thenAnswer((_) async => const Result.success('https://img/me.jpg'));

    final error = await provider.uploadPhoto(Uint8List.fromList([1]), 'me.jpg');

    expect(error, isNull);
    verify(() => repository.getMyProfile(AppRole.student)).called(2);
  });
}

import 'dart:typed_data';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/student_followups/data/models/student_followup.dart';
import 'package:cloud_lms/features/student_followups/data/repositories/student_followup_repository.dart';
import 'package:cloud_lms/features/student_followups/presentation/providers/student_followup_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStudentFollowupRepository extends Mock implements StudentFollowupRepository {}

const _followup1 = StudentFollowup(
  id: 'f1',
  studentName: 'Sam Prospect',
  faculty: 'Science',
  email: 'sam@test.dev',
  contactNumber: '9800000000',
  address: 'Kathmandu',
  followUpNote: 'Interested in Class 10 admission',
  visitDate: '2026-08-20T00:00:00.000Z',
  status: 'pending',
  createdByName: 'Alice Admin',
);

void main() {
  late _MockStudentFollowupRepository repository;
  late StudentFollowupProvider provider;

  setUp(() {
    repository = _MockStudentFollowupRepository();
    provider = StudentFollowupProvider(repository);
  });

  test('loadFollowups(): success populates the list and sets status', () async {
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([_followup1]));

    await provider.loadFollowups();

    expect(provider.status, LoadStatus.success);
    expect(provider.followups, [_followup1]);
  });

  test('loadFollowups(): failure sets error status', () async {
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadFollowups();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });

  test('createFollowup(): success prepends to the list and returns true', () async {
    when(
      () => repository.createFollowup(
        studentName: any(named: 'studentName'),
        faculty: any(named: 'faculty'),
        email: any(named: 'email'),
        contactNumber: any(named: 'contactNumber'),
        address: any(named: 'address'),
        followUpNote: any(named: 'followUpNote'),
        visitDate: any(named: 'visitDate'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => const Result.success(_followup1));

    final succeeded = await provider.createFollowup(
      studentName: 'Sam Prospect',
      faculty: 'Science',
      email: 'sam@test.dev',
      contactNumber: '9800000000',
      address: 'Kathmandu',
      followUpNote: 'Interested in Class 10 admission',
    );

    expect(succeeded, isTrue);
    expect(provider.followups, [_followup1]);
    expect(provider.isSaving, isFalse);
  });

  test('createFollowup(): failure returns false and exposes the action error', () async {
    when(
      () => repository.createFollowup(
        studentName: any(named: 'studentName'),
        faculty: any(named: 'faculty'),
        email: any(named: 'email'),
        contactNumber: any(named: 'contactNumber'),
        address: any(named: 'address'),
        followUpNote: any(named: 'followUpNote'),
        visitDate: any(named: 'visitDate'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => const Result.failure(ValidationException('studentName is required')));

    final succeeded = await provider.createFollowup(
      studentName: '',
      faculty: '',
      email: '',
      contactNumber: '',
      address: '',
      followUpNote: '',
    );

    expect(succeeded, isFalse);
    expect(provider.followups, isEmpty);
    expect(provider.actionError, isA<ValidationException>());
  });

  test('updateFollowup(): success replaces the matching record in the list', () async {
    const resolved = StudentFollowup(
      id: 'f1',
      studentName: 'Sam Prospect',
      faculty: 'Science',
      email: 'sam@test.dev',
      contactNumber: '9800000000',
      address: 'Kathmandu',
      followUpNote: 'Interested in Class 10 admission',
      visitDate: '2026-08-20T00:00:00.000Z',
      status: 'resolved',
      createdByName: 'Alice Admin',
    );
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([_followup1]));
    await provider.loadFollowups();

    when(
      () => repository.updateFollowup(
        id: any(named: 'id'),
        studentName: any(named: 'studentName'),
        faculty: any(named: 'faculty'),
        email: any(named: 'email'),
        contactNumber: any(named: 'contactNumber'),
        address: any(named: 'address'),
        followUpNote: any(named: 'followUpNote'),
        visitDate: any(named: 'visitDate'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => const Result.success(resolved));

    final succeeded = await provider.updateFollowup(id: 'f1', status: 'resolved');

    expect(succeeded, isTrue);
    expect(provider.followups.single.status, 'resolved');
  });

  test('deleteFollowup(): success removes the record from the list', () async {
    when(() => repository.getFollowups(status: any(named: 'status'), search: any(named: 'search'), limit: any(named: 'limit')))
        .thenAnswer((_) async => const Result.success([_followup1]));
    await provider.loadFollowups();

    when(() => repository.deleteFollowup('f1')).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteFollowup('f1');

    expect(succeeded, isTrue);
    expect(provider.followups, isEmpty);
  });

  test('exportFollowups(): success returns the bytes', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => repository.exportFollowups(status: any(named: 'status'), search: any(named: 'search')))
        .thenAnswer((_) async => Result.success(bytes));

    final result = await provider.exportFollowups();

    expect(result, bytes);
    expect(provider.downloadError, isNull);
  });

  test('exportFollowups(): failure surfaces the error and returns null', () async {
    when(() => repository.exportFollowups(status: any(named: 'status'), search: any(named: 'search')))
        .thenAnswer((_) async => const Result.failure(ServerException('Export failed')));

    final result = await provider.exportFollowups();

    expect(result, isNull);
    expect(provider.downloadError?.message, contains('Export failed'));
  });
}

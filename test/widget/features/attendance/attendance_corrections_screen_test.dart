import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/attendance/data/models/attendance_correction.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_correction_repository.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/admin_attendance_provider.dart';
import 'package:cloud_lms/features/attendance/presentation/screens/attendance_corrections_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

class _MockAttendanceCorrectionRepository extends Mock implements AttendanceCorrectionRepository {}

const _correction1 = AttendanceCorrection(
  id: 'corr1',
  targetType: 'StudentAttendance',
  attendanceSessionId: 'sess1',
  studentId: 's1',
  oldStatus: 'absent',
  newStatus: 'present',
  reason: 'Marked by mistake',
  status: 'pending',
  requestedById: 'u1',
  reviewNote: null,
);

Widget _wrap(AdminAttendanceProvider provider) => ChangeNotifierProvider<AdminAttendanceProvider>.value(
      value: provider,
      child: const MaterialApp(home: AttendanceCorrectionsScreen()),
    );

void main() {
  late _MockAttendanceRepository attendanceRepository;
  late _MockAttendanceCorrectionRepository correctionRepository;

  setUp(() {
    attendanceRepository = _MockAttendanceRepository();
    correctionRepository = _MockAttendanceCorrectionRepository();
  });

  testWidgets('loading state shows LoadingView', (tester) async {
    when(() => correctionRepository.getCorrections(status: any(named: 'status')))
        .thenAnswer((_) => Completer<Result<List<AttendanceCorrection>>>().future);
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty state shows the CTA', (tester) async {
    when(() => correctionRepository.getCorrections(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success([]));
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No pending correction requests'), findsOneWidget);
  });

  testWidgets('error state shows ErrorView with a working retry', (tester) async {
    var callCount = 0;
    when(() => correctionRepository.getCorrections(status: any(named: 'status'))).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? const Result.failure(NetworkException()) : const Result.success([_correction1]);
    });
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Network error. Please check your connection.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.textContaining('StudentAttendance'), findsOneWidget);
  });

  testWidgets('success state shows the request and approving it removes it from the queue', (tester) async {
    when(() => correctionRepository.getCorrections(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success([_correction1]));
    when(() => correctionRepository.approve(any(), reviewNote: any(named: 'reviewNote')))
        .thenAnswer((_) async => const Result.success(_correction1));
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.textContaining('absent → present'), findsOneWidget);
    expect(find.text('Reason: Marked by mistake'), findsOneWidget);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    verify(() => correctionRepository.approve('corr1', reviewNote: any(named: 'reviewNote'))).called(1);
    expect(find.text('No pending correction requests'), findsOneWidget);
  });

  testWidgets('rejecting surfaces a snackbar on failure and keeps the request in the queue', (tester) async {
    when(() => correctionRepository.getCorrections(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success([_correction1]));
    when(() => correctionRepository.reject(any(), reviewNote: any(named: 'reviewNote')))
        .thenAnswer((_) async => const Result.failure(ServerException('This request was already approved')));
    final provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(find.text('This request was already approved'), findsOneWidget);
    expect(find.textContaining('absent → present'), findsOneWidget);
  });
}

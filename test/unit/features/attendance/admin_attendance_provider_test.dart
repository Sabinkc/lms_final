import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/attendance/data/models/attendance_correction.dart';
import 'package:cloud_lms/features/attendance/data/models/attendance_session.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_correction_repository.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/admin_attendance_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

class _MockAttendanceCorrectionRepository extends Mock implements AttendanceCorrectionRepository {}

const _session1 = AttendanceSessionSummary(
  id: 'sess1',
  className: 'Class 10',
  section: 'A',
  subject: 'General',
  date: '2026-08-23',
  presentCount: 8,
  absentCount: 1,
  lateCount: 1,
  totalCount: 10,
  locked: true,
);

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

void main() {
  late _MockAttendanceRepository attendanceRepository;
  late _MockAttendanceCorrectionRepository correctionRepository;
  late AdminAttendanceProvider provider;

  setUp(() {
    attendanceRepository = _MockAttendanceRepository();
    correctionRepository = _MockAttendanceCorrectionRepository();
    provider = AdminAttendanceProvider(attendanceRepository, correctionRepository);
  });

  test('loadOverview(): success populates overviewSessions (school-wide, no teacher scoping client-side)', () async {
    when(() => attendanceRepository.getSessions(
          date: any(named: 'date'),
          className: any(named: 'className'),
          section: any(named: 'section'),
        )).thenAnswer((_) async => const Result.success([_session1]));

    await provider.loadOverview(date: '2026-08-23');

    expect(provider.overviewStatus, LoadStatus.success);
    expect(provider.overviewSessions, [_session1]);
  });

  test('loadOverview(): failure sets error status', () async {
    when(() => attendanceRepository.getSessions(
          date: any(named: 'date'),
          className: any(named: 'className'),
          section: any(named: 'section'),
        )).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadOverview(date: '2026-08-23');

    expect(provider.overviewStatus, LoadStatus.error);
    expect(provider.overviewError, isA<NetworkException>());
  });

  test('loadCorrections(): success populates corrections, defaulting to the pending queue', () async {
    when(() => correctionRepository.getCorrections(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success([_correction1]));

    await provider.loadCorrections();

    expect(provider.correctionsStatus, LoadStatus.success);
    expect(provider.corrections, [_correction1]);
    verify(() => correctionRepository.getCorrections(status: 'pending')).called(1);
  });

  test('approveCorrection(): success removes it from the queue and returns true', () async {
    when(() => correctionRepository.getCorrections(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success([_correction1]));
    await provider.loadCorrections();
    when(() => correctionRepository.approve(any(), reviewNote: any(named: 'reviewNote')))
        .thenAnswer((_) async => const Result.success(_correction1));

    final succeeded = await provider.approveCorrection('corr1');

    expect(succeeded, isTrue);
    expect(provider.corrections, isEmpty);
  });

  test('rejectCorrection(): failure leaves the queue untouched and surfaces the action error', () async {
    when(() => correctionRepository.getCorrections(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success([_correction1]));
    await provider.loadCorrections();
    when(() => correctionRepository.reject(any(), reviewNote: any(named: 'reviewNote')))
        .thenAnswer((_) async => const Result.failure(ServerException('This request was already approved')));

    final succeeded = await provider.rejectCorrection('corr1');

    expect(succeeded, isFalse);
    expect(provider.corrections, [_correction1]);
    expect(provider.correctionActionError?.message, contains('already approved'));
  });
}

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/attendance/data/models/attendance_session.dart';
import 'package:cloud_lms/features/attendance/data/models/attendance_status.dart';
import 'package:cloud_lms/features/attendance/data/models/attendance_submit_result.dart';
import 'package:cloud_lms/features/attendance/data/models/teacher_section.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

const _section1 = TeacherSection(id: 'sec1', name: 'A', classId: 'c1', className: 'Class 10');

const _student1 = Student(
  id: 's1',
  fullName: 'Sam Student',
  email: 'sam@school.test',
  admissionNumber: 'ADM001',
  rollNumber: '1',
  className: 'Class 10',
  section: 'A',
  parentId: null,
  dob: '',
  address: '',
  phone: '',
  status: 'active',
);

void main() {
  late _MockAttendanceRepository repository;
  late AttendanceProvider provider;

  setUpAll(() {
    registerFallbackValue(<AttendanceRecordInput>[]);
  });

  setUp(() {
    repository = _MockAttendanceRepository();
    provider = AttendanceProvider(repository);
  });

  test('loadMySections(): success populates sections and sets status', () async {
    when(() => repository.getMySections()).thenAnswer((_) async => const Result.success([_section1]));

    await provider.loadMySections();

    expect(provider.sectionsStatus, LoadStatus.success);
    expect(provider.sections, [_section1]);
  });

  test('loadRoster(): success populates roster and defaults every student to present', () async {
    when(() => repository.getSectionRoster(any())).thenAnswer((_) async => const Result.success([_student1]));

    await provider.loadRoster('sec1');

    expect(provider.rosterStatus, LoadStatus.success);
    expect(provider.roster, [_student1]);
    expect(provider.statusFor('s1'), AttendanceStatus.present);
  });

  test('setStatus(): overrides a student\'s status away from the present default', () async {
    when(() => repository.getSectionRoster(any())).thenAnswer((_) async => const Result.success([_student1]));
    await provider.loadRoster('sec1');

    provider.setStatus('s1', AttendanceStatus.absent);

    expect(provider.statusFor('s1'), AttendanceStatus.absent);
  });

  test('submit(): success stores the result and reflects every roster student\'s current status', () async {
    when(() => repository.getSectionRoster(any())).thenAnswer((_) async => const Result.success([_student1]));
    await provider.loadRoster('sec1');
    provider.setStatus('s1', AttendanceStatus.absent);

    when(() => repository.markAttendance(
          sectionId: any(named: 'sectionId'),
          date: any(named: 'date'),
          subject: any(named: 'subject'),
          records: any(named: 'records'),
        )).thenAnswer((_) async => const Result.success(AttendanceSubmitResult(savedCount: 1, failed: [])));

    final succeeded = await provider.submit(sectionId: 'sec1', date: '2026-08-23');

    expect(succeeded, isTrue);
    expect(provider.lastSubmitResult?.savedCount, 1);
    final captured = verify(() => repository.markAttendance(
          sectionId: 'sec1',
          date: '2026-08-23',
          subject: any(named: 'subject'),
          records: captureAny(named: 'records'),
        )).captured;
    final records = captured.single as List<AttendanceRecordInput>;
    expect(records.single.studentId, 's1');
    expect(records.single.status, AttendanceStatus.absent);
  });

  test('submit(): failure (e.g. already submitted) surfaces the error without touching lastSubmitResult', () async {
    when(() => repository.getSectionRoster(any())).thenAnswer((_) async => const Result.success([_student1]));
    await provider.loadRoster('sec1');
    when(() => repository.markAttendance(
          sectionId: any(named: 'sectionId'),
          date: any(named: 'date'),
          subject: any(named: 'subject'),
          records: any(named: 'records'),
        )).thenAnswer((_) async => const Result.failure(ServerException('Attendance has already been submitted.')));

    final succeeded = await provider.submit(sectionId: 'sec1', date: '2026-08-23');

    expect(succeeded, isFalse);
    expect(provider.submitError?.message, contains('already been submitted'));
    expect(provider.lastSubmitResult, isNull);
  });

  test('loadHistory(): success populates historySessions for the given date', () async {
    const session = AttendanceSessionSummary(
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
    when(() => repository.getSessions(date: any(named: 'date')))
        .thenAnswer((_) async => const Result.success([session]));

    await provider.loadHistory('2026-08-23');

    expect(provider.historyStatus, LoadStatus.success);
    expect(provider.historySessions, [session]);
  });
}

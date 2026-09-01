import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import 'package:cloud_lms/features/attendance/data/models/student_attendance_history.dart';
import 'package:cloud_lms/features/attendance/data/repositories/attendance_repository.dart';
import 'package:cloud_lms/features/attendance/presentation/providers/self_attendance_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAttendanceRepository extends Mock implements AttendanceRepository {}

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

const _student2 = Student(
  id: 's2',
  fullName: 'Alex Other',
  email: 'alex@school.test',
  admissionNumber: 'ADM002',
  rollNumber: '2',
  className: 'Class 9',
  section: 'B',
  parentId: null,
  dob: '',
  address: '',
  phone: '',
  status: 'active',
);

const _history = StudentAttendanceHistory(
  studentName: 'Sam Student',
  summary: AttendanceHistorySummary(present: 8, absent: 1, late: 1, leave: 0, halfDay: 0, total: 10, percentage: 90),
  records: [],
);

void main() {
  late _MockAttendanceRepository repository;
  late SelfAttendanceProvider provider;

  setUp(() {
    repository = _MockAttendanceRepository();
    provider = SelfAttendanceProvider(repository);
  });

  test('loadOwnHistory(): resolves own id then loads its history', () async {
    when(() => repository.getMyStudentId()).thenAnswer((_) async => const Result.success('s1'));
    when(() => repository.getStudentAttendanceHistory(
          studentId: any(named: 'studentId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Result.success(_history));

    await provider.loadOwnHistory();

    expect(provider.historyStatus, LoadStatus.success);
    expect(provider.history, _history);
    verify(() => repository.getStudentAttendanceHistory(
          studentId: 's1',
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).called(1);
  });

  test('loadOwnHistory(): failure resolving own id surfaces as a history error', () async {
    when(() => repository.getMyStudentId()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadOwnHistory();

    expect(provider.historyStatus, LoadStatus.error);
    expect(provider.historyError, isA<NetworkException>());
  });

  test('loadChildren(): with exactly one child, auto-selects and loads its history', () async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1]));
    when(() => repository.getStudentAttendanceHistory(
          studentId: any(named: 'studentId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Result.success(_history));

    await provider.loadChildren();

    expect(provider.childrenStatus, LoadStatus.success);
    expect(provider.selectedChildId, 's1');
    expect(provider.historyStatus, LoadStatus.success);
  });

  test('loadChildren(): with more than one child, does not auto-select', () async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1, _student2]));

    await provider.loadChildren();

    expect(provider.childrenStatus, LoadStatus.success);
    expect(provider.selectedChildId, isNull);
    expect(provider.historyStatus, LoadStatus.initial);
  });

  test('selectChild(): loads the chosen child\'s history', () async {
    when(() => repository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1, _student2]));
    await provider.loadChildren();
    when(() => repository.getStudentAttendanceHistory(
          studentId: any(named: 'studentId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).thenAnswer((_) async => const Result.success(_history));

    await provider.selectChild('s2');

    expect(provider.selectedChildId, 's2');
    expect(provider.historyStatus, LoadStatus.success);
    verify(() => repository.getStudentAttendanceHistory(
          studentId: 's2',
          month: any(named: 'month'),
          year: any(named: 'year'),
        )).called(1);
  });
}

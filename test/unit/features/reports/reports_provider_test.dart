import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/reports/data/models/academic_report.dart';
import 'package:cloud_lms/features/reports/data/models/attendance_report.dart';
import 'package:cloud_lms/features/reports/data/models/financial_report.dart';
import 'package:cloud_lms/features/reports/data/models/system_report.dart';
import 'package:cloud_lms/features/reports/data/repositories/reports_repository.dart';
import 'package:cloud_lms/features/reports/presentation/providers/reports_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportsRepository extends Mock implements ReportsRepository {}

const _academic = AcademicReport(
  totalExams: 4,
  published: 2,
  upcoming: 1,
  ongoing: 0,
  completed: 1,
  gradeDistribution: {'A+': 3},
  totalStudentResults: 9,
  totalPassed: 8,
  passRate: 88.9,
  totalStudents: 40,
  totalTeachers: 6,
);

const _financial = FinancialReport(
  totalInvoiced: 100000,
  totalCollected: 60000,
  totalPending: 40000,
  paidCount: 3,
  partialCount: 2,
  pendingCount: 1,
  payrollTotalNetSalary: 90000,
  payrollTotalPaid: 30000,
  payrollTotalPending: 60000,
  totalPayments: 5,
);

const _attendance = AttendanceReport(
  total: 100,
  present: 90,
  absent: 8,
  late: 2,
  attendanceRate: 90,
  totalStudents: 40,
  classBreakdown: {'10-A': ClassAttendanceBreakdown(present: 18, absent: 1, late: 1, total: 20)},
);

const _system = SystemReport(
  totalStudents: 40,
  totalTeachers: 6,
  totalParents: 30,
  totalLogs: 1,
  actionBreakdown: {'Auth': 1},
  recentLogs: [
    AuditLogEntry(action: 'Login', user: 'admin@test.dev', category: 'Auth', status: 'success', createdAt: null),
  ],
);

void main() {
  late _MockReportsRepository repository;
  late ReportsProvider provider;

  setUp(() {
    repository = _MockReportsRepository();
    provider = ReportsProvider(repository);
  });

  test('loadAcademic(): success stores the report', () async {
    when(() => repository.getAcademicReport()).thenAnswer((_) async => const Result.success(_academic));

    await provider.loadAcademic();

    expect(provider.academicStatus, LoadStatus.success);
    expect(provider.academic, _academic);
  });

  test('loadAcademic(): failure surfaces the error and clears no prior success', () async {
    when(() => repository.getAcademicReport())
        .thenAnswer((_) async => const Result.failure(ServerException('school not found')));

    await provider.loadAcademic();

    expect(provider.academicStatus, LoadStatus.error);
    expect(provider.academicError?.message, contains('school not found'));
    expect(provider.academic, isNull);
  });

  test('loadFinancial(): success stores the report', () async {
    when(() => repository.getFinancialReport()).thenAnswer((_) async => const Result.success(_financial));

    await provider.loadFinancial();

    expect(provider.financialStatus, LoadStatus.success);
    expect(provider.financial, _financial);
  });

  test('loadAttendance(): stores the requested date range alongside the result', () async {
    final start = DateTime(2026, 8, 1);
    final end = DateTime(2026, 8, 25);
    when(() => repository.getAttendanceReport(startDate: start, endDate: end))
        .thenAnswer((_) async => const Result.success(_attendance));

    await provider.loadAttendance(startDate: start, endDate: end);

    expect(provider.attendanceStatus, LoadStatus.success);
    expect(provider.attendance, _attendance);
    expect(provider.attendanceStartDate, start);
    expect(provider.attendanceEndDate, end);
  });

  test('loadAttendance(): with no arguments, clears any previously set date range', () async {
    final start = DateTime(2026, 8, 1);
    final end = DateTime(2026, 8, 25);
    when(() => repository.getAttendanceReport(startDate: start, endDate: end))
        .thenAnswer((_) async => const Result.success(_attendance));
    await provider.loadAttendance(startDate: start, endDate: end);

    when(() => repository.getAttendanceReport(startDate: null, endDate: null))
        .thenAnswer((_) async => const Result.success(_attendance));
    await provider.loadAttendance();

    expect(provider.attendanceStartDate, isNull);
    expect(provider.attendanceEndDate, isNull);
  });

  test('loadSystem(): success stores the report', () async {
    when(() => repository.getSystemReport()).thenAnswer((_) async => const Result.success(_system));

    await provider.loadSystem();

    expect(provider.systemStatus, LoadStatus.success);
    expect(provider.system, _system);
  });
}

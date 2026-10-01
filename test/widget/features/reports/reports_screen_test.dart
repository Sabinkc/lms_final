import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/reports/data/models/academic_report.dart';
import 'package:cloud_lms/features/reports/data/models/attendance_report.dart';
import 'package:cloud_lms/features/reports/data/models/financial_report.dart';
import 'package:cloud_lms/features/reports/data/models/system_report.dart';
import 'package:cloud_lms/features/reports/data/repositories/reports_repository.dart';
import 'package:cloud_lms/features/reports/presentation/providers/reports_provider.dart';
import 'package:cloud_lms/features/reports/presentation/screens/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockReportsRepository extends Mock implements ReportsRepository {}

const _academic = AcademicReport(
  totalExams: 4,
  published: 2,
  upcoming: 1,
  ongoing: 0,
  completed: 1,
  gradeDistribution: {'A+': 3, 'F': 1},
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
  payrollTotalPaid: 25000,
  payrollTotalPending: 65000,
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

Widget _wrap(ReportsProvider provider) => ChangeNotifierProvider<ReportsProvider>.value(
      value: provider,
      child: const MaterialApp(home: ReportsScreen()),
    );

void main() {
  late _MockReportsRepository repository;

  setUp(() {
    repository = _MockReportsRepository();
    when(() => repository.getAcademicReport()).thenAnswer((_) async => const Result.success(_academic));
    when(() => repository.getFinancialReport()).thenAnswer((_) async => const Result.success(_financial));
    when(() => repository.getAttendanceReport(startDate: any(named: 'startDate'), endDate: any(named: 'endDate')))
        .thenAnswer((_) async => const Result.success(_attendance));
    when(() => repository.getSystemReport()).thenAnswer((_) async => const Result.success(_system));
  });

  testWidgets('Academic tab shows stat cards and grade distribution on load', (tester) async {
    final provider = ReportsProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('4'), findsOneWidget); // totalExams
    expect(find.text('88.9%'), findsOneWidget); // passRate
    expect(find.text('A+'), findsOneWidget);
  });

  testWidgets('switching to Financial tab shows fee and payroll totals', (tester) async {
    final provider = ReportsProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Financial'));
    await tester.pumpAndSettle();

    expect(find.text('Rs. 60,000'), findsOneWidget);
    expect(find.text('Rs. 40,000'), findsOneWidget);
  });

  testWidgets('switching to Attendance tab shows the class breakdown row', (tester) async {
    final provider = ReportsProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Attendance'));
    await tester.pumpAndSettle();

    expect(find.text('90.0%'), findsWidgets);
    expect(find.text('10-A'), findsOneWidget);
  });

  testWidgets('switching to System tab shows the recent log entry', (tester) async {
    final provider = ReportsProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.textContaining('admin@test.dev'), findsOneWidget);
  });

  testWidgets('Academic tab shows an error view with retry on failure', (tester) async {
    final failingRepository = _MockReportsRepository();
    when(() => failingRepository.getAcademicReport())
        .thenAnswer((_) async => const Result.failure(ServerException('school not found')));
    when(() => failingRepository.getFinancialReport()).thenAnswer((_) async => const Result.success(_financial));
    when(() => failingRepository.getAttendanceReport(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => const Result.success(_attendance));
    when(() => failingRepository.getSystemReport()).thenAnswer((_) async => const Result.success(_system));
    final provider = ReportsProvider(failingRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.textContaining('school not found'), findsOneWidget);
  });
}

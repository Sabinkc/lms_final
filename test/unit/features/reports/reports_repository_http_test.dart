import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/reports/data/repositories/reports_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late ReportsRepositoryHttp repository;

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

    repository = ReportsRepositoryHttp(apiClient);
  });

  test('getAcademicReport(): parses summary, grade distribution, and passRate as a numeric string', () async {
    fakeAdapter.when(
      '/reports/academic',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          'summary': {'totalExams': 4, 'published': 2, 'upcoming': 1, 'ongoing': 0, 'completed': 1},
          'gradeDistribution': {'A+': 3, 'A': 5, 'B+': 0, 'B': 0, 'C+': 0, 'C': 0, 'F': 1},
          'totalStudentResults': 9,
          'totalPassed': 8,
          'passRate': '88.9',
          'totalStudents': 40,
          'totalTeachers': 6,
          'exams': [],
        },
      }, 200),
    );

    final result = await repository.getAcademicReport();

    result.when(
      success: (report) {
        expect(report.totalExams, 4);
        expect(report.gradeDistribution['A+'], 3);
        expect(report.passRate, 88.9);
        expect(report.totalStudents, 40);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getAcademicReport(): passRate is the bare number 0 (not a string) when there are no results yet', () async {
    fakeAdapter.when(
      '/reports/academic',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          'summary': {'totalExams': 0, 'published': 0, 'upcoming': 0, 'ongoing': 0, 'completed': 0},
          'gradeDistribution': {},
          'totalStudentResults': 0,
          'totalPassed': 0,
          'passRate': 0,
          'totalStudents': 0,
          'totalTeachers': 0,
          'exams': [],
        },
      }, 200),
    );

    final result = await repository.getAcademicReport();

    result.when(
      success: (report) => expect(report.passRate, 0),
      failure: (_) => fail('expected success'),
    );
  });

  test('getFinancialReport(): parses feeSummary and payrollSummary', () async {
    fakeAdapter.when(
      '/reports/financial',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          'feeSummary': {'totalInvoiced': 100000, 'totalCollected': 60000, 'totalPending': 40000, 'paid': 3, 'partial': 2, 'pending': 1},
          'payrollSummary': {'totalNetSalary': 90000, 'totalPaid': 30000, 'totalPending': 60000},
          'totalPayments': 5,
          'fees': [],
          'payrolls': [],
        },
      }, 200),
    );

    final result = await repository.getFinancialReport();

    result.when(
      success: (report) {
        expect(report.totalCollected, 60000);
        expect(report.paidCount, 3);
        expect(report.payrollTotalPending, 60000);
        expect(report.totalPayments, 5);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getAttendanceReport(): with a date range, parses classBreakdown keyed by "class-section"', () async {
    fakeAdapter.when(
      '/reports/attendance',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          'summary': {'total': 100, 'present': 90, 'absent': 8, 'late': 2, 'attendanceRate': '90.0', 'totalStudents': 40},
          'classBreakdown': {
            '10-A': {'present': 18, 'absent': 1, 'late': 1, 'total': 20},
          },
          'records': [],
        },
      }, 200),
    );

    final result = await repository.getAttendanceReport(
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 25),
    );

    result.when(
      success: (report) {
        expect(report.attendanceRate, 90.0);
        expect(report.classBreakdown['10-A']!.present, 18);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getAttendanceReport(): with no date range, still parses a full-history response', () async {
    fakeAdapter.when(
      '/reports/attendance',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          'summary': {'total': 0, 'present': 0, 'absent': 0, 'late': 0, 'attendanceRate': 0, 'totalStudents': 0},
          'classBreakdown': {},
          'records': [],
        },
      }, 200),
    );

    final result = await repository.getAttendanceReport();

    result.when(
      success: (report) => expect(report.total, 0),
      failure: (_) => fail('expected success'),
    );
  });

  test('getSystemReport(): parses actionBreakdown and caps recentLogs at 20 even if the server sends more', () async {
    final manyLogs = List.generate(
      30,
      (i) => {'action': 'Login', 'user': 'admin@test.dev', 'category': 'Auth', 'status': 'success', 'createdAt': '2026-08-25T00:00:00.000Z'},
    );
    fakeAdapter.when(
      '/reports/system',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          'summary': {'totalStudents': 40, 'totalTeachers': 6, 'totalParents': 30, 'totalLogs': 30},
          'actionBreakdown': {'Auth': 30},
          'logs': manyLogs,
        },
      }, 200),
    );

    final result = await repository.getSystemReport();

    result.when(
      success: (report) {
        expect(report.totalLogs, 30);
        expect(report.actionBreakdown['Auth'], 30);
        expect(report.recentLogs, hasLength(20));
      },
      failure: (_) => fail('expected success'),
    );
  });
}

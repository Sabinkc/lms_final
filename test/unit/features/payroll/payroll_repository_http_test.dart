import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/payroll/data/repositories/payroll_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

Map<String, dynamic> _payrollJson({String status = 'pending', Map<String, dynamic>? staff}) => {
      '_id': 'pr1',
      'staffId': 't1',
      'staffModel': 'Teacher',
      if (staff != null) 'staff': staff,
      'month': 8,
      'year': 2026,
      'basicSalary': 30000,
      'allowances': {'houseRent': 3000, 'transport': 1000, 'medical': 500, 'other': 0},
      'deductions': {'tax': 1500, 'providentFund': 3000, 'absence': 0, 'loan': 0, 'other': 0},
      'totalAllowances': 4500,
      'totalDeductions': 4500,
      'grossSalary': 34500,
      'netSalary': 30000,
      'workingDays': 26,
      'presentDays': 26,
      'absentDays': 0,
      'status': status,
      'paymentMethod': 'cash',
      'remarks': '',
    };

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late PayrollRepositoryHttp repository;

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

    repository = PayrollRepositoryHttp(apiClient);
  });

  test('setStaffSalary(): always sends staffModel "Teacher" and parses the upserted config', () async {
    fakeAdapter.when(
      '/payroll/salary-config',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'cfg1',
          'staffId': 't1',
          'staffModel': 'Teacher',
          'basicSalary': 30000,
          'allowances': {'houseRent': 3000, 'transport': 1000, 'medical': 500, 'other': 0},
          'pfRate': 10,
          'taxRate': 5,
          'workingDays': 26,
          'isActive': true,
        },
      }, 200),
    );

    final result = await repository.setStaffSalary(staffId: 't1', basicSalary: 30000);

    result.when(
      success: (config) {
        expect(config.staffModel, 'Teacher');
        expect(config.staffName, isNull);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getSalaryConfigs(): parses the server-built staff {name, email} object', () async {
    fakeAdapter.when(
      '/payroll/salary-config',
      (_) => jsonResponseBody({
        'success': true,
        'data': [
          {
            '_id': 'cfg1',
            'staffId': 't1',
            'staffModel': 'Teacher',
            'basicSalary': 30000,
            'allowances': {'houseRent': 0, 'transport': 0, 'medical': 0, 'other': 0},
            'pfRate': 10,
            'taxRate': 5,
            'workingDays': 26,
            'isActive': true,
            'staff': {'_id': 't1', 'name': 'Jane Teacher', 'email': 'jane@test.dev', 'model': 'Teacher'},
          },
        ],
      }, 200),
    );

    final result = await repository.getSalaryConfigs();

    result.when(
      success: (configs) => expect(configs.single.staffName, 'Jane Teacher'),
      failure: (_) => fail('expected success'),
    );
  });

  test('generatePayroll(): posts staffModel "Teacher" + month/year and parses the created payroll', () async {
    fakeAdapter.when('/payroll/generate', (_) => jsonResponseBody({'success': true, 'data': _payrollJson()}, 201));

    final result = await repository.generatePayroll(staffId: 't1', month: 8, year: 2026);

    result.when(
      success: (payroll) => expect(payroll.netSalary, 30000),
      failure: (_) => fail('expected success'),
    );
  });

  test('generateBulkPayroll(): parses the (generated, skipped, failed) counts', () async {
    fakeAdapter.when(
      '/payroll/generate-bulk',
      (_) => jsonResponseBody({
        'success': true,
        'data': {'generated': 2, 'skipped': 1, 'failed': 0, 'details': {}},
      }, 200),
    );

    final result = await repository.generateBulkPayroll(month: 8, year: 2026);

    result.when(
      success: (counts) => expect(counts, (2, 1, 0)),
      failure: (_) => fail('expected success'),
    );
  });

  test('markAsPaid(): puts to /payroll/:id/mark-paid', () async {
    fakeAdapter.when('/payroll/pr1/mark-paid', (_) => jsonResponseBody({'success': true, 'data': _payrollJson(status: 'paid')}, 200));

    final result = await repository.markAsPaid('pr1');

    result.when(
      success: (payroll) => expect(payroll.status, 'paid'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getAllPayrolls(): parses (summary, payrolls) as one tuple', () async {
    fakeAdapter.when(
      '/payroll',
      (_) => jsonResponseBody({
        'success': true,
        'summary': {'totalNetSalary': 30000, 'totalPaid': 0, 'totalPending': 30000},
        'data': [
          _payrollJson(staff: {'_id': 't1', 'name': 'Jane Teacher', 'email': 'jane@test.dev', 'model': 'Teacher'}),
        ],
      }, 200),
    );

    final result = await repository.getAllPayrolls();

    result.when(
      success: (data) {
        final (summary, payrolls) = data;
        expect(summary.totalPending, 30000);
        expect(payrolls.single.staffName, 'Jane Teacher');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyPayslips(): parses the caller\'s own payslip list', () async {
    fakeAdapter.when(
      '/payroll/my',
      (_) => jsonResponseBody({'success': true, 'totalEarned': 0, 'data': [_payrollJson()]}, 200),
    );

    final result = await repository.getMyPayslips();

    result.when(
      success: (payslips) => expect(payslips.single.month, 8),
      failure: (_) => fail('expected success'),
    );
  });
}

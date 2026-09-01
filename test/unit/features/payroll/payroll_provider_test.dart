import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/teacher.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/payroll/data/models/payroll.dart';
import 'package:cloud_lms/features/payroll/data/models/staff_salary_config.dart';
import 'package:cloud_lms/features/payroll/data/repositories/payroll_repository.dart';
import 'package:cloud_lms/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPayrollRepository extends Mock implements PayrollRepository {}

class _MockTeacherRepository extends Mock implements TeacherRepository {}

const _allowances = PayrollAllowances(houseRent: 3000, transport: 1000, medical: 500, other: 0);
const _deductions = PayrollDeductions(tax: 1500, providentFund: 3000, absence: 0, loan: 0, other: 0);

const _config1 = StaffSalaryConfig(
  id: 'cfg1',
  staffId: 't1',
  staffModel: 'Teacher',
  staffName: 'Jane Teacher',
  staffEmail: 'jane@test.dev',
  basicSalary: 30000,
  allowances: _allowances,
  pfRate: 10,
  taxRate: 5,
  workingDays: 26,
  isActive: true,
);

const _payroll1 = Payroll(
  id: 'pr1',
  staffId: 't1',
  staffModel: 'Teacher',
  staffName: 'Jane Teacher',
  staffEmail: 'jane@test.dev',
  month: 8,
  year: 2026,
  basicSalary: 30000,
  allowances: _allowances,
  deductions: _deductions,
  totalAllowances: 4500,
  totalDeductions: 4500,
  grossSalary: 34500,
  netSalary: 30000,
  workingDays: 26,
  presentDays: 26,
  absentDays: 0,
  status: 'pending',
  paidAt: null,
  paymentMethod: 'cash',
  remarks: '',
);

const _summary = PayrollSummary(totalNetSalary: 30000, totalPaid: 0, totalPending: 30000);

void main() {
  late _MockPayrollRepository payrollRepository;
  late _MockTeacherRepository teacherRepository;
  late PayrollProvider provider;

  setUp(() {
    payrollRepository = _MockPayrollRepository();
    teacherRepository = _MockTeacherRepository();
    provider = PayrollProvider(payrollRepository, teacherRepository);
  });

  test('setStaffSalary(): success adds a new config that wasn\'t in the list before', () async {
    when(() => payrollRepository.setStaffSalary(
          staffId: any(named: 'staffId'),
          basicSalary: any(named: 'basicSalary'),
          allowances: any(named: 'allowances'),
          pfRate: any(named: 'pfRate'),
          taxRate: any(named: 'taxRate'),
          workingDays: any(named: 'workingDays'),
        )).thenAnswer((_) async => const Result.success(_config1));

    final succeeded = await provider.setStaffSalary(staffId: 't1', basicSalary: 30000);

    expect(succeeded, isTrue);
    expect(provider.configs, [_config1]);
  });

  test('setStaffSalary(): updating an existing config (upsert) replaces it in place, not a duplicate', () async {
    when(() => payrollRepository.getSalaryConfigs()).thenAnswer((_) async => const Result.success([_config1]));
    await provider.loadSalaryConfigs();

    const updated = StaffSalaryConfig(
      id: 'cfg1',
      staffId: 't1',
      staffModel: 'Teacher',
      staffName: 'Jane Teacher',
      staffEmail: 'jane@test.dev',
      basicSalary: 35000,
      allowances: _allowances,
      pfRate: 10,
      taxRate: 5,
      workingDays: 26,
      isActive: true,
    );
    when(() => payrollRepository.setStaffSalary(
          staffId: any(named: 'staffId'),
          basicSalary: any(named: 'basicSalary'),
          allowances: any(named: 'allowances'),
          pfRate: any(named: 'pfRate'),
          taxRate: any(named: 'taxRate'),
          workingDays: any(named: 'workingDays'),
        )).thenAnswer((_) async => const Result.success(updated));

    await provider.setStaffSalary(staffId: 't1', basicSalary: 35000);

    expect(provider.configs, hasLength(1));
    expect(provider.configs.single.basicSalary, 35000);
  });

  test('generatePayroll(): success prepends the new payroll', () async {
    when(() => payrollRepository.generatePayroll(
          staffId: any(named: 'staffId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
          absentDays: any(named: 'absentDays'),
          remarks: any(named: 'remarks'),
        )).thenAnswer((_) async => const Result.success(_payroll1));

    final succeeded = await provider.generatePayroll(staffId: 't1', month: 8, year: 2026);

    expect(succeeded, isTrue);
    expect(provider.payrolls, [_payroll1]);
  });

  test('generatePayroll(): failure (e.g. "already exists for this staff") surfaces the error, no duplicate added', () async {
    when(() => payrollRepository.generatePayroll(
          staffId: any(named: 'staffId'),
          month: any(named: 'month'),
          year: any(named: 'year'),
          absentDays: any(named: 'absentDays'),
          remarks: any(named: 'remarks'),
        )).thenAnswer((_) async => const Result.failure(ServerException('Payroll for August 2026 already exists for this staff')));

    final succeeded = await provider.generatePayroll(staffId: 't1', month: 8, year: 2026);

    expect(succeeded, isFalse);
    expect(provider.payrolls, isEmpty);
    expect(provider.generateError?.message, contains('already exists'));
  });

  test('generateBulkPayroll(): success stores the counts and reloads the payroll list', () async {
    when(() => payrollRepository.generateBulkPayroll(month: any(named: 'month'), year: any(named: 'year')))
        .thenAnswer((_) async => const Result.success((2, 1, 0)));
    when(() => payrollRepository.getAllPayrolls(month: any(named: 'month'), year: any(named: 'year'), status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success((_summary, [_payroll1])));

    final succeeded = await provider.generateBulkPayroll(month: 8, year: 2026);

    expect(succeeded, isTrue);
    expect(provider.lastBulkResult, (2, 1, 0));
    expect(provider.payrolls, [_payroll1]);
  });

  test('markAsPaid(): success updates that payroll in place', () async {
    when(() => payrollRepository.getAllPayrolls(month: any(named: 'month'), year: any(named: 'year'), status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success((_summary, [_payroll1])));
    await provider.loadPayrolls();

    const paid = Payroll(
      id: 'pr1',
      staffId: 't1',
      staffModel: 'Teacher',
      staffName: 'Jane Teacher',
      staffEmail: 'jane@test.dev',
      month: 8,
      year: 2026,
      basicSalary: 30000,
      allowances: _allowances,
      deductions: _deductions,
      totalAllowances: 4500,
      totalDeductions: 4500,
      grossSalary: 34500,
      netSalary: 30000,
      workingDays: 26,
      presentDays: 26,
      absentDays: 0,
      status: 'paid',
      paidAt: '2026-08-24T00:00:00.000Z',
      paymentMethod: 'cash',
      remarks: '',
    );
    when(() => payrollRepository.markAsPaid(any(), paymentMethod: any(named: 'paymentMethod'), remarks: any(named: 'remarks')))
        .thenAnswer((_) async => const Result.success(paid));

    final succeeded = await provider.markAsPaid('pr1');

    expect(succeeded, isTrue);
    expect(provider.payrolls.single.status, 'paid');
  });

  test('deletePayroll(): success removes it from the list', () async {
    when(() => payrollRepository.getAllPayrolls(month: any(named: 'month'), year: any(named: 'year'), status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success((_summary, [_payroll1])));
    await provider.loadPayrolls();
    when(() => payrollRepository.deletePayroll(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deletePayroll('pr1');

    expect(succeeded, isTrue);
    expect(provider.payrolls, isEmpty);
  });

  test('loadTeacherOptions(): populates teacherOptions for staff pickers', () async {
    const teacher = Teacher(
      id: 't1',
      fullName: 'Jane Teacher',
      email: 'jane@test.dev',
      employeeId: 'EMP001',
      department: 'Science',
      designation: '',
      qualification: '',
      subjects: [],
      experience: 0,
      salary: 0,
      address: '',
      phone: '',
      bankAccountNumber: '',
      status: 'active',
    );
    when(() => teacherRepository.getTeachers()).thenAnswer((_) async => const Result.success([teacher]));

    await provider.loadTeacherOptions();

    expect(provider.teacherOptions, [teacher]);
  });
}

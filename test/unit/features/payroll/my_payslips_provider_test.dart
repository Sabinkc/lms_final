import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/payroll/data/models/payroll.dart';
import 'package:cloud_lms/features/payroll/data/repositories/payroll_repository.dart';
import 'package:cloud_lms/features/payroll/presentation/providers/my_payslips_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPayrollRepository extends Mock implements PayrollRepository {}

const _payslip1 = Payroll(
  id: 'pr1',
  staffId: 't1',
  staffModel: 'Teacher',
  staffName: null,
  staffEmail: null,
  month: 8,
  year: 2026,
  basicSalary: 30000,
  allowances: PayrollAllowances(houseRent: 0, transport: 0, medical: 0, other: 0),
  deductions: PayrollDeductions(tax: 0, providentFund: 0, absence: 0, loan: 0, other: 0),
  totalAllowances: 0,
  totalDeductions: 0,
  grossSalary: 30000,
  netSalary: 30000,
  workingDays: 26,
  presentDays: 26,
  absentDays: 0,
  status: 'paid',
  paidAt: '2026-08-24T00:00:00.000Z',
  paymentMethod: 'cash',
  remarks: '',
);

void main() {
  late _MockPayrollRepository repository;
  late MyPayslipsProvider provider;

  setUp(() {
    repository = _MockPayrollRepository();
    provider = MyPayslipsProvider(repository);
  });

  test('loadMyPayslips(): success populates payslips', () async {
    when(() => repository.getMyPayslips()).thenAnswer((_) async => const Result.success([_payslip1]));

    await provider.loadMyPayslips();

    expect(provider.status, LoadStatus.success);
    expect(provider.payslips, [_payslip1]);
  });

  test('loadMyPayslips(): failure sets error status', () async {
    when(() => repository.getMyPayslips()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadMyPayslips();

    expect(provider.status, LoadStatus.error);
    expect(provider.error, isA<NetworkException>());
  });
}

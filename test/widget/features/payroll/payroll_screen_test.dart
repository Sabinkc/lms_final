import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/teacher_repository.dart';
import 'package:cloud_lms/features/payroll/data/models/payroll.dart';
import 'package:cloud_lms/features/payroll/data/models/staff_salary_config.dart';
import 'package:cloud_lms/features/payroll/data/repositories/payroll_repository.dart';
import 'package:cloud_lms/features/payroll/presentation/providers/payroll_provider.dart';
import 'package:cloud_lms/features/payroll/presentation/screens/payroll_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

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

Widget _wrap(PayrollProvider provider) => ChangeNotifierProvider<PayrollProvider>.value(
      value: provider,
      child: const MaterialApp(home: PayrollScreen()),
    );

void main() {
  late _MockPayrollRepository payrollRepository;
  late _MockTeacherRepository teacherRepository;

  setUp(() {
    payrollRepository = _MockPayrollRepository();
    teacherRepository = _MockTeacherRepository();
  });

  testWidgets('Salary Config tab lists configs; Payroll tab lists payrolls with the summary card', (tester) async {
    when(() => payrollRepository.getSalaryConfigs()).thenAnswer((_) async => const Result.success([_config1]));
    when(() => payrollRepository.getAllPayrolls(month: any(named: 'month'), year: any(named: 'year'), status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success((_summary, [_payroll1])));
    final provider = PayrollProvider(payrollRepository, teacherRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Jane Teacher'), findsOneWidget);

    await tester.tap(find.widgetWithText(Tab, 'Payroll'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Jane Teacher'), findsOneWidget);
    expect(find.text('Rs 30000'), findsOneWidget);
  });

  testWidgets('mark-paid flow: tapping Mark Paid updates the payroll status in place', (tester) async {
    when(() => payrollRepository.getSalaryConfigs()).thenAnswer((_) async => const Result.success([_config1]));
    when(() => payrollRepository.getAllPayrolls(month: any(named: 'month'), year: any(named: 'year'), status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success((_summary, [_payroll1])));
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
    final provider = PayrollProvider(payrollRepository, teacherRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Payroll'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mark Paid'));
    await tester.pumpAndSettle();

    verify(() => payrollRepository.markAsPaid('pr1', paymentMethod: any(named: 'paymentMethod'), remarks: any(named: 'remarks')))
        .called(1);
    expect(find.text('Mark Paid'), findsNothing);
  });
}

import 'dart:async';

import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/payroll/data/models/payroll.dart';
import 'package:cloud_lms/features/payroll/data/repositories/payroll_repository.dart';
import 'package:cloud_lms/features/payroll/presentation/providers/my_payslips_provider.dart';
import 'package:cloud_lms/features/payroll/presentation/screens/my_payslips_screen.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

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

Widget _wrap(MyPayslipsProvider provider) => ChangeNotifierProvider<MyPayslipsProvider>.value(
      value: provider,
      child: const MaterialApp(home: MyPayslipsScreen()),
    );

void main() {
  late _MockPayrollRepository repository;

  setUp(() {
    repository = _MockPayrollRepository();
  });

  testWidgets('loading state shows the skeleton loading view', (tester) async {
    when(() => repository.getMyPayslips()).thenAnswer((_) => Completer<Result<List<Payroll>>>().future);
    final provider = MyPayslipsProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows a message', (tester) async {
    when(() => repository.getMyPayslips()).thenAnswer((_) async => const Result.success([]));
    final provider = MyPayslipsProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No payslips generated yet'), findsOneWidget);
  });

  testWidgets('success state expands to show the net salary breakdown', (tester) async {
    when(() => repository.getMyPayslips()).thenAnswer((_) async => const Result.success([_payslip1]));
    final provider = MyPayslipsProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('August 2026'), findsOneWidget);

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    expect(find.text('Net Salary'), findsOneWidget);
  });
}

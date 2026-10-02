import 'dart:async';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/fees/data/models/fee.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository.dart';
import 'package:cloud_lms/features/fees/data/repositories/payment_repository.dart';
import 'package:cloud_lms/features/fees/presentation/providers/fee_provider.dart';
import 'package:cloud_lms/features/fees/presentation/screens/admin_fees_screen.dart';
import 'package:cloud_lms/shared/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockFeeRepository extends Mock implements FeeRepository {}

class _MockPaymentRepository extends Mock implements PaymentRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

const _fee1 = Fee(
  id: 'f1',
  studentId: 's1',
  studentName: 'Sam Student',
  admissionNumber: 'ADM001',
  className: 'Class 10',
  section: 'A',
  title: 'Term 1 Fee',
  description: '',
  totalAmount: 5000,
  discountPercent: 0,
  discountAmount: 0,
  paidAmount: 0,
  remainingAmount: 5000,
  dueDate: '2026-09-01',
  isInstallment: false,
  installments: [],
  status: 'pending',
);

const _student1 = Student(
  id: 's1',
  fullName: 'Sam Student',
  email: 'sam@test.dev',
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

/// The restyled screen's header/stat-cards/quick-actions/chart all sit
/// above the fee list now, pushing it below the default 800x600 test
/// surface's fold — `find.text`/`find.textContaining` skip offstage
/// (unpainted) matches by default, so tests asserting on the fee list need
/// a taller surface to see it without a separate scroll-into-view step.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(FeeProvider provider) => ChangeNotifierProvider<FeeProvider>.value(
      value: provider,
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(path: '/', builder: (context, state) => const AdminFeesScreen()),
            GoRoute(path: '/admin/fees/payments', builder: (context, state) => const SizedBox()),
          ],
        ),
      ),
    );

void main() {
  late _MockFeeRepository feeRepository;
  late _MockPaymentRepository paymentRepository;
  late _MockStudentRepository studentRepository;

  setUp(() {
    feeRepository = _MockFeeRepository();
    paymentRepository = _MockPaymentRepository();
    studentRepository = _MockStudentRepository();
    // The screen now also loads payment history for its "Recent Fee
    // Collections" section — stub a default empty result so every test not
    // specifically exercising that section doesn't need its own stub.
    when(() => paymentRepository.getPaymentHistory()).thenAnswer((_) async => const Result.success([]));
  });

  testWidgets('loading state shows the skeleton loading view', (tester) async {
    when(() => feeRepository.getFees(status: any(named: 'status')))
        .thenAnswer((_) => Completer<Result<List<Fee>>>().future);
    final provider = FeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(LoadingView), findsOneWidget);
  });

  testWidgets('empty state shows the add-fee CTA', (tester) async {
    _useTallSurface(tester);
    when(() => feeRepository.getFees(status: any(named: 'status'))).thenAnswer((_) async => const Result.success([]));
    final provider = FeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No fees set up yet'), findsOneWidget);
  });

  testWidgets('success state shows fee + student, expands to show due date, and deletes on confirm', (tester) async {
    _useTallSurface(tester);
    when(() => feeRepository.getFees(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.success([_fee1]));
    when(() => feeRepository.deleteFee(any())).thenAnswer((_) async => const Result.success(null));
    final provider = FeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.textContaining('Term 1 Fee'), findsOneWidget);

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    verify(() => feeRepository.deleteFee('f1')).called(1);
  });

  testWidgets('add-fee flow: FAB -> pick student via Autocomplete -> save calls createFee', (tester) async {
    when(() => feeRepository.getFees(status: any(named: 'status'))).thenAnswer((_) async => const Result.success([]));
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => const Result.success([_student1]));
    when(() => feeRepository.createFee(
          studentId: any(named: 'studentId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          totalAmount: any(named: 'totalAmount'),
          discountPercent: any(named: 'discountPercent'),
          dueDate: any(named: 'dueDate'),
          isInstallment: any(named: 'isInstallment'),
          installments: any(named: 'installments'),
        )).thenAnswer((_) async => const Result.success(_fee1));
    final provider = FeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    // "Add Fee" also appears as the empty-state action button below the
    // Quick Actions tile (fees list is empty in this test) — the tile comes
    // first in the widget tree, so `.first` is the tile.
    await tester.tap(find.text('Add Fee').first);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Add Fee'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Student'), 'Sam');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sam Student (ADM001)').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Term 1 Fee');
    await tester.enterText(find.widgetWithText(TextFormField, 'Total Amount (Rs)'), '5000');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => feeRepository.createFee(
          studentId: 's1',
          title: 'Term 1 Fee',
          description: any(named: 'description'),
          totalAmount: 5000,
          discountPercent: any(named: 'discountPercent'),
          dueDate: any(named: 'dueDate'),
          isInstallment: false,
          installments: any(named: 'installments'),
        )).called(1);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('a failed export shows the error message in a snackbar', (tester) async {
    when(() => feeRepository.getFees(status: any(named: 'status'))).thenAnswer((_) async => const Result.success([]));
    when(() => feeRepository.exportFees(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.failure(ServerException('Export failed')));
    final provider = FeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export Fees'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Export failed'), findsOneWidget);
  });
}

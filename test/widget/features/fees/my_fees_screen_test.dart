import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/fees/data/models/fee.dart';
import 'package:cloud_lms/features/fees/data/models/fee_payment.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository.dart';
import 'package:cloud_lms/features/fees/data/repositories/payment_repository.dart';
import 'package:cloud_lms/features/fees/presentation/providers/self_fee_provider.dart';
import 'package:cloud_lms/features/fees/presentation/screens/my_fees_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockFeeRepository extends Mock implements FeeRepository {}

class _MockPaymentRepository extends Mock implements PaymentRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

const _me = Student(
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

const _summary = FeesSummary(total: 1, pending: 1, partial: 0, paid: 0, totalDue: 5000);

const _fee1 = Fee(
  id: 'f1',
  studentId: 's1',
  studentName: null,
  admissionNumber: null,
  className: null,
  section: null,
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

Widget _wrap(SelfFeeProvider provider) => ChangeNotifierProvider<SelfFeeProvider>.value(
      value: provider,
      child: const MaterialApp(home: MyFeesScreen()),
    );

void main() {
  late _MockFeeRepository feeRepository;
  late _MockPaymentRepository paymentRepository;
  late _MockStudentRepository studentRepository;

  setUp(() {
    feeRepository = _MockFeeRepository();
    paymentRepository = _MockPaymentRepository();
    studentRepository = _MockStudentRepository();
  });

  testWidgets('success state shows the summary and fee title after resolving own profile', (tester) async {
    when(() => studentRepository.getMyProfile()).thenAnswer((_) async => const Result.success(_me));
    when(() => feeRepository.getStudentFees('s1'))
        .thenAnswer((_) async => const Result.success((_summary, null, [_fee1])));
    when(() => paymentRepository.getMyPayments()).thenAnswer((_) async => const Result.success(<FeePayment>[]));
    final provider = SelfFeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    // "Rs 5000" now legitimately appears twice: once in the summary's Total
    // Due stat card, once on the itemized fee row itself (same amount in
    // this fixture).
    expect(find.text('Rs 5000'), findsNWidgets(2));
    expect(find.text('Term 1 Fee'), findsOneWidget);
  });

  testWidgets('pay flow: expand fee -> tap Pay -> submit -> calls submitFeePayment', (tester) async {
    when(() => studentRepository.getMyProfile()).thenAnswer((_) async => const Result.success(_me));
    when(() => feeRepository.getStudentFees('s1'))
        .thenAnswer((_) async => const Result.success((_summary, null, [_fee1])));
    when(() => paymentRepository.getMyPayments()).thenAnswer((_) async => const Result.success(<FeePayment>[]));
    when(() => paymentRepository.submitFeePayment(
          feeId: any(named: 'feeId'),
          installmentId: any(named: 'installmentId'),
          phoneNumber: any(named: 'phoneNumber'),
          transactionPin: any(named: 'transactionPin'),
        )).thenAnswer((_) async => const Result.success(FeePayment(
          id: 'p1',
          feeId: 'f1',
          feeTitle: 'Term 1 Fee',
          installmentId: null,
          studentId: 's1',
          studentAdmissionNumber: 'ADM001',
          submittedByName: 'Sam Student',
          amount: 5000,
          method: 'esewa',
          phoneNumber: '9800000000',
          transactionPin: 'ABC123',
          status: 'pending',
          rejectionNote: null,
          reviewedAt: null,
          createdAt: '2026-08-24T00:00:00.000Z',
        )));
    final provider = SelfFeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ExpansionTile));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pay'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AlertDialog, 'Submit Payment'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Phone number'), '9800000000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Transaction PIN / reference code'), 'ABC123');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    verify(() => paymentRepository.submitFeePayment(
          feeId: 'f1',
          installmentId: null,
          phoneNumber: '9800000000',
          transactionPin: 'ABC123',
        )).called(1);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

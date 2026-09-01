import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/fees/data/models/fee_payment.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository.dart';
import 'package:cloud_lms/features/fees/data/repositories/payment_repository.dart';
import 'package:cloud_lms/features/fees/presentation/providers/fee_provider.dart';
import 'package:cloud_lms/features/fees/presentation/screens/payment_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockFeeRepository extends Mock implements FeeRepository {}

class _MockPaymentRepository extends Mock implements PaymentRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

const _payment1 = FeePayment(
  id: 'p1',
  feeId: 'f1',
  feeTitle: 'Term 1 Fee',
  installmentId: null,
  studentId: 's1',
  studentAdmissionNumber: 'ADM001',
  submittedByName: 'Pat Parent',
  amount: 5000,
  method: 'esewa',
  phoneNumber: '9800000000',
  transactionPin: 'ABC123',
  status: 'pending',
  rejectionNote: null,
  reviewedAt: null,
  createdAt: '2026-08-24T00:00:00.000Z',
);

Widget _wrap(FeeProvider provider) => ChangeNotifierProvider<FeeProvider>.value(
      value: provider,
      child: const MaterialApp(home: PaymentReviewScreen()),
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

  testWidgets('pending queue: empty state shows nothing-to-review message', (tester) async {
    when(() => paymentRepository.getPendingPayments()).thenAnswer((_) async => const Result.success([]));
    final provider = FeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('No pending payments to review'), findsOneWidget);
  });

  testWidgets('pending queue: approve flow removes the card and calls approvePayment', (tester) async {
    when(() => paymentRepository.getPendingPayments()).thenAnswer((_) async => const Result.success([_payment1]));
    when(() => paymentRepository.approvePayment(any())).thenAnswer((_) async => const Result.success(_payment1));
    final provider = FeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.text('Term 1 Fee'), findsOneWidget);
    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    verify(() => paymentRepository.approvePayment('p1')).called(1);
    expect(find.text('Term 1 Fee'), findsNothing);
  });

  testWidgets('switching to the History segment loads and shows full payment history', (tester) async {
    when(() => paymentRepository.getPendingPayments()).thenAnswer((_) async => const Result.success([]));
    when(() => paymentRepository.getPaymentHistory()).thenAnswer((_) async => const Result.success([_payment1]));
    final provider = FeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(find.text('Term 1 Fee'), findsOneWidget);
    verify(() => paymentRepository.getPaymentHistory()).called(1);
  });
}

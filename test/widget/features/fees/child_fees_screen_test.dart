import 'dart:async';

import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/fees/data/models/fee.dart';
import 'package:cloud_lms/features/fees/data/models/fee_payment.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository.dart';
import 'package:cloud_lms/features/fees/data/repositories/payment_repository.dart';
import 'package:cloud_lms/features/fees/presentation/providers/self_fee_provider.dart';
import 'package:cloud_lms/features/fees/presentation/screens/child_fees_screen.dart';
import 'package:cloud_lms/shared/widgets/filter_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockFeeRepository extends Mock implements FeeRepository {}

class _MockPaymentRepository extends Mock implements PaymentRepository {}

class _MockStudentRepository extends Mock implements StudentRepository {}

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

const _student2 = Student(
  id: 's2',
  fullName: 'Alex Other',
  email: 'alex@test.dev',
  admissionNumber: 'ADM002',
  rollNumber: '2',
  className: 'Class 9',
  section: 'B',
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
      child: const MaterialApp(home: ChildFeesScreen()),
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

  testWidgets('loading state shows a progress indicator', (tester) async {
    when(() => feeRepository.getMyChildren()).thenAnswer((_) => Completer<Result<List<Student>>>().future);
    final provider = SelfFeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('a single child auto-loads fees with no selector chips shown', (tester) async {
    when(() => feeRepository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1]));
    when(() => feeRepository.getStudentFees('s1'))
        .thenAnswer((_) async => const Result.success((_summary, null, [_fee1])));
    when(() => paymentRepository.getMyPayments()).thenAnswer((_) async => const Result.success(<FeePayment>[]));
    final provider = SelfFeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byType(AppFilterChip), findsNothing);
    expect(find.text('Term 1 Fee'), findsOneWidget);
  });

  testWidgets('multiple children prompt a selection, then load the tapped child\'s fees', (tester) async {
    when(() => feeRepository.getMyChildren()).thenAnswer((_) async => const Result.success([_student1, _student2]));
    when(() => feeRepository.getStudentFees(any()))
        .thenAnswer((_) async => const Result.success((_summary, null, [_fee1])));
    when(() => paymentRepository.getMyPayments()).thenAnswer((_) async => const Result.success(<FeePayment>[]));
    final provider = SelfFeeProvider(feeRepository, paymentRepository, studentRepository);

    await tester.pumpWidget(_wrap(provider));
    await tester.pumpAndSettle();

    expect(find.byType(AppFilterChip), findsNWidgets(2));
    expect(find.text('Select a child above to view their fees'), findsOneWidget);

    await tester.tap(find.widgetWithText(AppFilterChip, 'Alex Other'));
    await tester.pumpAndSettle();

    verify(() => feeRepository.getStudentFees('s2')).called(1);
    expect(find.text('Term 1 Fee'), findsOneWidget);
  });
}

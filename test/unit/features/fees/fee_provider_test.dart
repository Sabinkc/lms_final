import 'dart:typed_data';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/fees/data/models/fee.dart';
import 'package:cloud_lms/features/fees/data/models/fee_payment.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository.dart';
import 'package:cloud_lms/features/fees/data/repositories/payment_repository.dart';
import 'package:cloud_lms/features/fees/presentation/providers/fee_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

void main() {
  late _MockFeeRepository feeRepository;
  late _MockPaymentRepository paymentRepository;
  late _MockStudentRepository studentRepository;
  late FeeProvider provider;

  setUp(() {
    feeRepository = _MockFeeRepository();
    paymentRepository = _MockPaymentRepository();
    studentRepository = _MockStudentRepository();
    provider = FeeProvider(feeRepository, paymentRepository, studentRepository);
  });

  test('loadFees(): success populates fees', () async {
    when(() => feeRepository.getFees(status: any(named: 'status'))).thenAnswer((_) async => const Result.success([_fee1]));

    await provider.loadFees();

    expect(provider.status, LoadStatus.success);
    expect(provider.fees, [_fee1]);
  });

  test('createFee(): success prepends the new fee and returns true', () async {
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

    final succeeded = await provider.createFee(studentId: 's1', title: 'Term 1 Fee', totalAmount: 5000);

    expect(succeeded, isTrue);
    expect(provider.fees, [_fee1]);
  });

  test('createFee(): failure surfaces the action error and leaves the list untouched', () async {
    when(() => feeRepository.createFee(
          studentId: any(named: 'studentId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          totalAmount: any(named: 'totalAmount'),
          discountPercent: any(named: 'discountPercent'),
          dueDate: any(named: 'dueDate'),
          isInstallment: any(named: 'isInstallment'),
          installments: any(named: 'installments'),
        )).thenAnswer((_) async => const Result.failure(ValidationException('totalAmount is required')));

    final succeeded = await provider.createFee(studentId: 's1', title: 'Term 1 Fee', totalAmount: 5000);

    expect(succeeded, isFalse);
    expect(provider.fees, isEmpty);
    expect(provider.actionError?.message, contains('totalAmount'));
  });

  test('deleteFee(): success removes it from the list', () async {
    when(() => feeRepository.getFees(status: any(named: 'status'))).thenAnswer((_) async => const Result.success([_fee1]));
    await provider.loadFees();
    when(() => feeRepository.deleteFee(any())).thenAnswer((_) async => const Result.success(null));

    final succeeded = await provider.deleteFee('f1');

    expect(succeeded, isTrue);
    expect(provider.fees, isEmpty);
  });

  test('loadStudentOptions(): populates studentOptions for the fee-form picker', () async {
    const student = Student(
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
    when(() => studentRepository.getStudents(className: any(named: 'className'), section: any(named: 'section')))
        .thenAnswer((_) async => const Result.success([student]));

    await provider.loadStudentOptions();

    expect(provider.studentOptions, [student]);
  });

  test('loadPendingPayments(): success populates the review queue', () async {
    when(() => paymentRepository.getPendingPayments()).thenAnswer((_) async => const Result.success([_payment1]));

    await provider.loadPendingPayments();

    expect(provider.pendingStatus, LoadStatus.success);
    expect(provider.pendingPayments, [_payment1]);
  });

  test('approvePayment(): success removes it from the pending queue and returns true', () async {
    when(() => paymentRepository.getPendingPayments()).thenAnswer((_) async => const Result.success([_payment1]));
    await provider.loadPendingPayments();
    when(() => paymentRepository.approvePayment(any())).thenAnswer((_) async => const Result.success(_payment1));

    final succeeded = await provider.approvePayment('p1');

    expect(succeeded, isTrue);
    expect(provider.pendingPayments, isEmpty);
  });

  test('rejectPayment(): failure leaves the queue untouched and surfaces the action error', () async {
    when(() => paymentRepository.getPendingPayments()).thenAnswer((_) async => const Result.success([_payment1]));
    await provider.loadPendingPayments();
    when(() => paymentRepository.rejectPayment(any(), note: any(named: 'note')))
        .thenAnswer((_) async => const Result.failure(ServerException('Payment is already approved')));

    final succeeded = await provider.rejectPayment('p1', note: 'test');

    expect(succeeded, isFalse);
    expect(provider.pendingPayments, [_payment1]);
    expect(provider.paymentActionError?.message, contains('already approved'));
  });

  test('loadHistory(): success populates full payment history', () async {
    when(() => paymentRepository.getPaymentHistory()).thenAnswer((_) async => const Result.success([_payment1]));

    await provider.loadHistory();

    expect(provider.historyStatus, LoadStatus.success);
    expect(provider.history, [_payment1]);
  });

  test('exportFees(): success returns the bytes', () async {
    final bytes = Uint8List.fromList([1, 2, 3]);
    when(() => feeRepository.exportFees(status: any(named: 'status'))).thenAnswer((_) async => Result.success(bytes));

    final result = await provider.exportFees(status: 'pending');

    expect(result, bytes);
    expect(provider.isDownloading, isFalse);
    expect(provider.downloadError, isNull);
  });

  test('exportFees(): failure surfaces the error and returns null', () async {
    when(() => feeRepository.exportFees(status: any(named: 'status')))
        .thenAnswer((_) async => const Result.failure(ServerException('Export failed')));

    final result = await provider.exportFees();

    expect(result, isNull);
    expect(provider.downloadError?.message, contains('Export failed'));
  });
}

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/data/models/student.dart';
import 'package:cloud_lms/features/admin_management/data/repositories/student_repository.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/fees/data/models/fee.dart';
import 'package:cloud_lms/features/fees/data/models/fee_payment.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository.dart';
import 'package:cloud_lms/features/fees/data/repositories/payment_repository.dart';
import 'package:cloud_lms/features/fees/presentation/providers/self_fee_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

const _payment1 = FeePayment(
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
);

void main() {
  late _MockFeeRepository feeRepository;
  late _MockPaymentRepository paymentRepository;
  late _MockStudentRepository studentRepository;
  late SelfFeeProvider provider;

  setUp(() {
    feeRepository = _MockFeeRepository();
    paymentRepository = _MockPaymentRepository();
    studentRepository = _MockStudentRepository();
    provider = SelfFeeProvider(feeRepository, paymentRepository, studentRepository);
  });

  test('loadOwnFees(): resolves the caller\'s own Student._id first, then loads its fees + payments', () async {
    when(() => studentRepository.getMyProfile()).thenAnswer((_) async => const Result.success(_me));
    when(() => feeRepository.getStudentFees('s1')).thenAnswer((_) async => const Result.success((_summary, null, [_fee1])));
    when(() => paymentRepository.getMyPayments()).thenAnswer((_) async => const Result.success([_payment1]));

    await provider.loadOwnFees();

    expect(provider.feesStatus, LoadStatus.success);
    expect(provider.fees, [_fee1]);
    expect(provider.summary, _summary);
    expect(provider.myPayments, [_payment1]);
  });

  test('loadOwnFees(): a failed profile lookup surfaces as a fees error, never calls getStudentFees', () async {
    when(() => studentRepository.getMyProfile()).thenAnswer((_) async => const Result.failure(NetworkException()));

    await provider.loadOwnFees();

    expect(provider.feesStatus, LoadStatus.error);
    verifyNever(() => feeRepository.getStudentFees(any()));
  });

  test('loadChildren(): auto-selects and loads fees when there is exactly one linked child', () async {
    when(() => feeRepository.getMyChildren()).thenAnswer((_) async => const Result.success([_me]));
    when(() => feeRepository.getStudentFees('s1')).thenAnswer((_) async => const Result.success((_summary, null, [_fee1])));
    when(() => paymentRepository.getMyPayments()).thenAnswer((_) async => const Result.success(<FeePayment>[]));

    await provider.loadChildren();

    expect(provider.children, [_me]);
    expect(provider.selectedChildId, 's1');
    expect(provider.feesStatus, LoadStatus.success);
  });

  test('loadChildren(): more than one child does not auto-select', () async {
    const secondChild = Student(
      id: 's2',
      fullName: 'Other Student',
      email: 'other@test.dev',
      admissionNumber: 'ADM002',
      rollNumber: '2',
      className: 'Class 10',
      section: 'A',
      parentId: null,
      dob: '',
      address: '',
      phone: '',
      status: 'active',
    );
    when(() => feeRepository.getMyChildren()).thenAnswer((_) async => const Result.success([_me, secondChild]));

    await provider.loadChildren();

    expect(provider.children, hasLength(2));
    expect(provider.selectedChildId, isNull);
    verifyNever(() => feeRepository.getStudentFees(any()));
  });

  test('submitPayment(): success adds the new payment and returns true', () async {
    when(() => paymentRepository.submitFeePayment(
          feeId: any(named: 'feeId'),
          installmentId: any(named: 'installmentId'),
          phoneNumber: any(named: 'phoneNumber'),
          transactionPin: any(named: 'transactionPin'),
        )).thenAnswer((_) async => const Result.success(_payment1));

    final succeeded =
        await provider.submitPayment(feeId: 'f1', phoneNumber: '9800000000', transactionPin: 'ABC123');

    expect(succeeded, isTrue);
    expect(provider.myPayments, [_payment1]);
  });

  test('submitPayment(): failure surfaces the action error and does not add a payment', () async {
    when(() => paymentRepository.submitFeePayment(
          feeId: any(named: 'feeId'),
          installmentId: any(named: 'installmentId'),
          phoneNumber: any(named: 'phoneNumber'),
          transactionPin: any(named: 'transactionPin'),
        )).thenAnswer((_) async => const Result.failure(
            ServerException('A payment with this phone number and transaction PIN has already been submitted')));

    final succeeded =
        await provider.submitPayment(feeId: 'f1', phoneNumber: '9800000000', transactionPin: 'ABC123');

    expect(succeeded, isFalse);
    expect(provider.myPayments, isEmpty);
    expect(provider.paymentActionError?.message, contains('already been submitted'));
  });

  test('paymentFor(): matches on both feeId and installmentId, distinguishing null from a set id', () async {
    when(() => studentRepository.getMyProfile()).thenAnswer((_) async => const Result.success(_me));
    when(() => feeRepository.getStudentFees('s1')).thenAnswer((_) async => const Result.success((_summary, null, [_fee1])));
    when(() => paymentRepository.getMyPayments()).thenAnswer((_) async => const Result.success([_payment1]));
    await provider.loadOwnFees();

    expect(provider.paymentFor(feeId: 'f1', installmentId: null)?.id, 'p1');
    expect(provider.paymentFor(feeId: 'f1', installmentId: 'inst-1'), isNull);
    expect(provider.paymentFor(feeId: 'other-fee', installmentId: null), isNull);
  });
}

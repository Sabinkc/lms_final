import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/fees/data/repositories/payment_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late PaymentRepositoryHttp repository;

  setUp(() {
    fakeAdapter = FakeHttpClientAdapter();
    final secureStorage = _MockSecureStorageService();
    when(() => secureStorage.readAccessToken()).thenAnswer((_) async => 'access-token');

    final dio = Dio()..httpClientAdapter = fakeAdapter;
    final apiClient = ApiClient(
      env: const EnvConfig(environment: AppEnvironment.dev, baseUrl: 'http://test.local', verboseLogging: false),
      secureStorage: secureStorage,
      dio: dio,
    );

    repository = PaymentRepositoryHttp(apiClient);
  });

  test('submitFeePayment(): posts feeId/installmentId/phoneNumber/transactionPin, no method field', () async {
    fakeAdapter.when(
      '/payments/fee/submit',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'p1',
          'feeId': 'f1',
          'studentId': 's1',
          'amount': 5000,
          'method': 'esewa',
          'phoneNumber': '9800000000',
          'transactionPin': 'ABC123',
          'status': 'pending',
          'createdAt': '2026-08-24T00:00:00.000Z',
        },
      }, 201),
    );

    final result =
        await repository.submitFeePayment(feeId: 'f1', phoneNumber: '9800000000', transactionPin: 'ABC123');

    result.when(
      success: (payment) {
        expect(payment.status, 'pending');
        expect(payment.method, 'esewa');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getPendingPayments(): parses populated feeId/studentId/submittedBy', () async {
    fakeAdapter.when(
      '/payments/fee/pending',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'p1',
            'feeId': {'_id': 'f1', 'title': 'Term 1 Fee'},
            'studentId': {'_id': 's1', 'admissionNumber': 'ADM001'},
            'submittedBy': {'fullName': 'Pat Parent', 'email': 'pat@test.dev'},
            'amount': 5000,
            'method': 'esewa',
            'phoneNumber': '9800000000',
            'transactionPin': 'ABC123',
            'status': 'pending',
            'createdAt': '2026-08-24T00:00:00.000Z',
          },
        ],
      }, 200),
    );

    final result = await repository.getPendingPayments();

    result.when(
      success: (payments) {
        expect(payments.single.feeTitle, 'Term 1 Fee');
        expect(payments.single.submittedByName, 'Pat Parent');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('approvePayment(): posts to /payments/fee/approve/:id', () async {
    fakeAdapter.when(
      '/payments/fee/approve/p1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'p1',
          'feeId': 'f1',
          'studentId': 's1',
          'amount': 5000,
          'method': 'esewa',
          'phoneNumber': '9800000000',
          'transactionPin': 'ABC123',
          'status': 'approved',
          'createdAt': '2026-08-24T00:00:00.000Z',
        },
      }, 200),
    );

    final result = await repository.approvePayment('p1');

    result.when(
      success: (payment) => expect(payment.status, 'approved'),
      failure: (_) => fail('expected success'),
    );
  });

  test('rejectPayment(): posts an optional note to /payments/fee/reject/:id', () async {
    fakeAdapter.when(
      '/payments/fee/reject/p1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'p1',
          'feeId': 'f1',
          'studentId': 's1',
          'amount': 5000,
          'method': 'esewa',
          'phoneNumber': '9800000000',
          'transactionPin': 'ABC123',
          'status': 'rejected',
          'rejectionNote': 'No matching transaction found',
          'createdAt': '2026-08-24T00:00:00.000Z',
        },
      }, 200),
    );

    final result = await repository.rejectPayment('p1', note: 'No matching transaction found');

    result.when(
      success: (payment) => expect(payment.rejectionNote, 'No matching transaction found'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getMyPayments(): parses the caller\'s own submissions', () async {
    fakeAdapter.when(
      '/payments/my-payments',
      (_) => jsonResponseBody({
        'success': true,
        'data': [
          {
            '_id': 'p1',
            'feeId': {'_id': 'f1', 'title': 'Term 1 Fee'},
            'studentId': 's1',
            'amount': 5000,
            'method': 'esewa',
            'phoneNumber': '9800000000',
            'transactionPin': 'ABC123',
            'status': 'pending',
            'createdAt': '2026-08-24T00:00:00.000Z',
          },
        ],
      }, 200),
    );

    final result = await repository.getMyPayments();

    result.when(
      success: (payments) => expect(payments.single.feeId, 'f1'),
      failure: (_) => fail('expected success'),
    );
  });
}

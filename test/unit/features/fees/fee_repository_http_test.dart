import 'package:cloud_lms/core/config/env.dart';
import 'package:cloud_lms/core/network/api_client.dart';
import 'package:cloud_lms/core/storage/secure_storage_service.dart';
import 'package:cloud_lms/features/fees/data/repositories/fee_repository_http.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  late FakeHttpClientAdapter fakeAdapter;
  late FeeRepositoryHttp repository;

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

    repository = FeeRepositoryHttp(apiClient);
  });

  test('createFee(): posts and parses a fee with an unpopulated (bare string) studentId', () async {
    fakeAdapter.when(
      '/fees',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'f1',
          'studentId': 's1',
          'title': 'Term 1 Fee',
          'totalAmount': 5000,
          'discountPercent': 0,
          'discountAmount': 0,
          'remainingAmount': 5000,
          'dueDate': '2026-09-01',
          'isInstallment': false,
          'status': 'pending',
        },
      }, 201),
    );

    final result = await repository.createFee(studentId: 's1', title: 'Term 1 Fee', totalAmount: 5000);

    result.when(
      success: (fee) {
        expect(fee.studentId, 's1');
        expect(fee.studentName, isNull);
        expect(fee.totalAmount, 5000);
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getFees(): parses a fully-populated studentId (Admin list, name + admission number)', () async {
    fakeAdapter.when(
      '/fees',
      (_) => jsonResponseBody({
        'success': true,
        'count': 1,
        'data': [
          {
            '_id': 'f1',
            'studentId': {
              '_id': 's1',
              'admissionNumber': 'ADM001',
              'class': 'Class 10',
              'section': 'A',
              'userId': {'fullName': 'Sam Student', 'email': 'sam@test.dev'},
            },
            'title': 'Term 1 Fee',
            'totalAmount': 5000,
            'discountPercent': 0,
            'discountAmount': 0,
            'remainingAmount': 5000,
            'dueDate': '2026-09-01',
            'isInstallment': false,
            'status': 'pending',
          },
        ],
      }, 200),
    );

    final result = await repository.getFees();

    result.when(
      success: (fees) {
        expect(fees.single.studentName, 'Sam Student');
        expect(fees.single.admissionNumber, 'ADM001');
        expect(fees.single.className, 'Class 10');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getFees(): parses installments when isInstallment is true', () async {
    fakeAdapter.when(
      '/fees',
      (_) => jsonResponseBody({
        'success': true,
        'data': [
          {
            '_id': 'f1',
            'studentId': 's1',
            'title': 'Term 1 Fee',
            'totalAmount': 5000,
            'discountPercent': 0,
            'discountAmount': 0,
            'remainingAmount': 5000,
            'dueDate': '2026-10-01',
            'isInstallment': true,
            'status': 'pending',
            'installments': [
              {
                '_id': 'i1',
                'installmentNumber': 1,
                'title': '1st Installment',
                'amount': 2500,
                'dueDate': '2026-09-01',
                'paidAmount': 0,
                'status': 'pending',
              },
            ],
          },
        ],
      }, 200),
    );

    final result = await repository.getFees();

    result.when(
      success: (fees) => expect(fees.single.installments.single.title, '1st Installment'),
      failure: (_) => fail('expected success'),
    );
  });

  test('getStudentFees(): parses (summary, paymentQrUrl, fees) as one tuple', () async {
    fakeAdapter.when(
      '/fees/student/s1',
      (_) => jsonResponseBody({
        'success': true,
        'summary': {'total': 1, 'pending': 1, 'partial': 0, 'paid': 0, 'totalDue': 5000},
        'paymentQrUrl': 'https://cloudinary.test/qr.png',
        'data': [
          {
            '_id': 'f1',
            'studentId': 's1',
            'title': 'Term 1 Fee',
            'totalAmount': 5000,
            'discountPercent': 0,
            'discountAmount': 0,
            'remainingAmount': 5000,
            'dueDate': '2026-09-01',
            'isInstallment': false,
            'status': 'pending',
          },
        ],
      }, 200),
    );

    final result = await repository.getStudentFees('s1');

    result.when(
      success: (data) {
        final (summary, qrUrl, fees) = data;
        expect(summary.totalDue, 5000);
        expect(qrUrl, 'https://cloudinary.test/qr.png');
        expect(fees.single.title, 'Term 1 Fee');
      },
      failure: (_) => fail('expected success'),
    );
  });

  test('getStudentFees(): a null paymentQrUrl (school hasn\'t uploaded one) stays null, not a parse error', () async {
    fakeAdapter.when(
      '/fees/student/s1',
      (_) => jsonResponseBody({
        'success': true,
        'summary': {'total': 0, 'pending': 0, 'partial': 0, 'paid': 0, 'totalDue': 0},
        'paymentQrUrl': null,
        'data': <Object?>[],
      }, 200),
    );

    final result = await repository.getStudentFees('s1');

    result.when(
      success: (data) => expect(data.$2, isNull),
      failure: (_) => fail('expected success'),
    );
  });

  test('updateFee(): puts and parses the updated fee', () async {
    fakeAdapter.when(
      '/fees/f1',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'f1',
          'studentId': 's1',
          'title': 'Renamed Fee',
          'totalAmount': 6000,
          'discountPercent': 0,
          'discountAmount': 0,
          'remainingAmount': 6000,
          'dueDate': '2026-09-15',
          'isInstallment': false,
          'status': 'pending',
        },
      }, 200),
    );

    final result = await repository.updateFee(id: 'f1', title: 'Renamed Fee');

    result.when(
      success: (fee) => expect(fee.title, 'Renamed Fee'),
      failure: (_) => fail('expected success'),
    );
  });

  test('deleteFee(): succeeds on a bare {message} response (no data envelope)', () async {
    fakeAdapter.when('/fees/f1', (_) => jsonResponseBody({'success': true, 'message': 'Fee deleted successfully'}, 200));

    final result = await repository.deleteFee('f1');

    expect(result.isSuccess, isTrue);
  });

  test('getMyChildren(): parses Parent.students[] via the shared Student model', () async {
    fakeAdapter.when(
      '/parents/me',
      (_) => jsonResponseBody({
        'success': true,
        'data': {
          '_id': 'p1',
          'userId': {'fullName': 'Pat Parent'},
          'students': [
            {
              '_id': 's1',
              'userId': {'fullName': 'Sam Student'},
              'class': 'Class 10',
              'section': 'A',
            },
          ],
        },
      }, 200),
    );

    final result = await repository.getMyChildren();

    result.when(
      success: (children) => expect(children.single.fullName, 'Sam Student'),
      failure: (_) => fail('expected success'),
    );
  });

  test('exportFees(): returns the raw bytes', () async {
    fakeAdapter.when('/fees/export', (_) => bytesResponseBody([5, 6, 7], 200));

    final result = await repository.exportFees();

    result.when(
      success: (bytes) => expect(bytes, [5, 6, 7]),
      failure: (_) => fail('expected success'),
    );
  });

  test('exportFees(): surfaces a server failure', () async {
    fakeAdapter.when('/fees/export', (_) => jsonResponseBody({'message': 'Export failed'}, 500));

    final result = await repository.exportFees(status: 'pending');

    result.when(
      success: (_) => fail('expected failure'),
      failure: (error) => expect(error.message, isNotEmpty),
    );
  });
}

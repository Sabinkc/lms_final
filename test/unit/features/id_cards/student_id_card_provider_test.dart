import 'dart:typed_data';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/id_cards/data/repositories/id_card_repository.dart';
import 'package:cloud_lms/features/id_cards/presentation/providers/student_id_card_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockIdCardRepository extends Mock implements IdCardRepository {}

void main() {
  late _MockIdCardRepository repository;
  late StudentIdCardProvider provider;

  setUp(() {
    repository = _MockIdCardRepository();
    provider = StudentIdCardProvider(repository);
  });

  test('downloadMyIdCard(): success returns the bytes and sets status', () async {
    final bytes = Uint8List.fromList([37, 80, 68, 70]);
    when(() => repository.generateMyIdCard()).thenAnswer((_) async => Result.success(bytes));

    final result = await provider.downloadMyIdCard();

    expect(result, bytes);
    expect(provider.status, LoadStatus.success);
    expect(provider.error, isNull);
  });

  test('downloadMyIdCard(): failure surfaces the error and returns null', () async {
    when(() => repository.generateMyIdCard())
        .thenAnswer((_) async => const Result.failure(ServerException('Student profile not found')));

    final result = await provider.downloadMyIdCard();

    expect(result, isNull);
    expect(provider.status, LoadStatus.error);
    expect(provider.error?.message, 'Student profile not found');
  });
}

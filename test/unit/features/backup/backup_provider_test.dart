import 'dart:typed_data';

import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import 'package:cloud_lms/features/backup/data/repositories/backup_repository.dart';
import 'package:cloud_lms/features/backup/presentation/providers/backup_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockBackupRepository extends Mock implements BackupRepository {}

void main() {
  late _MockBackupRepository repository;
  late BackupProvider provider;

  setUp(() {
    repository = _MockBackupRepository();
    provider = BackupProvider(repository);
  });

  test('downloadSchoolBackup(): success returns the bytes and sets status', () async {
    final bytes = Uint8List.fromList([80, 75, 3, 4]);
    when(() => repository.downloadSchoolBackup()).thenAnswer((_) async => Result.success(bytes));

    final result = await provider.downloadSchoolBackup();

    expect(result, bytes);
    expect(provider.status, LoadStatus.success);
    expect(provider.error, isNull);
  });

  test('downloadSchoolBackup(): failure surfaces the error and returns null', () async {
    when(() => repository.downloadSchoolBackup())
        .thenAnswer((_) async => const Result.failure(ServerException('backup failed')));

    final result = await provider.downloadSchoolBackup();

    expect(result, isNull);
    expect(provider.status, LoadStatus.error);
    expect(provider.error?.message, contains('backup failed'));
  });
}

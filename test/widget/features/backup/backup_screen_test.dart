import 'package:cloud_lms/core/error/app_exception.dart';
import 'package:cloud_lms/core/error/result.dart';
import 'package:cloud_lms/features/backup/data/repositories/backup_repository.dart';
import 'package:cloud_lms/features/backup/presentation/providers/backup_provider.dart';
import 'package:cloud_lms/features/backup/presentation/screens/backup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class _MockBackupRepository extends Mock implements BackupRepository {}

Widget _wrap(BackupProvider provider) => ChangeNotifierProvider<BackupProvider>.value(
      value: provider,
      child: const MaterialApp(home: BackupScreen()),
    );

void main() {
  late _MockBackupRepository repository;

  setUp(() {
    repository = _MockBackupRepository();
  });

  testWidgets('shows the Run Backup action with no data loaded yet', (tester) async {
    final provider = BackupProvider(repository);

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('Run Backup'), findsOneWidget);
    expect(find.byIcon(Icons.download_outlined), findsOneWidget);
  });

  testWidgets('tapping Run Backup shows a spinner while loading', (tester) async {
    when(() => repository.downloadSchoolBackup()).thenAnswer(
      (_) => Future.delayed(const Duration(milliseconds: 50), () => const Result.failure(ServerException('slow'))),
    );
    final provider = BackupProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.tap(find.text('Run Backup'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('a failed backup shows the error message in a snackbar', (tester) async {
    when(() => repository.downloadSchoolBackup())
        .thenAnswer((_) async => const Result.failure(ServerException('Backup failed')));
    final provider = BackupProvider(repository);

    await tester.pumpWidget(_wrap(provider));
    await tester.tap(find.text('Run Backup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Backup failed'), findsOneWidget);
  });
}

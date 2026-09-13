import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/download_helper.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart'
    show LoadStatus;
import '../providers/backup_provider.dart';

/// Admin: Backup & Data (`docs/production_roadmap.md` Phase L1,
/// `implementation_backlog.md` E20) — matches the real web app's shape
/// exactly (`docs/frontend_analysis.md` §4): one "Run Backup" download
/// action, no restore, no scheduling.
class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  Future<void> _runBackup(BuildContext context, BackupProvider provider) async {
    final bytes = await provider.downloadSchoolBackup();
    if (!context.mounted) return;
    if (bytes != null) {
      final timestamp = DateTime.now().toIso8601String().replaceAll(
        RegExp(r'[:.]'),
        '-',
      );
      await saveBytesOrNotify(context, bytes, 'school-backup-$timestamp.zip');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error?.message ?? 'Failed to download backup'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BackupProvider>();
    final isLoading = provider.status == LoadStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Data')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.backup_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Download a backup of your school\'s data as a zip file.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_outlined),
                      label: const Text('Run Backup'),
                      onPressed: isLoading
                          ? null
                          : () => _runBackup(context, provider),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

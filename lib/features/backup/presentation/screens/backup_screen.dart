import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/info_strip.dart';
import '../../../../shared/widgets/page_hero_card.dart';
import '../../../../shared/widgets/section_card.dart';

import '../../../../shared/utils/download_helper.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/backup_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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
      final timestamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
      await saveBytesOrNotify(context, bytes, 'school-backup-$timestamp.zip');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error?.message ?? 'Failed to download backup')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BackupProvider>();
    final isLoading = provider.status == LoadStatus.loading;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Backup & Data'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const PageHeroCard(
              icon: Icons.cloud_download_outlined,
              title: 'School Data Backup',
              subtitle: "Download a backup of your school's data as a zip file.",
            ),
            const SizedBox(height: 14),
            const SectionCard(
              icon: Icons.info_outline,
              title: 'Before you download',
              child: Column(
                children: [
                  InfoStrip(icon: Icons.folder_zip_outlined, text: 'Saved to your device as a single .zip file'),
                  SizedBox(height: 8),
                  InfoStrip(icon: Icons.lock_outline, text: 'Admin-only download', color: Color(0xFF16A34A)),
                  SizedBox(height: 8),
                  InfoStrip(
                    icon: Icons.privacy_tip_outlined,
                    text: 'Contains personal student and staff records — store it securely',
                    color: Color(0xFFEA580C),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                icon: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
                label: const Text('Run Backup'),
                onPressed: isLoading ? null : () => _runBackup(context, provider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

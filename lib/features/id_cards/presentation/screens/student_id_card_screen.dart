import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/info_strip.dart';
import '../../../../shared/widgets/page_hero_card.dart';
import '../../../../shared/widgets/section_card.dart';

import '../../../../shared/utils/download_helper.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/student_id_card_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/app_colors.dart';

/// Student: Download Own ID Card (`docs/production_roadmap.md` Phase L6,
/// `implementation_backlog.md` E21-F2) — one button, same shape as
/// `BackupScreen`. Parent has no equivalent here: the backend's `/my` route
/// only resolves via a `Student` profile, confirmed no Parent access exists.
class StudentIdCardScreen extends StatelessWidget {
  const StudentIdCardScreen({super.key});

  Future<void> _download(BuildContext context, StudentIdCardProvider provider) async {
    final bytes = await provider.downloadMyIdCard();
    if (!context.mounted) return;
    if (bytes != null) {
      await saveBytesOrNotify(context, bytes, 'my-id-card.pdf');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.error?.message ?? 'Failed to download ID card')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentIdCardProvider>();
    final isLoading = provider.status == LoadStatus.loading;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'My ID Card'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const PageHeroCard(
              icon: Icons.badge_outlined,
              title: 'Your Student ID',
              subtitle: 'Download your official student ID card as a PDF to print or keep on your phone.',
            ),
            const SizedBox(height: 14),
            const SectionCard(
              icon: Icons.tips_and_updates_outlined,
              title: 'Good to know',
              child: Column(
                children: [
                  InfoStrip(icon: Icons.picture_as_pdf_outlined, text: 'Issued by your school as a PDF'),
                  SizedBox(height: 8),
                  InfoStrip(
                    icon: Icons.support_agent_outlined,
                    text: 'Details wrong? Ask the school office to update your record',
                    color: AppColors.warning,
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
                label: const Text('Download ID Card'),
                onPressed: isLoading ? null : () => _download(context, provider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

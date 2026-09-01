import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/download_helper.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/student_id_card_provider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error?.message ?? 'Failed to download ID card')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentIdCardProvider>();
    final isLoading = provider.status == LoadStatus.loading;

    return Scaffold(
      appBar: AppBar(title: const Text('My ID Card')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('Download your student ID card as a PDF.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: isLoading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
                label: const Text('Download ID Card'),
                onPressed: isLoading ? null : () => _download(context, provider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

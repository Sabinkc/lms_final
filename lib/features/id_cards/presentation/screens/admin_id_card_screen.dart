import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../widgets/id_badge_preview.dart';

import '../../../../shared/utils/download_helper.dart';
import '../../../admin_management/data/models/student.dart';
import '../providers/admin_id_card_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

/// Admin: Generate ID Card (`docs/production_roadmap.md` Phase L6,
/// `implementation_backlog.md` E21-F1) — pick a student (same
/// `Autocomplete<Student>` pattern `fee_form_dialog.dart` uses), then
/// generate+download the PDF. No preview step: the backend streams a
/// finished PDF directly, there's nothing to preview client-side.
class AdminIdCardScreen extends StatefulWidget {
  const AdminIdCardScreen({super.key});

  @override
  State<AdminIdCardScreen> createState() => _AdminIdCardScreenState();
}

class _AdminIdCardScreenState extends State<AdminIdCardScreen> {
  Student? _selectedStudent;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AdminIdCardProvider>();
    Future.microtask(() => provider.loadStudentOptions());
  }

  Future<void> _generate(BuildContext context, AdminIdCardProvider provider) async {
    if (_selectedStudent == null) return;
    final bytes = await provider.generateStudentIdCard(_selectedStudent!.id);
    if (!context.mounted) return;
    if (bytes != null) {
      await saveBytesOrNotify(context, bytes, 'id-card-${_selectedStudent!.admissionNumber}.pdf');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.generateError?.message ?? 'Failed to generate ID card')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminIdCardProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'ID Cards'),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'SELECT STUDENT',
                          style: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6),
                        ),
                        const Spacer(),
                        AppStatusPill(
                          label: '${provider.studentOptions.length} on roster',
                          icon: Icons.school_outlined,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<Student>(
                      displayStringForOption: (s) =>
                          s.admissionNumber.isEmpty ? s.fullName : '${s.fullName} (${s.admissionNumber})',
                      optionsBuilder: (value) {
                        if (value.text.isEmpty) return provider.studentOptions;
                        final query = value.text.toLowerCase();
                        return provider.studentOptions.where(
                          (s) =>
                              s.fullName.toLowerCase().contains(query) ||
                              s.admissionNumber.toLowerCase().contains(query),
                        );
                      },
                      onSelected: (s) => setState(() => _selectedStudent = s),
                      fieldViewBuilder: (context, controller, focusNode, onSubmit) => TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: 'Student',
                          hintText: 'Search by name or admission no.',
                          prefixIcon: const Icon(Icons.person_search_outlined),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.badge_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Badge Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_selectedStudent != null)
              IdBadgePreview(student: _selectedStudent!)
            else
              Container(
                height: 160,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl2),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: const EmptyStateView(
                  message: 'Pick a student to preview their badge',
                  icon: Icons.credit_card_outlined,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                icon: provider.isGenerating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_rounded),
                label: const Text('Generate & Download'),
                onPressed: (_selectedStudent == null || provider.isGenerating)
                    ? null
                    : () => _generate(context, provider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/info_strip.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/progress_overlay.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/school_info.dart';
import '../providers/profile_provider.dart';

/// Admin: the school's details and its logo (`GET /api/schools/me`,
/// `PUT /api/schools/me/branding`). The logo is the only school image the
/// backend stores — it's also printed on student ID cards.
class SchoolProfileScreen extends StatefulWidget {
  const SchoolProfileScreen({super.key});

  @override
  State<SchoolProfileScreen> createState() => _SchoolProfileScreenState();
}

class _SchoolProfileScreenState extends State<SchoolProfileScreen> {
  /// The backend rejects branding files over 2 MB.
  static const _maxLogoBytes = 2 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ProfileProvider>();
    Future.microtask(provider.loadSchool);
  }

  Future<void> _uploadLogo() async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['png', 'jpg', 'jpeg', 'webp']);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxLogoBytes) {
      _snack('That image is over 2 MB. Please choose a smaller one.');
      return;
    }
    final error = await runWithProgress(
      context,
      () => context.read<ProfileProvider>().uploadSchoolLogo(bytes, file.name),
      message: 'Uploading logo…',
    );
    if (mounted) _snack(error?.message ?? 'School logo updated');
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProfileProvider>();
    final school = provider.school;

    final Widget body;
    if (school == null && provider.schoolStatus == LoadStatus.error) {
      body = ErrorView(error: provider.schoolError!, onRetry: provider.loadSchool);
    } else if (school == null) {
      body = const LoadingView(message: 'Loading school…');
    } else {
      body = RefreshIndicator(
        onRefresh: () => provider.loadSchool(refresh: true),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _LogoCard(school: school, onUpload: _uploadLogo),
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.apartment_outlined,
              title: 'School details',
              child: Column(
                children: [
                  _row(context, 'Name', school.name),
                  const Divider(height: 20),
                  _row(context, 'Address', school.address ?? '—'),
                  const Divider(height: 20),
                  _row(context, 'Phone', school.phone ?? '—'),
                  const Divider(height: 20),
                  _row(context, 'Email', school.email ?? '—'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'School Profile'),
        body: body,
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _LogoCard extends StatelessWidget {
  final SchoolInfo school;
  final VoidCallback onUpload;

  const _LogoCard({required this.school, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLogo = school.logoUrl != null;
    final placeholder = Icon(Icons.add_photo_alternate_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Container(
              width: 140,
              height: 140,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: theme.dividerColor),
              ),
              child: hasLogo
                  ? Image.network(
                      school.logoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => placeholder,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : placeholder,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              school.name,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (school.slogan != null) ...[
              const SizedBox(height: 4),
              Text(school.slogan!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_outlined),
                label: Text(hasLogo ? 'Change logo' : 'Upload logo'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const InfoStrip(
              icon: Icons.photo_size_select_actual_outlined,
              text: 'PNG or JPG, up to 2 MB — square works best',
            ),
            const SizedBox(height: 8),
            const InfoStrip(
              icon: Icons.credit_card_outlined,
              text: 'Also printed on student ID cards',
              color: AppColors.success,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/page_hero_card.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_correction.dart';
import '../providers/admin_attendance_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/screens.md doesn't name this screen explicitly (it predates the
/// correction-workflow finding) — `implementation_backlog.md` E3-F6-T2:
/// "Admin: review queue — approve/reject correction requests". A real
/// request/approve/reject workflow (`/api/attendance/corrections`), not a
/// direct edit of a locked attendance record.
///
/// **Known display gap**: the backend never populates `student`/
/// `attendanceSession` on this endpoint (see `AttendanceCorrection`'s doc
/// comment) — the student/session shown below are raw ids, not names, until
/// a backend change adds population.
class AttendanceCorrectionsScreen extends StatefulWidget {
  const AttendanceCorrectionsScreen({super.key});

  @override
  State<AttendanceCorrectionsScreen> createState() => _AttendanceCorrectionsScreenState();
}

class _AttendanceCorrectionsScreenState extends State<AttendanceCorrectionsScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<AdminAttendanceProvider>();
    Future.microtask(() => provider.loadCorrections());
  }

  Future<void> _refresh() async {
    await context.read<AdminAttendanceProvider>().loadCorrections(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAttendanceProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Attendance Corrections'),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: switch (provider.correctionsStatus) {
            LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading correction requests...'),
            LoadStatus.error => ErrorView(error: provider.correctionsError!, onRetry: () => provider.loadCorrections()),
            LoadStatus.success =>
              provider.corrections.isEmpty
                  ? const EmptyStateView(message: 'No pending correction requests', icon: Icons.task_alt_outlined)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        PageHeroCard(
                          icon: Icons.rule_rounded,
                          title: 'Review Queue',
                          subtitle:
                              'Teacher requests to change a marked attendance status. Approving updates the record.',
                          color: const Color(0xFFEA580C),
                          figure: '${provider.corrections.length}',
                          figureLabel: 'Pending',
                        ),
                        const SizedBox(height: 14),
                        for (final correction in provider.corrections) ...[
                          _CorrectionCard(
                            correction: correction,
                            processing: provider.isProcessingCorrection(correction.id),
                            onApprove: () => _approve(context, provider, correction),
                            onReject: () => _reject(context, provider, correction),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ],
                    ),
          },
        ),
      ),
    );
  }
}

Future<void> _approve(BuildContext context, AdminAttendanceProvider provider, AttendanceCorrection correction) async {
  final succeeded = await provider.approveCorrection(correction.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.correctionActionError?.message ?? 'Failed to approve correction')));
  }
}

Future<void> _reject(BuildContext context, AdminAttendanceProvider provider, AttendanceCorrection correction) async {
  final succeeded = await provider.rejectCorrection(correction.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(provider.correctionActionError?.message ?? 'Failed to reject correction')));
  }
}

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'present' => const Color(0xFF16A34A),
  'absent' => AppColors.danger,
  'late' => const Color(0xFFEA580C),
  _ => AppColors.info,
};

class _CorrectionCard extends StatelessWidget {
  final AttendanceCorrection correction;
  final bool processing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _CorrectionCard({
    required this.correction,
    required this.processing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStudent = correction.targetType.toLowerCase().contains('student');
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Icon(
                    isStudent ? Icons.person_outline : Icons.fact_check_outlined,
                    color: context.readable(AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        correction.targetType,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (correction.studentId != null)
                        Text(
                          'Student ID: ${correction.studentId}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const AppStatusPill(label: 'Pending', icon: Icons.schedule, color: Color(0xFFEA580C)),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  Text('STATUS SHIFT', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  AppStatusPill(label: _capitalize(correction.oldStatus), color: _statusColor(correction.oldStatus)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded, size: 16),
                  ),
                  AppStatusPill(label: _capitalize(correction.newStatus), color: _statusColor(correction.newStatus)),
                ],
              ),
            ),
            if (correction.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.format_quote_rounded, size: 18, color: context.readable(AppColors.info)),
                    const SizedBox(width: 6),
                    Expanded(child: Text(correction.reason, style: theme.textTheme.bodyMedium)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Color.alphaBlend(
                        theme.colorScheme.error.withValues(alpha: 0.1),
                        theme.colorScheme.surface,
                      ),
                      foregroundColor: theme.colorScheme.error,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: processing ? null : onReject,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: processing ? null : onApprove,
                    icon: processing
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

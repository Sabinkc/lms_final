import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_correction.dart';
import '../providers/admin_attendance_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminAttendanceProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Attendance Corrections'),
        body: switch (provider.correctionsStatus) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading correction requests...'),
          LoadStatus.error => ErrorView(error: provider.correctionsError!, onRetry: () => provider.loadCorrections()),
          LoadStatus.success =>
            provider.corrections.isEmpty
                ? const EmptyStateView(message: 'No pending correction requests', icon: Icons.task_alt_outlined)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    itemCount: provider.corrections.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final correction = provider.corrections[index];
                      final processing = provider.isProcessingCorrection(correction.id);
                      final accent = Theme.of(context).colorScheme.primary;
                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: accent.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.fact_check_outlined, color: accent, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(correction.targetType, style: Theme.of(context).textTheme.titleSmall),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  AppStatusChip(
                                    label: correction.oldStatus,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.arrow_forward, size: 14),
                                  ),
                                  AppStatusChip(label: correction.newStatus, color: accent),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Reason: ${correction.reason}'),
                              if (correction.studentId != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Student ID: ${correction.studentId}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: processing ? null : () => _reject(context, provider, correction),
                                    child: const Text('Reject'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: processing ? null : () => _approve(context, provider, correction),
                                    child: processing
                                        ? const SizedBox(
                                            height: 16,
                                            width: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Approve'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        },
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

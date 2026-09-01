import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../data/models/attendance_correction.dart';
import '../providers/admin_attendance_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Corrections')),
      body: switch (provider.correctionsStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading correction requests...'),
        LoadStatus.error => ErrorView(error: provider.correctionsError!, onRetry: () => provider.loadCorrections()),
        LoadStatus.success => provider.corrections.isEmpty
            ? const EmptyStateView(message: 'No pending correction requests', icon: Icons.task_alt_outlined)
            : ListView.builder(
                itemCount: provider.corrections.length,
                itemBuilder: (context, index) {
                  final correction = provider.corrections[index];
                  final processing = provider.isProcessingCorrection(correction.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${correction.targetType}: ${correction.oldStatus} → ${correction.newStatus}'),
                          const SizedBox(height: 4),
                          Text('Reason: ${correction.reason}'),
                          if (correction.studentId != null) ...[
                            const SizedBox(height: 4),
                            Text('Student ID: ${correction.studentId}', style: Theme.of(context).textTheme.bodySmall),
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
    );
  }
}

Future<void> _approve(BuildContext context, AdminAttendanceProvider provider, AttendanceCorrection correction) async {
  final succeeded = await provider.approveCorrection(correction.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.correctionActionError?.message ?? 'Failed to approve correction')),
    );
  }
}

Future<void> _reject(BuildContext context, AdminAttendanceProvider provider, AttendanceCorrection correction) async {
  final succeeded = await provider.rejectCorrection(correction.id);
  if (!succeeded && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.correctionActionError?.message ?? 'Failed to reject correction')),
    );
  }
}

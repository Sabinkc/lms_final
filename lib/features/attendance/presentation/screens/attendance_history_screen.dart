import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/attendance_provider.dart';

String _formatDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

/// docs/screens.md "Attendance History" (Teacher, read-only). The backend
/// requires a `date` filter on every read (`studentattendanceController.js`'s
/// `getAttendanceByDate` 400s without one) — this is "what I submitted on
/// this date," not an open-ended scrollable history, so the screen is a
/// date-picker over per-day session summaries rather than an infinite list.
class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = context.read<AttendanceProvider>();
    Future.microtask(() => provider.loadHistory(_formatDate(_date)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AttendanceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance History'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(_formatDate(_date)),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _date = picked);
                provider.loadHistory(_formatDate(picked));
              }
            },
          ),
        ],
      ),
      body: switch (provider.historyStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading history...'),
        LoadStatus.error =>
          ErrorView(error: provider.historyError!, onRetry: () => provider.loadHistory(_formatDate(_date))),
        LoadStatus.success => provider.historySessions.isEmpty
            ? const EmptyStateView(message: 'No attendance submitted on this date', icon: Icons.event_busy_outlined)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: provider.historySessions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final session = provider.historySessions[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${session.className} — ${session.section} · ${session.subject}',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              if (session.locked) const Icon(Icons.lock_outline, size: 18),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              AppStatusChip(label: '${session.presentCount} present', color: Colors.green),
                              AppStatusChip(
                                label: '${session.absentCount} absent',
                                color: Theme.of(context).colorScheme.error,
                              ),
                              AppStatusChip(label: '${session.lateCount} late', color: Colors.orange),
                              AppStatusChip(
                                label: 'of ${session.totalCount}',
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/self_attendance_provider.dart';
import '../widgets/attendance_history_body.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/screens.md "Child's Attendance" (Parent) — history + a child
/// selector when the Parent has more than one linked child. Reuses the same
/// `GET /api/attendance/student/:studentId` endpoint the Student screen
/// uses — confirmed authorized for a linked parent too
/// (`Attendance.service.js`'s `isAuthorizedForStudent`).
class ChildAttendanceScreen extends StatefulWidget {
  const ChildAttendanceScreen({super.key});

  @override
  State<ChildAttendanceScreen> createState() => _ChildAttendanceScreenState();
}

class _ChildAttendanceScreenState extends State<ChildAttendanceScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<SelfAttendanceProvider>();
    Future.microtask(() => provider.loadChildren());
  }

  Future<void> _refresh() async {
    final provider = context.read<SelfAttendanceProvider>();
    await provider.loadChildren(silent: true);
    final childId = provider.selectedChildId;
    if (childId != null) await provider.selectChild(childId, silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SelfAttendanceProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: "Child's Attendance"),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: Column(
            children: [
              if (provider.childrenStatus == LoadStatus.success && provider.children.length > 1)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppFilterChipBar<String>(
                    options: [for (final child in provider.children) child.id],
                    selected: provider.selectedChildId ?? '',
                    labelBuilder: (id) => provider.children.firstWhere((c) => c.id == id).fullName,
                    onSelected: provider.selectChild,
                  ),
                ),
              Expanded(
                child: switch (provider.childrenStatus) {
                  LoadStatus.initial || LoadStatus.loading => const LoadingView(),
                  LoadStatus.error => Center(
                    child: Text(
                      provider.childrenError!.message,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                  LoadStatus.success =>
                    provider.children.isEmpty
                        ? const Center(child: Text('No children linked to your account yet'))
                        : provider.selectedChildId == null
                        ? const EmptyStateView(
                            message: 'Select a child above to view their attendance',
                            icon: Icons.family_restroom_outlined,
                          )
                        : AttendanceHistoryBody(
                            status: provider.historyStatus,
                            history: provider.history,
                            error: provider.historyError,
                            onRetry: () {
                              final id = provider.selectedChildId;
                              if (id != null) provider.selectChild(id);
                            },
                          ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

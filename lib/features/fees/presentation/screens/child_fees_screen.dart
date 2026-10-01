import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/filter_chip_bar.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/self_fee_provider.dart';
import '../widgets/fee_history_body.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

/// docs/screens.md "Child's Fees" (Parent) — child selector + fee list,
/// same pattern as `ChildAttendanceScreen`.
class ChildFeesScreen extends StatefulWidget {
  const ChildFeesScreen({super.key});

  @override
  State<ChildFeesScreen> createState() => _ChildFeesScreenState();
}

class _ChildFeesScreenState extends State<ChildFeesScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<SelfFeeProvider>();
    Future.microtask(() => provider.loadChildren());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SelfFeeProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: "Child's Fees"),
        body: Column(
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
                LoadStatus.initial || LoadStatus.loading => const Center(child: CircularProgressIndicator()),
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
                          message: 'Select a child above to view their fees',
                          icon: Icons.family_restroom_outlined,
                        )
                      : FeeHistoryBody(provider: provider),
              },
            ),
          ],
        ),
      ),
    );
  }
}

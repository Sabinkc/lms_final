import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/self_fee_provider.dart';
import '../widgets/fee_history_body.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/pull_to_refresh.dart';

/// docs/screens.md "My Fees" (Student) — own fee list + summary + a "Pay"
/// action per unpaid fee/installment. Mirrors `MyAttendanceScreen`, except
/// resolving the caller's own `Student._id` costs an extra round trip here
/// (see `SelfFeeProvider`'s doc comment — no combined `/fees/me` endpoint).
class MyFeesScreen extends StatefulWidget {
  const MyFeesScreen({super.key});

  @override
  State<MyFeesScreen> createState() => _MyFeesScreenState();
}

class _MyFeesScreenState extends State<MyFeesScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<SelfFeeProvider>();
    Future.microtask(() => provider.loadOwnFees());
  }

  Future<void> _refresh() async {
    await context.read<SelfFeeProvider>().loadOwnFees(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SelfFeeProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'My Fees'),
        body: PullToRefresh(
          onRefresh: _refresh,
          child: FeeHistoryBody(provider: provider),
        ),
      ),
    );
  }
}

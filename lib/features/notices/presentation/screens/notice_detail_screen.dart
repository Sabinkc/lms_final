import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/utils/display_date.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/notice_provider.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';

/// docs/screens.md's Notice Detail — read-only for every role (Admin's
/// edit/delete live on the list screen's row actions, not here).
class NoticeDetailScreen extends StatefulWidget {
  final String noticeId;

  const NoticeDetailScreen({super.key, required this.noticeId});

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  @override
  void initState() {
    super.initState();
    final provider = context.read<NoticeProvider>();
    Future.microtask(() => provider.loadNoticeDetail(widget.noticeId));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NoticeProvider>();

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(title: 'Notice'),
        body: switch (provider.detailStatus) {
          LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading notice...'),
          LoadStatus.error => ErrorView(
            error: provider.detailError!,
            onRetry: () => provider.loadNoticeDetail(widget.noticeId),
          ),
          LoadStatus.success => Builder(
            builder: (context) {
              final notice = provider.currentNotice!;
              final scheme = Theme.of(context).colorScheme;
              final tint = notice.isImportant ? scheme.error : scheme.primary;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              AppStatusChip(label: notice.audience, color: scheme.secondary),
                              if (notice.isImportant) AppStatusChip(label: 'Important', color: scheme.error),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            notice.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: tint.withValues(alpha: 0.14),
                                child: Icon(Icons.account_balance, color: tint, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (notice.createdByName.isNotEmpty)
                                      Text(
                                        notice.createdByName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    Text(
                                      formatDisplayDate(notice.createdAt),
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 28),
                          Text(
                            notice.description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        },
      ),
    );
  }
}

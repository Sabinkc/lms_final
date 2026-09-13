import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../providers/notice_provider.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Notice')),
      body: switch (provider.detailStatus) {
        LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading notice...'),
        LoadStatus.error => ErrorView(
            error: provider.detailError!,
            onRetry: () => provider.loadNoticeDetail(widget.noticeId),
          ),
        LoadStatus.success => Builder(builder: (context) {
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: tint.withValues(alpha: 0.14),
                          child: Icon(notice.isImportant ? Icons.priority_high : Icons.campaign_outlined, color: tint),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notice.title, style: Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 6),
                              Text('Audience: ${notice.audience}', style: Theme.of(context).textTheme.bodySmall),
                              if (notice.createdByName.isNotEmpty)
                                Text('Posted by: ${notice.createdByName}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(notice.description),
                  ),
                ),
              ],
            );
          }),
      },
    );
  }
}

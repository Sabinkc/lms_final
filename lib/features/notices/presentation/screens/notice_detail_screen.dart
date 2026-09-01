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
        LoadStatus.success => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  if (provider.currentNotice!.isImportant) const Icon(Icons.priority_high, color: Colors.red),
                  Expanded(
                    child: Text(provider.currentNotice!.title, style: Theme.of(context).textTheme.headlineSmall),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Audience: ${provider.currentNotice!.audience}'),
              if (provider.currentNotice!.createdByName.isNotEmpty)
                Text('Posted by: ${provider.currentNotice!.createdByName}'),
              const SizedBox(height: 16),
              Text(provider.currentNotice!.description),
            ],
          ),
      },
    );
  }
}

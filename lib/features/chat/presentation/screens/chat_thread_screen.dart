import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../shared/utils/display_date.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/utils/relative_time.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/group_conversation.dart';
import '../../data/models/group_message.dart';
import '../providers/chat_provider.dart';
import 'manage_group_dialog.dart';
import '../../../../shared/widgets/brand_app_bar.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../../core/theme/readable_color.dart';

/// Group Thread — bubbles, compose bar, typing indicator
/// (`implementation_backlog.md` E10-F1-T2/E10-F2-T3). [group] is passed via
/// `state.extra` from the list screen (same pattern as
/// `PublishResultsScreen`) purely for the AppBar title and Manage-Group
/// action — [conversationId] alone is enough to load messages, so a
/// deep-link with no `extra` still works, just without a title/manage
/// button until the group loads some other way.
class ChatThreadScreen extends StatefulWidget {
  final String conversationId;
  final GroupConversation? group;

  const ChatThreadScreen({super.key, required this.conversationId, this.group});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  PlatformFile? _pendingAttachment;
  bool _wasTyping = false;

  // Captured once, not read again in dispose() — see
  // `ChatListScreen`'s identical doc comment for why. Nullable + reassigned
  // (not `late final`) because `didChangeDependencies` can fire more than
  // once over a State's lifetime, not just on first build.
  ChatProvider? _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = context.read<ChatProvider>();
  }

  @override
  void initState() {
    super.initState();
    final provider = context.read<ChatProvider>();
    Future.microtask(() async {
      await provider.openThread(widget.conversationId);
      _scrollToEnd();
    });
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isTyping = _textController.text.isNotEmpty;
    if (isTyping != _wasTyping) {
      _wasTyping = isTyping;
      context.read<ChatProvider>().setTyping(isTyping);
    }
  }

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _pickAttachment() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'mp4', 'mov', 'webm', '3gp'],
    );
    if (files.isEmpty) return;
    setState(() => _pendingAttachment = files.first);
  }

  Future<void> _send() async {
    final provider = context.read<ChatProvider>();
    final text = _textController.text.trim();
    final attachment = _pendingAttachment;
    if (text.isEmpty && attachment == null) return;

    final succeeded = await provider.sendMessage(
      text: text.isEmpty ? null : text,
      attachmentBytes: attachment == null ? null : await attachment.readAsBytes(),
      attachmentFilename: attachment?.name,
    );

    if (succeeded) {
      _textController.clear();
      _wasTyping = false;
      setState(() => _pendingAttachment = null);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(provider.sendError?.message ?? 'Failed to send message')));
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _provider?.closeThread();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final myUserId = context.watch<AuthProvider>().user?.id;
    final isTeacher = context.watch<AuthProvider>().role == AppRole.teacher;

    final group = widget.group;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: BrandAppBar(
          // A conversation keeps its header to the group itself — no global
          // bell/avatar competing with the member count.
          showNotifications: false,
          showAccount: false,
          titleWidget: group == null
              ? const Text('Chat')
              : Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        _groupInitials(group.className.isNotEmpty ? group.className : group.name),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            group.name,
                            style: const TextStyle(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${group.memberIds.length + group.teacherIds.length} members',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          actions: [
            if (isTeacher && widget.group != null)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Manage Group',
                onPressed: () => showManageGroupDialog(context, provider, widget.group!),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: switch (provider.messagesStatus) {
                LoadStatus.initial || LoadStatus.loading => const LoadingView(message: 'Loading messages...'),
                LoadStatus.error => ErrorView(
                  error: provider.messagesError!,
                  onRetry: () => provider.openThread(widget.conversationId),
                ),
                LoadStatus.success =>
                  provider.messages.isEmpty
                      ? const EmptyStateView(message: 'No messages yet — say hello!', icon: Icons.waving_hand_outlined)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: provider.messages.length,
                          itemBuilder: (context, index) {
                            final message = provider.messages[index];
                            final previous = index > 0 ? provider.messages[index - 1] : null;
                            final day = _dayOf(message.createdAt);
                            final showDate = day != null && (previous == null || _dayOf(previous.createdAt) != day);
                            // Consecutive messages from one sender share a single name header.
                            final showSender =
                                showDate || previous == null || previous.senderUserId != message.senderUserId;
                            return Column(
                              children: [
                                if (showDate) _DateSeparator(day: day),
                                _MessageBubble(
                                  message: message,
                                  isMine: message.senderUserId == myUserId,
                                  showSender: showSender,
                                ),
                              ],
                            );
                          },
                        ),
              },
            ),
            if (provider.typingUserNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${provider.typingUserNames.join(', ')} typing…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            if (_pendingAttachment != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Chip(
                  label: Text(_pendingAttachment!.name),
                  onDeleted: () => setState(() => _pendingAttachment = null),
                ),
              ),
            Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 6,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        tooltip: 'Attach image or video',
                        onPressed: _pickAttachment,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          decoration: InputDecoration(
                            hintText: group == null ? 'Message' : 'Message ${group.name}',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerLow,
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(24)),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: IconButton(
                          icon: provider.isSending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          tooltip: 'Send',
                          onPressed: provider.isSending ? null : _send,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _groupInitials(String source) {
  final letters = source.trim().split(RegExp(r'\s+')).first.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  return letters.length >= 2 ? letters.substring(0, 2).toUpperCase() : letters.toUpperCase();
}

/// Local calendar day of an ISO timestamp, for grouping messages.
DateTime? _dayOf(String raw) {
  final at = DateTime.tryParse(raw)?.toLocal();
  return at == null ? null : DateTime(at.year, at.month, at.day);
}

class _DateSeparator extends StatelessWidget {
  final DateTime day;

  const _DateSeparator({required this.day});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    final label = switch (diff) {
      0 => 'Today',
      1 => 'Yesterday',
      _ => formatDisplayDate(day.toIso8601String()),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl4),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMine;
  final bool showSender;

  const _MessageBubble({required this.message, required this.isMine, this.showSender = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final time = formatRelativeTime(message.createdAt);
    final role = message.senderRole.isEmpty
        ? ''
        : '${message.senderRole[0].toUpperCase()}${message.senderRole.substring(1)}';
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: maxWidth),
      decoration: BoxDecoration(
        color: isMine ? AppColors.primary : colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isMine || !showSender ? 18 : 4),
          topRight: Radius.circular(isMine && showSender ? 4 : 18),
          bottomLeft: const Radius.circular(18),
          bottomRight: const Radius.circular(18),
        ),
        boxShadow: isMine
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.attachment != null)
            Padding(
              padding: EdgeInsets.only(bottom: message.text.isNotEmpty ? 6 : 0),
              child: message.attachment!.type == 'image'
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        message.attachment!.url,
                        width: 220,
                        fit: BoxFit.cover,
                        // Decode at display size, not the photo's full resolution.
                        cacheWidth: (220 * MediaQuery.devicePixelRatioOf(context)).round(),
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 220,
                          height: 120,
                          child: Center(child: Icon(Icons.broken_image_outlined)),
                        ),
                      ),
                    )
                  : Text(
                      '📎 ${message.attachment!.type} attachment',
                      style: theme.textTheme.bodySmall?.copyWith(color: isMine ? Colors.white : null),
                    ),
            ),
          if (message.text.isNotEmpty)
            Text(message.text, style: theme.textTheme.bodyMedium?.copyWith(color: isMine ? Colors.white : null)),
        ],
      ),
    );

    final timeLabel = time.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(time, style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                if (isMine && message.readBy.length > 1) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.done_all_rounded, size: 14, color: context.readable(AppColors.primary)),
                ],
              ],
            ),
          );

    if (isMine) {
      // Align right explicitly: the list item's parent Column centres its
      // children, and this Column only spans its widest child.
      return Padding(
        padding: EdgeInsets.only(top: showSender ? 8 : 3),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [bubble, timeLabel]),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: showSender ? 10 : 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            child: showSender
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      initialsFor(message.senderName),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSender)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 2),
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          message.senderName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.readable(AppColors.primary),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (role.isNotEmpty) AppStatusPill(label: role, color: AppColors.primary),
                      ],
                    ),
                  ),
                bubble,
                timeLabel,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

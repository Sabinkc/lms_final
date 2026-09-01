import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_view.dart';
import '../../../admin_management/presentation/providers/academic_structure_provider.dart' show LoadStatus;
import '../../../auth/data/models/app_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/group_conversation.dart';
import '../../data/models/group_message.dart';
import '../providers/chat_provider.dart';
import 'manage_group_dialog.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.sendError?.message ?? 'Failed to send message')),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group?.name ?? 'Chat'),
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
              LoadStatus.error => ErrorView(error: provider.messagesError!, onRetry: () => provider.openThread(widget.conversationId)),
              LoadStatus.success => provider.messages.isEmpty
                  ? const Center(child: Text('No messages yet — say hello!'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.messages.length,
                      itemBuilder: (context, index) {
                        final message = provider.messages[index];
                        return _MessageBubble(message: message, isMine: message.senderUserId == myUserId);
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    tooltip: 'Attach image or video',
                    onPressed: _pickAttachment,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(hintText: 'Message', border: OutlineInputBorder()),
                      minLines: 1,
                      maxLines: 4,
                    ),
                  ),
                  IconButton(
                    icon: provider.isSending
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send),
                    tooltip: 'Send',
                    onPressed: provider.isSending ? null : _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final GroupMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMine ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isMine) Text(message.senderName, style: Theme.of(context).textTheme.labelSmall),
            if (message.attachment != null)
              message.attachment!.type == 'image'
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(message.attachment!.url, width: 200, fit: BoxFit.cover),
                    )
                  : Text('📎 ${message.attachment!.type} attachment', style: Theme.of(context).textTheme.bodySmall),
            if (message.text.isNotEmpty) Text(message.text),
          ],
        ),
      ),
    );
  }
}

/// Shape confirmed by reading `GroupMessageSchema.js`/
/// `groupMessageController.js` directly — `getMessages`/`sendMessage` both
/// flatten `senderUserId` to a plain id string and add a `senderName`
/// alongside it server-side (`m.senderUserId?.fullName || "Unknown"`), so
/// this model reads the flattened shape, not a nested populated object.
class GroupMessage {
  final String id;
  final String conversationId;
  final String senderRole;
  final String senderUserId;
  final String senderName;
  final String text;
  final ChatAttachment? attachment;
  final List<String> readBy;
  final String createdAt;

  const GroupMessage({
    required this.id,
    required this.conversationId,
    required this.senderRole,
    required this.senderUserId,
    required this.senderName,
    required this.text,
    required this.attachment,
    required this.readBy,
    required this.createdAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) => GroupMessage(
        id: json['_id'] as String? ?? json['id'] as String,
        conversationId: json['conversationId'] as String? ?? '',
        senderRole: json['senderRole'] as String? ?? '',
        senderUserId: json['senderUserId'] as String? ?? '',
        senderName: json['senderName'] as String? ?? 'Unknown',
        text: json['text'] as String? ?? '',
        attachment: json['attachment'] == null ? null : ChatAttachment.fromJson(json['attachment'] as Map<String, dynamic>),
        readBy: (json['readBy'] as List? ?? const []).map((e) => e as String).toList(),
        createdAt: json['createdAt'] as String? ?? '',
      );
}

/// One attachment per message — `type` is `image|video|voice`, but this app
/// only builds a picker for image/video (see `ChatComposeBar`'s doc comment
/// for why voice recording is out of scope). A message with a `voice`
/// attachment sent from elsewhere (e.g. a future web/mobile client) still
/// renders here since parsing doesn't restrict the enum.
class ChatAttachment {
  final String type;
  final String url;
  final String? thumbnailUrl;
  final int? durationSeconds;

  const ChatAttachment({required this.type, required this.url, required this.thumbnailUrl, required this.durationSeconds});

  factory ChatAttachment.fromJson(Map<String, dynamic> json) => ChatAttachment(
        type: json['type'] as String? ?? 'image',
        url: json['url'] as String? ?? '',
        thumbnailUrl: json['thumbnailUrl'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      );
}

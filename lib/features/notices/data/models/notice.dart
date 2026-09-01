/// `Notice`, confirmed against `noticeSchema.js`/`noticeController.js`.
/// Admin-only creation for v1 — `createdByModel` only enums `Admin`/`User`
/// (SuperAdmin), Teacher was never a valid creator server-side, so the
/// pre-built Teacher notice-creation screen this product doc once described
/// stays parked rather than wired to nothing.
class Notice {
  final String id;
  final String title;
  final String description;
  final String audience;
  final bool isImportant;
  final String? expiryDate;
  final String createdByName;
  final String createdAt;

  const Notice({
    required this.id,
    required this.title,
    required this.description,
    required this.audience,
    required this.isImportant,
    required this.expiryDate,
    required this.createdByName,
    required this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    final creator = json['createdBy'];
    return Notice(
      id: json['_id'] as String? ?? json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      audience: json['audience'] as String? ?? 'all',
      isImportant: json['isImportant'] as bool? ?? false,
      expiryDate: json['expiryDate'] as String?,
      createdByName: creator is Map<String, dynamic> ? creator['fullName'] as String? ?? '' : '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../utils/initials.dart';
import 'status_chip.dart';

/// Directory-row card from the Stitch "Manage Teachers/Parents" mockups:
/// coloured initials avatar, name, a status pill, one meta line, round
/// edit/delete buttons, and an optional footer (phone + a highlight pill).
/// Shared by the Admin Teachers, Parents and Departments lists.
class PersonCard extends StatelessWidget {
  final String name;
  final String? status;
  final String meta;
  final String? phone;
  final String? highlight;
  final IconData highlightIcon;

  /// Overrides the initials avatar (e.g. a department icon).
  final IconData? avatarIcon;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PersonCard({
    super.key,
    required this.name,
    this.status,
    required this.meta,
    this.phone,
    this.highlight,
    this.highlightIcon = Icons.class_outlined,
    this.avatarIcon,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  static const _palette = [
    Color(0xFF0B6E4F),
    Color(0xFF4F46E5),
    Color(0xFFEA580C),
    Color(0xFF0891B2),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _palette[name.hashCode.abs() % _palette.length];
    final active = status == null || status!.toLowerCase() == 'active';
    final statusColor = active ? const Color(0xFF16A34A) : theme.colorScheme.onSurfaceVariant;
    final hasFooter = (phone != null && phone!.isNotEmpty) || highlight != null;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: color.withValues(alpha: 0.14),
                    child: avatarIcon != null
                        ? Icon(avatarIcon, color: color)
                        : Text(
                            initialsFor(name),
                            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (status != null && status!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          AppStatusPill(
                            label: status![0].toUpperCase() + status!.substring(1),
                            icon: Icons.circle,
                            color: statusColor,
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          meta,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onEdit != null)
                    IconButton.filledTonal(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      tooltip: 'Edit',
                      visualDensity: VisualDensity.compact,
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton.filledTonal(
                      style: IconButton.styleFrom(backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1)),
                      icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                      tooltip: 'Delete',
                      visualDensity: VisualDensity.compact,
                      onPressed: onDelete,
                    ),
                ],
              ),
              if (hasFooter) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (phone != null && phone!.isNotEmpty) ...[
                      const Icon(Icons.phone_outlined, size: 15, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Text(phone!, style: theme.textTheme.bodySmall),
                    ],
                    if (phone != null && phone!.isNotEmpty) const Spacer(),
                    if (highlight != null)
                      Flexible(
                        flex: 3,
                        child: AppStatusPill(label: highlight!, icon: highlightIcon, color: AppColors.info),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

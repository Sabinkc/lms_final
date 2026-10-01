import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';

/// Badge gradients cycled by a stable hash of the class name, so a class
/// keeps its color across reloads and reorderings.
const _badgeGradients = <List<Color>>[
  [Color(0xFF2F80FF), Color(0xFF0052D4)],
  [Color(0xFFFF9A3C), Color(0xFFF2600C)],
  [Color(0xFF4CC46A), Color(0xFF239B45)],
  [Color(0xFF9B6BFF), Color(0xFF6D3FE0)],
  [Color(0xFFFFC23D), Color(0xFFF59E0B)],
  [Color(0xFF2FD1D1), Color(0xFF0EA5B7)],
  [Color(0xFFFF6B81), Color(0xFFE63958)],
  [Color(0xFFC77DFF), Color(0xFF9D4EDD)],
];

List<Color> _gradientFor(String name) {
  var hash = 0;
  for (final unit in name.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  return _badgeGradients[hash % _badgeGradients.length];
}

/// The number in the name when there is one ("Class 10" -> "10", as in the
/// reference's badges), otherwise two initials.
String classBadgeLabel(String name) {
  final trimmed = name.trim();
  final number = RegExp(r'\d+').firstMatch(trimmed)?.group(0);
  if (number != null && number.length <= 3) return number;
  if (trimmed.isEmpty) return '?';
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) return trimmed.length >= 2 ? trimmed.substring(0, 2).toUpperCase() : trimmed.toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}

/// Colorful gradient square with the class's number/initials — shared by the
/// Classes list and Class Details header.
class ClassBadge extends StatelessWidget {
  final String name;
  final double size;

  const ClassBadge({super.key, required this.name, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: _gradientFor(name)),
        borderRadius: BorderRadius.circular(size >= 64 ? AppRadius.xl3 : AppRadius.xl2),
      ),
      child: Text(
        classBadgeLabel(name),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.35),
      ),
    );
  }
}

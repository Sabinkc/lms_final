import 'package:flutter/material.dart';

/// Icon for a free-text subject name, shared by assignment cards/chips and department avatars.
IconData subjectIcon(String subject) {
  final s = subject.toLowerCase();
  if (s.contains('math')) return Icons.calculate_outlined;
  if (s.contains('science') || s.contains('physics') || s.contains('chemistry') || s.contains('bio')) {
    return Icons.science_outlined;
  }
  if (s.contains('english') || s.contains('literature') || s.contains('nepali')) return Icons.menu_book_outlined;
  if (s.contains('history') || s.contains('social')) return Icons.public_outlined;
  if (s.contains('art')) return Icons.palette_outlined;
  if (s.contains('computer') || s.contains('ict')) return Icons.computer_outlined;
  return Icons.assignment_outlined;
}

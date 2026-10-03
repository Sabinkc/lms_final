import 'package:cloud_lms/features/exams/data/models/exam.dart';
import 'package:flutter_test/flutter_test.dart';

Exam _exam(String status, DateTime date) => Exam.fromJson({
      '_id': 'e1',
      'title': 'Midterm',
      'className': 'Class 10',
      'subjects': const [],
      'examDate': date.toUtc().toIso8601String(),
      'status': status,
    });

void main() {
  final today = DateTime.now();

  test('an "upcoming" exam whose date has passed reads as completed', () {
    expect(_exam('upcoming', today.subtract(const Duration(days: 3))).status, 'completed');
  });

  test('an "upcoming" exam today or later stays upcoming', () {
    expect(_exam('upcoming', DateTime(today.year, today.month, today.day, 9)).status, 'upcoming');
    expect(_exam('upcoming', today.add(const Duration(days: 5))).status, 'upcoming');
  });

  test('other statuses are left as the server sent them', () {
    final past = today.subtract(const Duration(days: 30));
    expect(_exam('published', past).status, 'published');
    expect(_exam('ongoing', past).status, 'ongoing');
  });
}

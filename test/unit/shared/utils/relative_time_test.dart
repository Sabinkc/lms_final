import 'package:cloud_lms/shared/utils/relative_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 1, 18, 0);

  test('same day shows the clock time', () {
    expect(formatRelativeTime(DateTime(2026, 10, 1, 9, 5).toIso8601String(), now: now), '9:05 AM');
    expect(formatRelativeTime(DateTime(2026, 10, 1, 0, 30).toIso8601String(), now: now), '12:30 AM');
    expect(formatRelativeTime(DateTime(2026, 10, 1, 13, 0).toIso8601String(), now: now), '1:00 PM');
  });

  test('recent days are relative, older ones a date', () {
    expect(formatRelativeTime(DateTime(2026, 9, 30, 23).toIso8601String(), now: now), 'Yesterday');
    expect(formatRelativeTime(DateTime(2026, 9, 27).toIso8601String(), now: now), '4 days ago');
    expect(formatRelativeTime(DateTime(2026, 9, 1).toIso8601String(), now: now), '1 Sep 2026');
  });

  test('unparseable input is empty', () {
    expect(formatRelativeTime('nope', now: now), '');
  });

  test('older timestamps use the local calendar day, not the UTC one', () {
    final local = DateTime(2026, 9, 5, 2, 0); // early morning local time
    expect(formatRelativeTime(local.toUtc().toIso8601String(), now: now), '5 Sep 2026');
  });
}

import 'package:cloud_lms/shared/utils/display_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatDisplayDate', () {
    test('formats a full ISO datetime as a short readable date', () {
      expect(formatDisplayDate('2026-09-12T00:00:00.000Z'), '12 Sep 2026');
    });

    test('formats a bare date string the same way', () {
      expect(formatDisplayDate('2026-01-05'), '5 Jan 2026');
    });

    test('falls back to the raw string when it is not a parseable date', () {
      expect(formatDisplayDate('not a date'), 'not a date');
    });
  });
}

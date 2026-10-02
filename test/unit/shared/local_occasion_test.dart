import 'package:cloud_lms/shared/utils/local_occasion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Bikram Sambat date label matches the published 2083 calendar', () {
    expect(bsDateLabel(DateTime(2026, 10, 21)), '4 Kartik 2083'); // Vijaya Dashami
    expect(bsDateLabel(DateTime(2026, 4, 14)), '1 Baishakh 2083');
  });

  test('festival greetings for Dashain, Tihar and Nepali New Year; none on ordinary days', () {
    expect(festivalGreeting(DateTime(2026, 10, 3)), isNull);
    expect(festivalGreeting(DateTime(2026, 10, 11, 9)), 'Happy Dashain!');
    expect(festivalGreeting(DateTime(2026, 10, 21, 18)), 'Happy Vijaya Dashami!');
    expect(festivalGreeting(DateTime(2026, 10, 25)), 'Happy Dashain!');
    expect(festivalGreeting(DateTime(2026, 10, 26)), isNull);
    expect(festivalGreeting(DateTime(2026, 11, 8)), 'Happy Deepawali!');
    expect(festivalGreeting(DateTime(2026, 11, 11)), 'Happy Bhai Tika!');
    expect(festivalGreeting(DateTime(2027, 4, 14)), 'Happy New Year 2084!');
  });
}

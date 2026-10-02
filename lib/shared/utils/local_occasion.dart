import 'package:nepali_utils/nepali_utils.dart';

/// Bikram Sambat date for the home banner, e.g. "17 Ashwin 2083".
String bsDateLabel(DateTime date) => NepaliDateFormat('d MMMM yyyy').format(date.toNepaliDateTime());

/// A festival greeting for [now], or null on ordinary days.
///
/// Nepali New Year (Baisakh 1) is computed. Dashain and Tihar follow the
/// lunar calendar and can't be computed, so their dates are listed per year
/// below (2026 from published 2083 BS calendars). Add each new year's dates
/// here; a year that isn't listed simply shows no Dashain/Tihar greeting.
String? festivalGreeting(DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final bs = now.toNepaliDateTime();
  if (bs.month == 1 && bs.day == 1) return 'Happy New Year ${bs.year}!';
  for (final festival in _lunarFestivals) {
    if (!today.isBefore(festival.from) && !today.isAfter(festival.to)) {
      return festival.highlights[today] ?? festival.greeting;
    }
  }
  return null;
}

class _Festival {
  final DateTime from;
  final DateTime to;
  final String greeting;
  final Map<DateTime, String> highlights;

  const _Festival(this.from, this.to, this.greeting, [this.highlights = const {}]);
}

final _lunarFestivals = [
  // 2026 (2083 BS)
  _Festival(DateTime(2026, 10, 11), DateTime(2026, 10, 25), 'Happy Dashain!', {
    DateTime(2026, 10, 21): 'Happy Vijaya Dashami!',
  }),
  _Festival(DateTime(2026, 11, 6), DateTime(2026, 11, 11), 'Happy Tihar!', {
    DateTime(2026, 11, 8): 'Happy Deepawali!',
    DateTime(2026, 11, 11): 'Happy Bhai Tika!',
  }),
];

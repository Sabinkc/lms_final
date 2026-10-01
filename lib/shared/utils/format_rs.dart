import 'dart:math' as math;

/// `Rs. 24,80,000` — South-Asian digit grouping (last 3 digits, then pairs),
/// which is how amounts are read in Nepal. No `intl` dependency for one
/// format.
String formatRs(double amount) {
  final negative = amount < 0;
  final digits = amount.abs().round().toString();
  final String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final head = digits.substring(0, digits.length - 3);
    final tail = digits.substring(digits.length - 3);
    final pairs = <String>[];
    for (var i = head.length; i > 0; i -= 2) {
      pairs.insert(0, head.substring(math.max(0, i - 2), i));
    }
    grouped = '${pairs.join(',')},$tail';
  }
  return '${negative ? '-' : ''}Rs. $grouped';
}

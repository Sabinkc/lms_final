import 'package:cloud_lms/features/fees/presentation/widgets/fee_dashboard_widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatRs uses South-Asian digit grouping', () {
    expect(formatRs(0), 'Rs. 0');
    expect(formatRs(850), 'Rs. 850');
    expect(formatRs(5000), 'Rs. 5,000');
    expect(formatRs(85000), 'Rs. 85,000');
    expect(formatRs(560000), 'Rs. 5,60,000');
    expect(formatRs(2480000), 'Rs. 24,80,000');
    expect(formatRs(12345678), 'Rs. 1,23,45,678');
    expect(formatRs(4999.6), 'Rs. 5,000');
  });
}

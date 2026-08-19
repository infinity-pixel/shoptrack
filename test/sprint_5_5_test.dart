import 'package:flutter_test/flutter_test.dart';
import 'package:shoptrack/core/utils/number_formatter.dart';

void main() {
  group('Sprint 5.5: Number Formatting Tests', () {
    test('1. 999 → 999', () {
      expect(NumberFormatter.format(999), '999');
    });

    test('2. 1,000 → 1,000', () {
      expect(NumberFormatter.format(1000), '1,000');
    });

    test('3. 12,500 → 12,500', () {
      expect(NumberFormatter.format(12500), '12,500');
    });

    test('4. 2,946,875 → 2,946,875', () {
      expect(NumberFormatter.format(2946875), '2,946,875');
    });

    test('5. 294,687,500 → 294,687,500', () {
      expect(NumberFormatter.format(294687500), '294,687,500');
    });

    test('6. 5,125 pc → 5,125 pc', () {
      expect(NumberFormatter.format(5125), '5,125');
    });

    test('7. 5,125,000 pc → 5,125,000 pc', () {
      expect(NumberFormatter.format(5125000), '5,125,000');
    });

    test('8. 1.0 kg → 1 kg', () {
      expect(NumberFormatter.format(1.0), '1');
    });

    test('9. 2.50 kg → 2.5 kg', () {
      expect(NumberFormatter.format(2.50), '2.5');
    });

    test('10. 0.5 kg → 0.5 kg', () {
      expect(NumberFormatter.format(0.5), '0.5');
    });

    test('11. Price Formatting: ৳12,500', () {
      expect(NumberFormatter.formatPrice(12500), '৳12,500');
    });

    test('12. Decimal Price: ৳500.50', () {
      expect(NumberFormatter.formatPrice(500.50), '৳500.50');
    });
  });
}

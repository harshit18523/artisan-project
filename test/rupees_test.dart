import 'package:flutter_test/flutter_test.dart';
import 'package:handora/utils/rupees.dart';

void main() {
  group('formatIndianDigits', () {
    test('leaves amounts under a thousand ungrouped', () {
      expect(formatIndianDigits(0), '0');
      expect(formatIndianDigits(80), '80');
      expect(formatIndianDigits(450), '450');
    });

    test('groups thousands the same as western formatting', () {
      expect(formatIndianDigits(1250), '1,250');
      expect(formatIndianDigits(45500), '45,500');
      expect(formatIndianDigits(99999), '99,999');
    });

    test('switches to groups of two above a lakh', () {
      expect(formatIndianDigits(100000), '1,00,000');
      expect(formatIndianDigits(250000), '2,50,000');
      expect(formatIndianDigits(1000000), '10,00,000');
      expect(formatIndianDigits(10000000), '1,00,00,000');
    });

    test('handles negative amounts', () {
      expect(formatIndianDigits(-100000), '-1,00,000');
    });
  });

  test('formatRupees prefixes the rupee sign', () {
    expect(formatRupees(450), '₹450');
    expect(formatRupees(100000), '₹1,00,000');
  });
}

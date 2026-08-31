/// Indian digit grouping: the last three digits, then groups of two.
///
/// 1250 -> "1,250", 45500 -> "45,500", 100000 -> "1,00,000", 10000000 -> "1,00,00,000".
/// Western grouping would render the last two as "100,000" and "10,000,000".
String formatIndianDigits(int amount) {
  final digits = amount.abs().toString();

  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);
    // Comma after any digit followed by a whole number of 2-digit groups.
    final restGrouped = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+$)'),
      (m) => '${m[1]},',
    );
    grouped = '$restGrouped,$last3';
  }

  return amount < 0 ? '-$grouped' : grouped;
}

/// [formatIndianDigits] prefixed with the rupee sign: 100000 -> "₹1,00,000".
String formatRupees(int amount) => '₹${formatIndianDigits(amount)}';

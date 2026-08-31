import '../utils/rupees.dart';

class Order {
  final int? dbId; // auto-increment PK from SQLite
  final String id;
  final int quantity;
  final String productEn;
  final String productHi;
  final int amountInRupees;
  final String placedAt;
  final String thumbnail;
  final String status; // "new", "processing", "shipped", "delivered", "cancelled"
  final String buyerName;
  final String buyerPhone;
  final String createdAt;

  const Order({
    this.dbId,
    required this.id,
    required this.quantity,
    required this.productEn,
    required this.productHi,
    required this.amountInRupees,
    required this.placedAt,
    required this.thumbnail,
    this.status = 'new',
    this.buyerName = 'Valued Customer',
    this.buyerPhone = '919876543210',
    this.createdAt = '',
  });

  Order copyWith({
    int? dbId,
    String? id,
    int? quantity,
    String? productEn,
    String? productHi,
    int? amountInRupees,
    String? placedAt,
    String? thumbnail,
    String? status,
    String? buyerName,
    String? buyerPhone,
    String? createdAt,
  }) {
    return Order(
      dbId: dbId ?? this.dbId,
      id: id ?? this.id,
      quantity: quantity ?? this.quantity,
      productEn: productEn ?? this.productEn,
      productHi: productHi ?? this.productHi,
      amountInRupees: amountInRupees ?? this.amountInRupees,
      placedAt: placedAt ?? this.placedAt,
      thumbnail: thumbnail ?? this.thumbnail,
      status: status ?? this.status,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    if (dbId != null) 'dbId': dbId,
    'id': id,
    'quantity': quantity,
    'productEn': productEn,
    'productHi': productHi,
    'amountInRupees': amountInRupees,
    'placedAt': placedAt,
    'thumbnail': thumbnail,
    'status': status,
    'buyerName': buyerName,
    'buyerPhone': buyerPhone,
    'createdAt': createdAt,
  };

  factory Order.fromMap(Map<String, dynamic> m) => Order(
    dbId: m['dbId'] as int?,
    id: m['id'] as String,
    quantity: m['quantity'] as int,
    productEn: m['productEn'] as String,
    productHi: m['productHi'] as String,
    amountInRupees: m['amountInRupees'] as int,
    placedAt: m['placedAt'] as String,
    thumbnail: m['thumbnail'] as String,
    status: m['status'] as String? ?? 'new',
    buyerName: m['buyerName'] as String? ?? 'Valued Customer',
    buyerPhone: m['buyerPhone'] as String? ?? '919876543210',
    createdAt: m['createdAt'] as String? ?? '',
  );

  /// Formats amount: 850 -> "₹850", 1250 -> "₹1,250", 100000 -> "₹1,00,000"
  String get formattedAmount => formatRupees(amountInRupees);

  /// Clean buyer phone formatted for display (e.g. +91 98765 43210)
  String get formattedPhone {
    if (buyerPhone.startsWith('91') && buyerPhone.length == 12) {
      final p = buyerPhone.substring(2);
      return '+91 ${p.substring(0, 5)} ${p.substring(5)}';
    }
    return '+$buyerPhone';
  }
}

/// Formats a [DateTime] the way `Order.createdAt` stores it: `yyyy-MM-dd HH:mm`.
///
/// Matches what `DateTime.tryParse` expects in `ShopAnalytics.fromOrders`.
String formatOrderTimestamp(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)} '
      '${two(d.hour)}:${two(d.minute)}';
}

/// Seed data loaded into SQLite on first launch.
///
/// Timestamps are relative to when seeding happens, not fixed dates. The Growth
/// tab charts the last seven days, so hardcoded dates would drop out of that
/// window within a week and leave the chart flat while the revenue card still
/// showed their total.
List<Order> seedOrders({DateTime? now}) {
  final base = now ?? DateTime.now();
  String ago(Duration d) => formatOrderTimestamp(base.subtract(d));

  return [
    Order(
      id: 'HND-2481',
      quantity: 1,
      productEn: 'Handmade Scarf',
      productHi: 'हाथ से बुना मफलर',
      amountInRupees: 850,
      placedAt: '10 min ago',
      thumbnail: 'assets/images/scarf.jpg',
      status: 'new',
      buyerName: 'Priya Sharma',
      buyerPhone: '919876543210',
      createdAt: ago(const Duration(minutes: 10)),
    ),
    Order(
      id: 'HND-2480',
      quantity: 2,
      productEn: 'Handmade Clay Pot',
      productHi: 'हाथ से बना मिट्टी का बर्तन',
      amountInRupees: 900,
      placedAt: '2 hours ago',
      thumbnail: 'assets/images/clay_pot.jpg',
      status: 'processing',
      buyerName: 'Amit Verma',
      buyerPhone: '919812345678',
      createdAt: ago(const Duration(hours: 2)),
    ),
    Order(
      id: 'HND-2479',
      quantity: 1,
      productEn: 'Wooden Craft Toys',
      productHi: 'लकड़ी के खिलौने',
      amountInRupees: 300,
      placedAt: 'Yesterday',
      thumbnail: 'assets/images/wooden_toys.jpg',
      status: 'shipped',
      buyerName: 'Sunita Patel',
      buyerPhone: '919898989898',
      createdAt: ago(const Duration(hours: 26)),
    ),
  ];
}

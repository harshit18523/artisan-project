import '../utils/rupees.dart';

enum ProductStatus { live, draft }

class Product {
  final String id;
  final String nameEn;
  final String nameHi;
  final String description;
  final String category;
  final int priceInRupees;
  final ProductStatus status;
  final String image;
  final bool isSynced;

  /// Primary key of the matching row in Supabase, captured at insert time.
  ///
  /// Supabase may assign its own key (e.g. a serial column), in which case it
  /// differs from [id]. Cloud updates and deletes must filter on [syncKey], not
  /// on [id], or they silently match zero rows.
  final String? remoteId;

  const Product({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    this.description = '',
    this.category = 'Other',
    required this.priceInRupees,
    required this.status,
    required this.image,
    this.isSynced = true,
    this.remoteId,
  });

  /// Key identifying this product's row in Supabase.
  String get syncKey => remoteId ?? id;

  Product copyWith({
    String? id,
    String? nameEn,
    String? nameHi,
    String? description,
    String? category,
    int? priceInRupees,
    ProductStatus? status,
    String? image,
    bool? isSynced,
    String? remoteId,
  }) {
    return Product(
      id: id ?? this.id,
      nameEn: nameEn ?? this.nameEn,
      nameHi: nameHi ?? this.nameHi,
      description: description ?? this.description,
      category: category ?? this.category,
      priceInRupees: priceInRupees ?? this.priceInRupees,
      status: status ?? this.status,
      image: image ?? this.image,
      isSynced: isSynced ?? this.isSynced,
      remoteId: remoteId ?? this.remoteId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nameEn': nameEn,
    'nameHi': nameHi,
    'description': description,
    'category': category,
    'priceInRupees': priceInRupees,
    'status': status.name,
    'image': image,
    'isSynced': isSynced ? 1 : 0,
    'remoteId': remoteId,
  };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'] as String,
    nameEn: m['nameEn'] as String,
    nameHi: m['nameHi'] as String,
    description: m['description'] as String? ?? '',
    category: m['category'] as String? ?? 'Other',
    priceInRupees: m['priceInRupees'] as int,
    status: ProductStatus.values.byName(m['status'] as String),
    image: m['image'] as String,
    isSynced: (m['isSynced'] as int? ?? 1) == 1,
    remoteId: m['remoteId'] as String?,
  );

  /// Format price for display: 450 -> "₹450", 1250 -> "₹1,250", 100000 -> "₹1,00,000"
  String get formattedPrice => formatRupees(priceInRupees);
}

/// Seed data loaded into SQLite on first launch.
const kSeedProducts = <Product>[
  Product(
    id: 'p-clay-pot',
    nameEn: 'Handmade Clay Pot',
    nameHi: 'हाथ से बना मिट्टी का बर्तन',
    description: 'Traditional unglazed terracotta clay pot made by local potters.',
    category: 'Pottery',
    priceInRupees: 450,
    status: ProductStatus.live,
    image: 'assets/images/clay_pot.jpg',
    isSynced: true,
  ),
  Product(
    id: 'p-scarf',
    nameEn: 'Handmade Scarf',
    nameHi: 'हाथ से बुना मफलर',
    description: 'Soft hand-knitted woolen scarf for winter warmth.',
    category: 'Textiles',
    priceInRupees: 850,
    status: ProductStatus.live,
    image: 'assets/images/scarf.jpg',
    isSynced: true,
  ),
  Product(
    id: 'p-wooden-toys',
    nameEn: 'Wooden Craft Toys',
    nameHi: 'लकड़ी के खिलौने',
    description: 'Organic natural wood handcrafted folk toys for children.',
    category: 'Woodwork',
    priceInRupees: 300,
    status: ProductStatus.draft,
    image: 'assets/images/wooden_toys.jpg',
    isSynced: true,
  ),
];

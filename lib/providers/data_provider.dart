import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/analytics.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/database_helper.dart';
import '../services/supabase_gateway.dart';
import '../utils/rupees.dart';

/// Bridges the UI, local SQLite database, and Supabase backend.
///
/// Call [init] once at app startup to seed initial data (if first run)
/// and load everything into memory. After that, use the mutation methods
/// which write to the DB and then refresh the in-memory lists.
class DataProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  /// Supabase access, injectable so tests can exercise the sync logic without
  /// a live project. Defaults to the real implementation.
  final SupabaseGateway _cloud;

  // `_cloud` is private and a named parameter cannot start with an underscore.
  // ignore_for_file: prefer_initializing_formals
  DataProvider({SupabaseGateway cloud = const LiveSupabaseGateway()})
      : _cloud = cloud;

  List<Product> _products = [];
  List<Order> _orders = [];
  bool _initialized = false;
  bool _isProcessingAi = false;
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  List<Product> get products => _products;
  List<Order> get orders => _orders;
  List<Order> get recentOrders => _orders.take(5).toList();
  bool get initialized => _initialized;
  bool get isProcessingAi => _isProcessingAi;
  bool get isSyncing => _isSyncing;

  int get productCount => _products.length + (_isProcessingAi ? 1 : 0);
  int get activeProductCount =>
      _products.where((p) => p.status == ProductStatus.live).length;
  int get pendingSyncCount => _products.where((p) => !p.isSynced).length;
  bool get hasPendingSync => pendingSyncCount > 0;

  void setProcessingAi(bool value) {
    if (_isProcessingAi == value) return;
    _isProcessingAi = value;
    notifyListeners();
  }

  /// Sales figures for the Growth tab, derived from the current orders.
  ShopAnalytics get analytics => ShopAnalytics.fromOrders(_orders);

  Order? _pendingOrder;
  Order? _lastAcceptedOrder;

  /// An incoming order awaiting the artisan's acceptance, shown as the toast.
  Order? get pendingOrder => _pendingOrder;

  /// The most recently accepted order, shown in the shipped confirmation.
  Order? get lastAcceptedOrder => _lastAcceptedOrder;

  /// Creates an incoming order from a real catalogue product.
  ///
  /// Stands in for the ONDC order feed, which is mocked for this build (PRD §5
  /// lists "Real ONDC network API" as mocked). The order itself is genuine —
  /// accepting it writes a row to SQLite that flows through Home, the Growth
  /// figures and the WhatsApp flow like any other.
  void simulateIncomingOrder() {
    if (_pendingOrder != null || _products.isEmpty) return;

    final random = Random();
    final live = _products.where((p) => p.status == ProductStatus.live).toList();
    final pool = live.isEmpty ? _products : live;
    final source = pool[random.nextInt(pool.length)];

    const buyers = [
      ('Meera Nair', '919845012345'),
      ('Rahul Iyer', '919833011223'),
      ('Kavya Reddy', '919867045566'),
    ];
    final buyer = buyers[random.nextInt(buyers.length)];

    _pendingOrder = Order(
      id: _nextOrderId(),
      quantity: 1,
      productEn: source.nameEn,
      productHi: source.nameHi,
      amountInRupees: source.priceInRupees,
      placedAt: 'Just now',
      thumbnail: source.image,
      status: 'new',
      buyerName: buyer.$1,
      buyerPhone: buyer.$2,
      createdAt: formatOrderTimestamp(DateTime.now()),
    );
    notifyListeners();
  }

  /// Next id in the `HND-####` sequence, continuing from the highest in use.
  String _nextOrderId() {
    var highest = 2481;
    for (final o in _orders) {
      final digits = RegExp(r'(\d+)$').firstMatch(o.id)?.group(1);
      final n = digits == null ? null : int.tryParse(digits);
      if (n != null && n > highest) highest = n;
    }
    return 'HND-${highest + 1}';
  }

  /// Accepts [pendingOrder] into SQLite and surfaces the shipped confirmation.
  Future<void> acceptPendingOrder() async {
    final pending = _pendingOrder;
    if (pending == null) return;

    _pendingOrder = null;
    await addOrder(pending);

    // Re-read so the confirmation carries the row's dbId and status updates work.
    _lastAcceptedOrder =
        _orders.firstWhere((o) => o.id == pending.id, orElse: () => pending);
    notifyListeners();
  }

  void dismissShipped() {
    _lastAcceptedOrder = null;
    notifyListeners();
  }

  /// Sum of all active / non-cancelled order amounts — formatted for display.
  String get todaysSales {
    final nonCancelled = _orders.where((o) => o.status.toLowerCase() != 'cancelled');
    final total = nonCancelled.fold<int>(0, (sum, o) => sum + o.amountInRupees);
    return formatRupees(total);
  }

  /// Seeds the database on first run, then loads everything and starts network listener.
  Future<void> init() async {
    final existingProducts = await _db.queryAllProducts();
    if (existingProducts.isEmpty) {
      for (final p in kSeedProducts) {
        await _db.insertProduct(p);
      }
    }

    final existingOrders = await _db.queryAllOrders();
    if (existingOrders.isEmpty) {
      for (final o in seedOrders()) {
        await _db.insertOrder(o);
      }
    }

    await loadProducts();
    await loadOrders();
    _initialized = true;

    // Present one incoming order for the artisan to accept.
    simulateIncomingOrder();
    notifyListeners();

    // Listen to network state changes for automatic background sync
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && hasPendingSync) {
        debugPrint(
            '🌐 Network connected: Auto-syncing $pendingSyncCount pending products...');
        syncOfflineProducts();
      }
    });

    // Trigger sync if online and pending
    syncOfflineProducts();
  }

  Future<void> loadProducts() async {
    _products = await _db.queryAllProducts();
    notifyListeners();
  }

  Future<void> loadOrders() async {
    _orders = await _db.queryAllOrders();
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    await _db.insertProduct(product);
    await loadProducts();
  }

  /// Updates product details locally in SQLite and in Supabase if online.
  Future<void> updateProduct(Product product) async {
    var toSave = product;
    try {
      if (product.isSynced) {
        await _cloud.updateProduct(product);
      }
    } catch (e) {
      debugPrint('⚠️ Supabase update failed (marking product as unsynced): $e');
      toSave = product.copyWith(isSynced: false);
    }
    await _db.updateProduct(toSave);
    await loadProducts();
  }

  /// Syncs any offline / pending products to Supabase Storage and database.
  Future<void> syncOfflineProducts() async {
    if (_isSyncing) return;
    final unsynced = _products.where((p) => !p.isSynced).toList();
    if (unsynced.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    try {
      for (final p in unsynced) {
        try {
          String publicUrl = p.image;
          // If image is a local file path, upload to Supabase Storage
          if (!p.image.startsWith('http://') && !p.image.startsWith('https://')) {
            final file = File(p.image);
            if (await file.exists()) {
              publicUrl = await _cloud.uploadProductImage(file);
            }
          }

          // A product that already has a remote row got here because an edit
          // failed to reach the cloud — push the edit instead of inserting a
          // second copy of it.
          String? remoteId = p.remoteId;
          if (remoteId != null) {
            await _cloud.updateProduct(p.copyWith(image: publicUrl));
          } else {
            remoteId = await _cloud.insertProduct(
              id: p.id,
              nameEn: p.nameEn,
              nameHi: p.nameHi,
              description: p.description,
              category: p.category,
              priceInRupees: p.priceInRupees,
              imageUrl: publicUrl,
            );
          }

          // Update local SQLite record with isSynced = true, the remote public
          // URL, and the key that later cloud updates/deletes must filter on.
          final updated = p.copyWith(
            image: publicUrl,
            isSynced: true,
            remoteId: remoteId,
          );
          await _db.updateProduct(updated);
          debugPrint('✅ Synced offline product ${p.id} to Supabase');
        } catch (e) {
          debugPrint('⚠️ Sync attempt for product ${p.id} pending: $e');
        }
      }
    } finally {
      _isSyncing = false;
      await loadProducts();
    }
  }

  /// Deletes product from local SQLite and Supabase (PostgreSQL + Storage bucket), then refreshes UI.
  Future<void> deleteProduct(String id) async {
    Product? targetProduct;
    try {
      targetProduct = _products.firstWhere((p) => p.id == id);
    } catch (_) {
      targetProduct = null;
    }

    await _db.deleteProduct(id);

    try {
      await _cloud.deleteProduct(
        id: targetProduct?.syncKey ?? id,
        imageUrl: targetProduct?.image,
      );
    } catch (e) {
      debugPrint('⚠️ Supabase deletion error: $e');
    }

    await loadProducts();
  }

  /// Updates an order status in local SQLite and refreshes orders.
  Future<void> updateOrderStatus(int dbId, String status) async {
    await _db.updateOrderStatus(dbId, status);
    await loadOrders();
  }

  Future<void> addOrder(Order order) async {
    await _db.insertOrder(order);
    await loadOrders();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

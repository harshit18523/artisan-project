import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:handora/models/order.dart';
import 'package:handora/models/product.dart';
import 'package:handora/providers/data_provider.dart';
import 'package:handora/services/database_helper.dart';
import 'package:handora/services/supabase_gateway.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Records what the sync logic asked Supabase to do, and can be told to fail.
class FakeGateway implements SupabaseGateway {
  final List<String> insertedIds = [];
  final List<String> updatedKeys = [];
  final List<String> deletedKeys = [];

  /// Key Postgres "assigns" — set to something other than the client id to
  /// simulate a table with a server-generated primary key.
  String? assignedId;
  bool failUpdates = false;

  @override
  Future<String> uploadProductImage(File imageFile) async =>
      'https://cdn.example/${basename(imageFile.path)}';

  @override
  Future<String> insertProduct({
    required String id,
    required String nameEn,
    required String nameHi,
    required String description,
    required String category,
    required int priceInRupees,
    required String imageUrl,
  }) async {
    insertedIds.add(id);
    return assignedId ?? id;
  }

  @override
  Future<void> updateProduct(Product product) async {
    if (failUpdates) throw StateError('no row matched');
    updatedKeys.add(product.syncKey);
  }

  @override
  Future<void> deleteProduct({required String id, String? imageUrl}) async {
    deletedKeys.add(id);
  }
}

Product _product({
  String id = 'p-1',
  bool isSynced = false,
  String? remoteId,
  int price = 450,
}) {
  return Product(
    id: id,
    nameEn: 'Clay Pot',
    nameHi: 'मिट्टी का बर्तन',
    priceInRupees: price,
    status: ProductStatus.live,
    // An https image so sync skips the upload branch (no real file on disk).
    image: 'https://cdn.example/pot.jpg',
    isSynced: isSynced,
    remoteId: remoteId,
  );
}

void main() {
  late String dbPath;
  late FakeGateway cloud;
  late DataProvider provider;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Test files run in parallel isolates; each needs its own database file.
    DatabaseHelper.databaseName = 'handora_sync_test.db';
  });

  setUp(() async {
    dbPath = join(await getDatabasesPath(), DatabaseHelper.databaseName);
    await DatabaseHelper.instance.resetForTests();
    await databaseFactory.deleteDatabase(dbPath);
    cloud = FakeGateway();
    provider = DataProvider(cloud: cloud);
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTests();
    await databaseFactory.deleteDatabase(dbPath);
  });

  group('syncOfflineProducts', () {
    test('inserts an unsynced product once and records the remote key',
        () async {
      await provider.addProduct(_product());
      expect(provider.pendingSyncCount, 1);

      await provider.syncOfflineProducts();

      expect(cloud.insertedIds, ['p-1']);
      expect(provider.pendingSyncCount, 0);
      expect(provider.products.single.isSynced, isTrue);
      expect(provider.products.single.remoteId, 'p-1');
    });

    test('stores a server-assigned key when the table generates its own',
        () async {
      cloud.assignedId = '7';
      await provider.addProduct(_product());

      await provider.syncOfflineProducts();

      final stored = provider.products.single;
      expect(stored.remoteId, '7');
      expect(stored.syncKey, '7',
          reason: 'later updates and deletes must target the server key');
    });

    test('a product that already has a remote row updates instead of '
        'inserting a duplicate', () async {
      // This is the state a failed cloud update leaves behind.
      await provider.addProduct(
        _product(isSynced: false, remoteId: 'remote-9'),
      );

      await provider.syncOfflineProducts();

      expect(cloud.insertedIds, isEmpty,
          reason: 'inserting again would duplicate the row in Supabase');
      expect(cloud.updatedKeys, ['remote-9']);
      expect(provider.products.single.isSynced, isTrue);
    });

    test('running twice does not insert the product a second time', () async {
      await provider.addProduct(_product());

      await provider.syncOfflineProducts();
      await provider.syncOfflineProducts();

      expect(cloud.insertedIds, ['p-1']);
    });

    test('a product left unsynced by a failure is retried, not lost', () async {
      cloud.assignedId = 'remote-3';
      await provider.addProduct(_product());
      await provider.syncOfflineProducts();

      // A later edit fails to reach the cloud.
      cloud.failUpdates = true;
      await provider.updateProduct(
        provider.products.single.copyWith(priceInRupees: 500),
      );
      expect(provider.products.single.isSynced, isFalse,
          reason: 'a failed cloud write must not be reported as synced');

      // When the cloud recovers, the retry updates rather than duplicating.
      cloud.failUpdates = false;
      await provider.syncOfflineProducts();

      expect(cloud.insertedIds, ['p-1'], reason: 'still just the one insert');
      expect(cloud.updatedKeys, contains('remote-3'));
      expect(provider.products.single.isSynced, isTrue);
      expect(provider.products.single.priceInRupees, 500);
    });
  });

  group('updateProduct', () {
    test('a successful cloud write keeps the product synced', () async {
      await provider.addProduct(_product(isSynced: true, remoteId: 'remote-1'));

      await provider.updateProduct(
        provider.products.single.copyWith(priceInRupees: 999),
      );

      expect(cloud.updatedKeys, ['remote-1']);
      expect(provider.products.single.isSynced, isTrue);
      expect(provider.products.single.priceInRupees, 999);
    });

    test('an unsynced product is saved locally without touching the cloud',
        () async {
      await provider.addProduct(_product(isSynced: false));

      await provider.updateProduct(
        provider.products.single.copyWith(priceInRupees: 120),
      );

      expect(cloud.updatedKeys, isEmpty);
      expect(provider.products.single.priceInRupees, 120);
      expect(provider.products.single.isSynced, isFalse);
    });
  });

  group('incoming order', () {
    test('is built from a real catalogue product', () async {
      await provider.addProduct(_product(isSynced: true));

      provider.simulateIncomingOrder();

      final pending = provider.pendingOrder;
      expect(pending, isNotNull);
      expect(pending!.productEn, 'Clay Pot',
          reason: 'must reference an actual product, not invented text');
      expect(pending.amountInRupees, 450,
          reason: 'amount must match the product price');
      expect(DateTime.tryParse(pending.createdAt), isNotNull);
    });

    test('does nothing when the catalogue is empty', () async {
      provider.simulateIncomingOrder();
      expect(provider.pendingOrder, isNull);
    });

    test('accepting writes a real order that reaches Home and Growth', () async {
      await provider.addProduct(_product(isSynced: true));
      provider.simulateIncomingOrder();
      final pending = provider.pendingOrder!;

      expect(provider.orders, isEmpty);

      await provider.acceptPendingOrder();

      expect(provider.pendingOrder, isNull, reason: 'toast should dismiss');
      expect(provider.orders.single.id, pending.id);
      expect(provider.orders.single.dbId, isNotNull,
          reason: 'must be persisted, so status updates and WhatsApp work');
      expect(provider.analytics.totalOrders, 1);
      expect(provider.analytics.totalRevenue, pending.amountInRupees,
          reason: 'the accepted order must move the Growth figures');
    });

    test('the accepted order drives the shipped confirmation', () async {
      await provider.addProduct(_product(isSynced: true));
      provider.simulateIncomingOrder();
      final pending = provider.pendingOrder!;

      await provider.acceptPendingOrder();

      expect(provider.lastAcceptedOrder?.id, pending.id);
      expect(provider.lastAcceptedOrder?.buyerName, pending.buyerName);

      provider.dismissShipped();
      expect(provider.lastAcceptedOrder, isNull);
    });

    test('ids continue the HND sequence rather than colliding', () async {
      await provider.addProduct(_product(isSynced: true));
      await provider.addOrder(seedOrders().first); // HND-2481
      provider.simulateIncomingOrder();

      expect(provider.pendingOrder!.id, 'HND-2482');
    });
  });

  group('deleteProduct', () {
    test('deletes from the cloud using the remote key, not the local id',
        () async {
      await provider.addProduct(_product(isSynced: true, remoteId: 'remote-5'));

      await provider.deleteProduct('p-1');

      expect(cloud.deletedKeys, ['remote-5']);
      expect(provider.products, isEmpty);
    });

    test('falls back to the local id when there is no remote row', () async {
      await provider.addProduct(_product(isSynced: false));

      await provider.deleteProduct('p-1');

      expect(cloud.deletedKeys, ['p-1']);
      expect(provider.products, isEmpty);
    });
  });
}

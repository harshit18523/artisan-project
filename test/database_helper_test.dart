import 'package:flutter_test/flutter_test.dart';
import 'package:handora/models/product.dart';
import 'package:handora/services/database_helper.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Schema as it shipped at version 2, used to prove the v2 -> v3 upgrade path.
const _v2Products = '''
  CREATE TABLE products (
    id TEXT PRIMARY KEY,
    nameEn TEXT NOT NULL,
    nameHi TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT 'Other',
    priceInRupees INTEGER NOT NULL,
    status TEXT NOT NULL,
    image TEXT NOT NULL,
    isSynced INTEGER NOT NULL DEFAULT 1,
    remoteId TEXT
  )
''';

const _v2Orders = '''
  CREATE TABLE orders (
    dbId INTEGER PRIMARY KEY AUTOINCREMENT,
    id TEXT NOT NULL,
    quantity INTEGER NOT NULL,
    productEn TEXT NOT NULL,
    productHi TEXT NOT NULL,
    amountInRupees INTEGER NOT NULL,
    placedAt TEXT NOT NULL,
    thumbnail TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'new',
    buyerName TEXT NOT NULL DEFAULT 'Valued Customer',
    buyerPhone TEXT NOT NULL DEFAULT '919876543210',
    createdAt TEXT NOT NULL DEFAULT ''
  )
''';

void main() {
  late String dbPath;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Test files run in parallel isolates; each needs its own database file.
    DatabaseHelper.databaseName = 'handora_db_helper_test.db';
  });

  setUp(() async {
    dbPath = join(await getDatabasesPath(), DatabaseHelper.databaseName);
    await DatabaseHelper.instance.resetForTests();
    await databaseFactory.deleteDatabase(dbPath);
  });

  tearDown(() async {
    await DatabaseHelper.instance.resetForTests();
    await databaseFactory.deleteDatabase(dbPath);
  });

  group('settings', () {
    test('round trips a value', () async {
      final db = DatabaseHelper.instance;

      await db.writeSetting('language', 'hi');
      expect(await db.readSetting('language'), 'hi');
    });

    test('returns null for a key that was never written', () async {
      expect(await DatabaseHelper.instance.readSetting('nope'), isNull);
    });

    test('overwrites rather than duplicating on a repeat write', () async {
      final db = DatabaseHelper.instance;

      await db.writeSetting('dark_mode', 'true');
      await db.writeSetting('dark_mode', 'false');

      expect(await db.readSetting('dark_mode'), 'false');
      expect(await db.readAllSettings(), {'dark_mode': 'false'});
    });
  });

  group('migration', () {
    test('a v2 database gains the settings table and keeps its rows', () async {
      // Build a database exactly as version 2 left it.
      final legacy = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, _) async {
            await db.execute(_v2Products);
            await db.execute(_v2Orders);
          },
        ),
      );
      await legacy.insert('products', const Product(
        id: 'p-legacy',
        nameEn: 'Legacy Pot',
        nameHi: 'पुराना बर्तन',
        priceInRupees: 450,
        status: ProductStatus.live,
        image: 'assets/images/clay_pot.jpg',
      ).toMap());
      await legacy.close();

      // Opening through DatabaseHelper triggers onUpgrade to version 3.
      final helper = DatabaseHelper.instance;
      await helper.writeSetting('language', 'hi');

      expect(await helper.readSetting('language'), 'hi',
          reason: 'settings table must exist after the upgrade');

      final products = await helper.queryAllProducts();
      expect(products, hasLength(1));
      expect(products.single.nameEn, 'Legacy Pot',
          reason: 'the upgrade must not drop existing data');
    });
  });

  group('products', () {
    test('remoteId survives a write and read', () async {
      final helper = DatabaseHelper.instance;

      await helper.insertProduct(const Product(
        id: 'p-1',
        nameEn: 'Scarf',
        nameHi: 'मफलर',
        priceInRupees: 850,
        status: ProductStatus.live,
        image: 'assets/images/scarf.jpg',
        isSynced: true,
        remoteId: 'remote-42',
      ));

      final stored = (await helper.queryAllProducts()).single;
      expect(stored.remoteId, 'remote-42');
      expect(stored.syncKey, 'remote-42');
    });

    test('syncKey falls back to the local id when there is no remote row',
        () async {
      final helper = DatabaseHelper.instance;

      await helper.insertProduct(const Product(
        id: 'p-2',
        nameEn: 'Toys',
        nameHi: 'खिलौने',
        priceInRupees: 300,
        status: ProductStatus.draft,
        image: 'assets/images/wooden_toys.jpg',
        isSynced: false,
      ));

      final stored = (await helper.queryAllProducts()).single;
      expect(stored.remoteId, isNull);
      expect(stored.syncKey, 'p-2');
    });
  });
}

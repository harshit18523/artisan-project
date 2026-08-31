import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/order.dart';

/// Singleton that manages the local SQLite database.
///
/// Usage: `final db = await DatabaseHelper.instance.database;`
const _createSettingsTable = '''
  CREATE TABLE IF NOT EXISTS settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
  )
''';

class DatabaseHelper {
  DatabaseHelper._();
  static final instance = DatabaseHelper._();

  /// File name of the SQLite database.
  ///
  /// Overridable so each test file can use its own database: the test runner
  /// executes files in separate isolates in parallel, and sharing one file
  /// makes them clobber each other.
  @visibleForTesting
  static String databaseName = 'handora.db';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  /// Closes and forgets the cached connection so the next access reopens it.
  ///
  /// Exists for tests, which need each case to start from a fresh database;
  /// without this the singleton would hold a handle to a deleted file.
  @visibleForTesting
  Future<void> resetForTests() async {
    await _db?.close();
    _db = null;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, databaseName);

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
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
        ''');

        await db.execute('''
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
        ''');

        await db.execute(_createSettingsTable);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE products ADD COLUMN remoteId TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(_createSettingsTable);
        }
      },
      // Legacy migrations: these columns predate the version counter and were
      // added in place on already-shipped v1 databases. New columns belong in
      // [onUpgrade] above, not here.
      onOpen: (db) async {
        try {
          await db.execute(
            'ALTER TABLE products ADD COLUMN isSynced INTEGER NOT NULL DEFAULT 1',
          );
        } catch (_) {}
        try {
          await db.execute(
            "ALTER TABLE products ADD COLUMN description TEXT NOT NULL DEFAULT ''",
          );
        } catch (_) {}
        try {
          await db.execute(
            "ALTER TABLE products ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'",
          );
        } catch (_) {}
        try {
          await db.execute(
            "ALTER TABLE orders ADD COLUMN buyerName TEXT NOT NULL DEFAULT 'Valued Customer'",
          );
        } catch (_) {}
        try {
          await db.execute(
            "ALTER TABLE orders ADD COLUMN buyerPhone TEXT NOT NULL DEFAULT '919876543210'",
          );
        } catch (_) {}
        try {
          await db.execute(
            "ALTER TABLE orders ADD COLUMN createdAt TEXT NOT NULL DEFAULT ''",
          );
        } catch (_) {}
      },
    );
  }

  // ── Products ──

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert('products', product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> queryAllProducts() async {
    final db = await database;
    final rows = await db.query('products');
    return rows.map(Product.fromMap).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return db.update('products', product.toMap(),
        where: 'id = ?', whereArgs: [product.id]);
  }

  Future<int> deleteProduct(String id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ── Orders ──

  Future<int> insertOrder(Order order) async {
    final db = await database;
    return db.insert('orders', order.toMap());
  }

  Future<List<Order>> queryAllOrders() async {
    final db = await database;
    final rows = await db.query('orders', orderBy: 'dbId DESC');
    return rows.map(Order.fromMap).toList();
  }

  Future<int> updateOrderStatus(int dbId, String status) async {
    final db = await database;
    return db.update('orders', {'status': status},
        where: 'dbId = ?', whereArgs: [dbId]);
  }

  Future<int> updateOrder(Order order) async {
    final db = await database;
    return db.update('orders', order.toMap(),
        where: 'dbId = ?', whereArgs: [order.dbId]);
  }

  Future<int> deleteOrder(int dbId) async {
    final db = await database;
    return db.delete('orders', where: 'dbId = ?', whereArgs: [dbId]);
  }

  // ── Settings ──
  //
  // Small key/value store for UI preferences (language, theme) so they survive
  // a restart. Kept here rather than adding a shared_preferences dependency.

  Future<String?> readSetting(String key) async {
    final db = await database;
    final rows = await db.query(
      'settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> writeSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// All settings in one read — used at startup to avoid several round trips.
  Future<Map<String, String>> readAllSettings() async {
    final db = await database;
    final rows = await db.query('settings');
    return {
      for (final r in rows) r['key'] as String: r['value'] as String,
    };
  }
}

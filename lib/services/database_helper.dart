import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/dining_order.dart';
import '../models/order_processing_log.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static late DatabaseFactory _databaseFactory;
  final _uuid = Uuid();

  DatabaseHelper._init() {
    if (kIsWeb) {
      _databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      _databaseFactory = databaseFactoryFfi;
    } else {
      _databaseFactory = sqflite.databaseFactory;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('receipts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await _databaseFactory.getDatabasesPath();
    final path = join(dbPath, filePath);

    return await _databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _createDB,
        onConfigure: _onConfigure,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> init() async {
    final migrationHelper = DatabaseMigrationHelper.instance;
    if (await migrationHelper.needsMigration()) {
      await migrationHelper.migrateData();
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 创建users表
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        email TEXT UNIQUE,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 创建orders表
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        order_type TEXT NOT NULL,
        merchant_name TEXT NOT NULL,
        platform TEXT,
        total_amount REAL NOT NULL,
        actual_paid REAL NOT NULL,
        discount_amount REAL,
        currency TEXT NOT NULL DEFAULT 'CNY',
        order_date TEXT NOT NULL,
        order_time TEXT NOT NULL,
        order_status TEXT NOT NULL DEFAULT 'pending',
        payment_method TEXT,
        payment_status TEXT,
        source_image_url TEXT,
        source_image_path TEXT,
        raw_text_content TEXT,
        recognition_status TEXT NOT NULL DEFAULT 'pending',
        error_message TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // 创建order_items表
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        name TEXT NOT NULL,
        specification TEXT,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        amount REAL NOT NULL,
        category TEXT,
        item_index INTEGER NOT NULL,
        is_valid BOOLEAN DEFAULT true,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    // 创建dining_orders表
    await db.execute('''
      CREATE TABLE dining_orders (
        order_id TEXT PRIMARY KEY,
        meal_type TEXT NOT NULL,
        estimated_diners INTEGER,
        tableware_count INTEGER,
        set_meal_count INTEGER,
        per_person_cost REAL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    // 创建order_processing_logs表
    await db.execute('''
      CREATE TABLE order_processing_logs (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        action TEXT NOT NULL,
        status TEXT NOT NULL,
        message TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');
  }

  // User operations
  Future<String> insertUser(User user) async {
    final db = await instance.database;
    await db.insert('users', user.toMap());
    return user.id;
  }

  Future<User?> getUser(String id) async {
    final db = await instance.database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  // Order operations
  Future<String> insertOrder(Order order) async {
    final db = await instance.database;
    await db.insert('orders', order.toMap());
    return order.id;
  }

  Future<Order?> getOrder(String id) async {
    final db = await instance.database;
    final maps = await db.query('orders', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Order.fromMap(maps.first);
  }

  Future<List<Order>> getOrders(String userId) async {
    final db = await instance.database;
    final maps = await db.query('orders', 
      where: 'user_id = ?', 
      whereArgs: [userId],
      orderBy: 'created_at DESC'
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  Future<void> updateOrder(Order order) async {
    final db = await instance.database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  // OrderItem operations
  Future<String> insertOrderItem(OrderItem item) async {
    final db = await instance.database;
    await db.insert('order_items', item.toMap());
    return item.id;
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final db = await instance.database;
    final maps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'item_index ASC',
    );
    return maps.map((map) => OrderItem.fromMap(map)).toList();
  }

  // DiningOrder operations
  Future<void> insertDiningOrder(DiningOrder diningOrder) async {
    final db = await instance.database;
    await db.insert('dining_orders', diningOrder.toMap());
  }

  Future<DiningOrder?> getDiningOrder(String orderId) async {
    final db = await instance.database;
    final maps = await db.query(
      'dining_orders',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    if (maps.isEmpty) return null;
    return DiningOrder.fromMap(maps.first);
  }

  // OrderProcessingLog operations
  Future<String> insertOrderProcessingLog(OrderProcessingLog log) async {
    final db = await instance.database;
    await db.insert('order_processing_logs', log.toMap());
    return log.id;
  }

  Future<List<OrderProcessingLog>> getOrderProcessingLogs(String orderId) async {
    final db = await instance.database;
    final maps = await db.query(
      'order_processing_logs',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => OrderProcessingLog.fromMap(map)).toList();
  }

  // Transaction helper
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await instance.database;
    return await db.transaction(action);
  }

  // Cleanup
  Future<void> deleteDatabase() async {
    final dbPath = await _databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'receipts.db');
    await _databaseFactory.deleteDatabase(path);
    _database = null;
  }
}

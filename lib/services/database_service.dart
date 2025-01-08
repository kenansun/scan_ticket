import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/dining_order.dart';
import '../models/order_processing_log.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  final _uuid = const Uuid();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scan_ticket.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
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
        log_type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    // 创建默认用户
    await db.insert('users', {
      'id': _uuid.v4(),
      'username': 'default_user',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  // 获取默认用户ID
  Future<String> getDefaultUserId() async {
    final db = await database;
    final result = await db.query('users', limit: 1);
    return result.first['id'] as String;
  }

  // 插入新订单
  Future<String> insertReceipt({
    required String imageUrl,
    String? title,
    String? description,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final now = DateTime.now();
    final userId = await getDefaultUserId();

    await db.insert('orders', {
      'id': id,
      'user_id': userId,
      'order_type': 'receipt',
      'merchant_name': title ?? 'Unknown Merchant',
      'total_amount': 0.0,  // 待识别
      'actual_paid': 0.0,   // 待识别
      'currency': 'CNY',
      'order_date': now.toIso8601String(),
      'order_time': now.toIso8601String().split('T')[1],
      'order_status': 'pending',
      'source_image_url': imageUrl,
      'recognition_status': 'pending',
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    return id;
  }

  // 获取所有订单
  Future<List<Order>> getAllReceipts() async {
    final db = await database;
    final maps = await db.query(
      'orders',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // 获取单个订单
  Future<Order?> getReceipt(String id) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Order.fromMap(maps.first);
    }
    return null;
  }

  // 更新订单
  Future<void> updateReceipt(Order order) async {
    final db = await database;
    await db.update(
      'orders',
      order.toMap(),
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  // 获取订单项
  Future<List<OrderItem>> getOrderItems(String orderId) async {
    final db = await database;
    final maps = await db.query(
      'order_items',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'item_index ASC',
    );
    return maps.map((map) => OrderItem.fromMap(map)).toList();
  }

  // 获取餐饮订单详情
  Future<DiningOrder?> getDiningOrder(String orderId) async {
    final db = await database;
    final maps = await db.query(
      'dining_orders',
      where: 'order_id = ?',
      whereArgs: [orderId],
    );
    if (maps.isEmpty) return null;
    return DiningOrder.fromMap(maps.first);
  }

  // 批量插入订单项
  Future<void> insertOrderItems(String orderId, List<OrderItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final item in items) {
        await txn.insert('order_items', item.toMap());
      }
    });
  }

  // 批量更新订单项
  Future<void> updateOrderItems(String orderId, List<OrderItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      // 删除旧的订单项
      await txn.delete(
        'order_items',
        where: 'order_id = ?',
        whereArgs: [orderId],
      );
      // 插入新的订单项
      for (final item in items) {
        await txn.insert('order_items', item.toMap());
      }
    });
  }

  // 更新订单状态
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'order_status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // 更新识别状态
  Future<void> updateRecognitionStatus(String orderId, RecognitionStatus status, {String? errorMessage}) async {
    final db = await database;
    await db.update(
      'orders',
      {
        'recognition_status': status.toString().split('.').last,
        if (errorMessage != null) 'error_message': errorMessage,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // 插入餐饮订单信息
  Future<void> insertOrUpdateDiningOrder(DiningOrder diningOrder) async {
    final db = await database;
    await db.insert(
      'dining_orders',
      diningOrder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 插入处理日志
  Future<String> insertProcessingLog(OrderProcessingLog log) async {
    final db = await database;
    await db.insert('order_processing_logs', log.toMap());
    return log.id;
  }

  // 获取订单的所有信息（包括订单项和餐饮信息）
  Future<Map<String, dynamic>> getCompleteOrder(String orderId) async {
    final order = await getReceipt(orderId);
    if (order == null) {
      throw Exception('Order not found');
    }

    final items = await getOrderItems(orderId);
    final diningOrder = await getDiningOrder(orderId);
    final logs = await getOrderProcessingLogs(orderId);

    return {
      'order': order,
      'items': items,
      'dining_order': diningOrder,
      'logs': logs,
    };
  }

  // 按日期范围查询订单
  Future<List<Order>> getOrdersByDateRange(String userId, DateTime startDate, DateTime endDate) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'user_id = ? AND order_date BETWEEN ? AND ?',
      whereArgs: [userId, startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'order_date DESC, order_time DESC',
    );
    return maps.map((map) => Order.fromMap(map)).toList();
  }

  // 获取订单处理日志
  Future<List<OrderProcessingLog>> getOrderProcessingLogs(String orderId) async {
    final db = await database;
    final maps = await db.query(
      'order_processing_logs',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => OrderProcessingLog.fromMap(map)).toList();
  }
}

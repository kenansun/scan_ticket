import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'database_helper.dart';
import 'database_service.dart';

class DatabaseMigrationHelper {
  static final DatabaseMigrationHelper instance = DatabaseMigrationHelper._init();
  final _uuid = const Uuid();

  DatabaseMigrationHelper._init();

  Future<void> migrateData() async {
    // 获取旧数据
    final oldService = DatabaseService.instance;
    final oldReceipts = await oldService.getAllReceipts();

    // 获取新数据库实例
    final newHelper = DatabaseHelper.instance;
    final db = await newHelper.database;

    // 开始事务
    await db.transaction((txn) async {
      // 1. 创建默认用户
      final userId = _uuid.v4();
      await txn.insert('users', {
        'id': userId,
        'username': 'default_user',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. 迁移每条记录
      for (final receipt in oldReceipts) {
        final orderId = _uuid.v4();
        
        // 创建新的order记录
        await txn.insert('orders', {
          'id': orderId,
          'user_id': userId,
          'order_type': 'receipt',
          'merchant_name': receipt['title'] ?? 'Unknown Merchant',
          'total_amount': 0.0, // 需要从图像识别中获取
          'actual_paid': 0.0,  // 需要从图像识别中获取
          'currency': 'CNY',
          'order_date': DateTime.fromMillisecondsSinceEpoch(receipt['created_at']).toIso8601String(),
          'order_time': DateTime.fromMillisecondsSinceEpoch(receipt['created_at']).toIso8601String().split('T')[1],
          'order_status': 'pending',
          'source_image_url': receipt['image_url'],
          'recognition_status': 'pending',
          'created_at': DateTime.fromMillisecondsSinceEpoch(receipt['created_at']).toIso8601String(),
          'updated_at': DateTime.fromMillisecondsSinceEpoch(receipt['updated_at']).toIso8601String(),
        });

        // 添加处理日志
        await txn.insert('order_processing_logs', {
          'id': _uuid.v4(),
          'order_id': orderId,
          'action': 'migration',
          'status': 'completed',
          'message': 'Migrated from old database',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    });

    // 3. 标记迁移完成
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('database_migrated', true);
  }

  Future<bool> needsMigration() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('database_migrated') ?? false);
  }
}

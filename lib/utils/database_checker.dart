import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';

class DatabaseChecker {
  static Future<bool> checkDatabaseTables() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // 检查所有表是否存在
      final tables = ['users', 'receipts', 'receipt_items', 'translations'];
      for (final table in tables) {
        final result = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
          [table],
        );
        if (result.isEmpty) {
          print('Table $table does not exist');
          return false;
        }
      }
      
      // 检查表结构
      final receiptColumns = await db.rawQuery('PRAGMA table_info(receipts)');
      final requiredColumns = [
        'id', 'user_id', 'image_path', 'merchant_name',
        'total_amount', 'currency', 'receipt_date', 'created_at'
      ];
      
      for (final column in requiredColumns) {
        if (!receiptColumns.any((col) => col['name'] == column)) {
          print('Column $column does not exist in receipts table');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      print('Database check failed: $e');
      return false;
    }
  }

  static Future<void> printDatabaseInfo() async {
    try {
      final db = await DatabaseHelper.instance.database;
      
      // 打印所有表信息
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      
      print('\n=== Database Tables ===');
      for (final table in tables) {
        final tableName = table['name'] as String;
        print('\nTable: $tableName');
        
        // 打印表结构
        final columns = await db.rawQuery('PRAGMA table_info($tableName)');
        print('Columns:');
        for (final column in columns) {
          print('  ${column['name']} (${column['type']})');
        }
        
        // 打印记录数
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
        );
        print('Records count: $count');
      }
      print('\n=====================');
    } catch (e) {
      print('Failed to print database info: $e');
    }
  }
}

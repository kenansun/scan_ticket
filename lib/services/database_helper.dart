import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/receipt.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart' as sqflite;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static late DatabaseFactory _databaseFactory;

  DatabaseHelper._init() {
    if (kIsWeb) {
      _databaseFactory = databaseFactoryFfiWeb;
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      _databaseFactory = databaseFactoryFfi;
    } else {
      // Use regular sqflite for Android and iOS
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

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipts (
        id $idType,
        user_id $textType,
        image_path $textType,
        merchant_name $textType,
        total_amount $realType,
        currency $textType,
        receipt_date $textType,
        created_at $textType
      )
    ''');
  }

  Future<bool> testConnection() async {
    try {
      final db = await instance.database;
      await db.execute('SELECT 1');
      return true;
    } catch (e) {
      print('Database connection test failed: $e');
      return false;
    }
  }

  Future<void> deleteDatabase() async {
    final dbPath = await _databaseFactory.getDatabasesPath();
    final path = join(dbPath, 'receipts.db');
    await _databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // CRUD Operations
  Future<String> insertReceipt(Receipt receipt) async {
    final db = await instance.database;
    await db.insert('receipts', receipt.toMap());
    return receipt.id;
  }

  Future<Receipt?> getReceipt(String id) async {
    final db = await instance.database;
    final maps = await db.query(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Receipt.fromMap(maps.first);
  }

  Future<List<Receipt>> getReceipts(String userId) async {
    final db = await instance.database;
    final orderBy = 'receipt_date DESC';
    final result = await db.query(
      'receipts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: orderBy,
    );

    return result.map((map) => Receipt.fromMap(map)).toList();
  }

  Future<int> updateReceipt(Receipt receipt) async {
    final db = await instance.database;
    return db.update(
      'receipts',
      receipt.toMap(),
      where: 'id = ?',
      whereArgs: [receipt.id],
    );
  }

  Future<int> deleteReceipt(String id) async {
    final db = await instance.database;
    return await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

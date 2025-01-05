import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/receipt.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

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
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        phone TEXT UNIQUE NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE receipts (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        image_path TEXT NOT NULL,
        merchant_name TEXT NOT NULL,
        total_amount DECIMAL(10,2) NOT NULL,
        currency TEXT NOT NULL,
        receipt_date DATE NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE receipt_items (
        id TEXT PRIMARY KEY,
        receipt_id TEXT NOT NULL,
        name TEXT NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        quantity INTEGER,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (receipt_id) REFERENCES receipts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE translations (
        id TEXT PRIMARY KEY,
        item_id TEXT NOT NULL,
        original_text TEXT NOT NULL,
        translated_text TEXT NOT NULL,
        language TEXT NOT NULL,
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (item_id) REFERENCES receipt_items(id)
      )
    ''');
  }

  Future<String> insertReceipt(Receipt receipt) async {
    final db = await database;
    await db.insert('receipts', receipt.toMap());
    
    for (var item in receipt.items) {
      await db.insert('receipt_items', item.toMap());
    }
    
    return receipt.id;
  }

  Future<Receipt?> getReceipt(String id) async {
    final db = await database;
    final maps = await db.query(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final receipt = Receipt.fromMap(maps.first);
    final items = await db.query(
      'receipt_items',
      where: 'receipt_id = ?',
      whereArgs: [id],
    );

    return Receipt(
      id: receipt.id,
      userId: receipt.userId,
      imagePath: receipt.imagePath,
      merchantName: receipt.merchantName,
      totalAmount: receipt.totalAmount,
      currency: receipt.currency,
      receiptDate: receipt.receiptDate,
      createdAt: receipt.createdAt,
      items: items.map((item) => ReceiptItem.fromMap(item)).toList(),
    );
  }

  Future<List<Receipt>> getReceipts(String userId) async {
    final db = await database;
    final receipts = await db.query(
      'receipts',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return Future.wait(
      receipts.map((map) async {
        final receipt = Receipt.fromMap(map);
        final items = await db.query(
          'receipt_items',
          where: 'receipt_id = ?',
          whereArgs: [receipt.id],
        );

        return Receipt(
          id: receipt.id,
          userId: receipt.userId,
          imagePath: receipt.imagePath,
          merchantName: receipt.merchantName,
          totalAmount: receipt.totalAmount,
          currency: receipt.currency,
          receiptDate: receipt.receiptDate,
          createdAt: receipt.createdAt,
          items: items.map((item) => ReceiptItem.fromMap(item)).toList(),
        );
      }),
    );
  }
}

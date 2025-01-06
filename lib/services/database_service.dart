import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

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
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipts (
        id TEXT PRIMARY KEY,
        title TEXT,
        description TEXT,
        image_url TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  // 插入新记录
  Future<String> insertReceipt({
    required String imageUrl,
    String? title,
    String? description,
  }) async {
    final db = await database;
    final id = _uuid.v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    await db.insert('receipts', {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'created_at': timestamp,
      'updated_at': timestamp,
    });

    return id;
  }

  // 获取所有记录
  Future<List<Map<String, dynamic>>> getAllReceipts() async {
    final db = await database;
    return await db.query(
      'receipts',
      orderBy: 'created_at DESC',
    );
  }

  // 获取单个记录
  Future<Map<String, dynamic>?> getReceipt(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // 更新记录
  Future<int> updateReceipt(String id, {
    String? title,
    String? description,
    String? imageUrl,
  }) async {
    final db = await database;
    return await db.update(
      'receipts',
      {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 删除记录
  Future<int> deleteReceipt(String id) async {
    final db = await database;
    return await db.delete(
      'receipts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 搜索记录
  Future<List<Map<String, dynamic>>> searchReceipts(String query) async {
    final db = await database;
    return await db.query(
      'receipts',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
  }
}

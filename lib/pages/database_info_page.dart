import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../utils/database_checker.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class DatabaseInfoPage extends StatefulWidget {
  const DatabaseInfoPage({super.key});

  @override
  State<DatabaseInfoPage> createState() => _DatabaseInfoPageState();
}

class _DatabaseInfoPageState extends State<DatabaseInfoPage> {
  String _dbInfo = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDatabaseInfo();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() {
      _isLoading = true;
      _dbInfo = 'Loading database information...';
    });

    try {
      final dbPath = await getDatabasesPath();
      final db = await DatabaseHelper.instance.database;
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );

      StringBuffer info = StringBuffer();
      info.writeln('Database Path: ${path.join(dbPath, 'scan_ticket.db')}');
      info.writeln('Database Version: ${await db.getVersion()}');
      info.writeln('\nTables:');

      for (final table in tables) {
        final tableName = table['name'] as String;
        info.writeln('\n📋 Table: $tableName');
        
        // 获取表结构
        final columns = await db.rawQuery('PRAGMA table_info($tableName)');
        info.writeln('Columns:');
        for (final column in columns) {
          info.writeln('  • ${column['name']} (${column['type']})');
        }
        
        // 获取记录数
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $tableName'),
        );
        info.writeln('Records count: $count');
      }

      setState(() {
        _dbInfo = info.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _dbInfo = 'Error loading database info: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetDatabase() async {
    try {
      await DatabaseHelper.instance.deleteDatabase();
      await _loadDatabaseInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Database reset successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resetting database: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDatabaseInfo,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dbInfo,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Reset Database'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reset Database'),
                            content: const Text(
                              'This will delete all data. Are you sure?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _resetDatabase();
                                },
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

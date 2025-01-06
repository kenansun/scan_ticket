import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/camera_page.dart';
import 'pages/image_preview_page.dart';
import 'pages/database_info_page.dart';
import 'pages/receipt_list_page.dart';
import 'utils/database_checker.dart';
import 'services/database_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize appropriate SQLite implementation based on platform
  if (!kIsWeb) {
    if (Platform.isAndroid || Platform.isIOS) {
      // Use default sqflite for mobile platforms
      // No initialization needed as it's the default
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Use FFI for desktop platforms
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  // 测试数据库连接
  final dbHelper = DatabaseHelper.instance;
  final isConnected = await dbHelper.testConnection();
  print('Database connection status: ${isConnected ? 'Connected' : 'Failed'}');

  // 检查数据库表
  final dbReady = await DatabaseChecker.checkDatabaseTables();
  if (!dbReady) {
    print('Database tables are not properly initialized');
    await DatabaseChecker.printDatabaseInfo();
  } else {
    print('Database tables are properly initialized');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scan Ticket',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('zh', ''),
      ],
      home: const ReceiptListPage(),
    );
  }
}

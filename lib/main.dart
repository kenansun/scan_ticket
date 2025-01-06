import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'pages/camera_page.dart';
import 'pages/image_preview_page.dart';
import 'pages/database_info_page.dart';
import 'utils/database_checker.dart';
import 'services/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化数据库工厂
  if (kIsWeb) {
    // Web平台使用 FFI web
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux) {
    // Windows 和 Linux 平台使用 FFI
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android 和 iOS 平台使用默认的 databaseFactory

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
        Locale('en', 'US'),
        Locale('zh', 'CN'),
      ],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _handleCameraButton(BuildContext context) async {
    final String? imagePath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraPage(),
      ),
    );

    if (imagePath != null && context.mounted) {
      final String? editedImagePath = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => ImagePreviewPage(imagePath: imagePath),
        ),
      );

      if (editedImagePath != null && context.mounted) {
        // TODO: 处理编辑后的图片
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edited photo saved to: $editedImagePath')),
        );
      }
    }
  }

  Future<void> _handleGalleryButton(BuildContext context) async {
    // TODO: 实现图库选择功能
  }

  void _showDatabaseInfo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DatabaseInfoPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Ticket'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () => _showDatabaseInfo(context),
            tooltip: 'Database Info',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _handleCameraButton(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _handleGalleryButton(context),
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}

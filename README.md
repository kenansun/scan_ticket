# Scan Ticket App

A Flutter application for scanning and managing receipts.

## Environment Setup

### Prerequisites
- Flutter SDK: Latest stable version
- Android Studio / VS Code with Flutter plugin
- Android SDK for Android development
- Xcode for iOS development (Mac only)
- Windows 开发者模式已启用（用于Flutter插件支持）

### Required Permissions
- Camera access
- Storage access (read/write)
- Photo library access (iOS)

## Project Structure

```
lib/
├── main.dart              # 应用程序入口
├── models/               # 数据模型
│   └── receipt.dart      # 收据模型
├── pages/               # 页面
│   ├── camera_page.dart  # 相机页面
│   └── image_preview_page.dart # 图片预览页面
├── services/            # 服务
│   ├── camera_service.dart    # 相机服务
│   └── database_helper.dart   # 数据库服务
└── widgets/             # 可重用组件
```

## Database Configuration

SQLite 数据库表结构：

```sql
-- 用户表
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  phone TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 收据表
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
);

-- 收据项目表
CREATE TABLE receipt_items (
  id TEXT PRIMARY KEY,
  receipt_id TEXT NOT NULL,
  name TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  quantity INTEGER,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (receipt_id) REFERENCES receipts(id)
);

-- 翻译表
CREATE TABLE translations (
  id TEXT PRIMARY KEY,
  item_id TEXT NOT NULL,
  original_text TEXT NOT NULL,
  translated_text TEXT NOT NULL,
  language TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (item_id) REFERENCES receipt_items(id)
);
```

## Development Guide

### Camera Feature
相机功能使用 `camera` 插件实现，主要包括：
- 相机初始化
- 拍照功能
- 图片保存

配置文件：
- Android: `android/app/src/main/AndroidManifest.xml`
- iOS: `ios/Runner/Info.plist`

### Image Processing
图片处理使用以下插件：
- `image`: 基本图片处理
- `image_cropper`: 图片裁剪

功能包括：
- 图片预览
- 裁剪
- 亮度/对比度调节
- 旋转

### Database
使用 `sqflite` 插件进行本地数据存储，主要操作：
- 数据库初始化
- CRUD 操作
- 数据迁移

## Testing

在运行应用前，请确保：
1. 已启用开发者模式
2. 已授予相机和存储权限
3. 数据库表已正确创建

## Known Issues

1. Windows开发需要启用开发者模式以支持Flutter插件
2. 相机预览可能需要适当的权限配置

## Next Steps

- [ ] 实现OCR文本识别
- [ ] 添加图片滤镜
- [ ] 实现多语言支持
- [ ] 添加用户认证
- [ ] 实现云存储同步

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('No cameras found', 'No cameras available on device');
      }

      // 默认使用后置相机
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
    } on CameraException catch (e) {
      throw Exception('Failed to initialize camera: ${e.description}');
    }
  }

  Future<String> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    try {
      // 确保相机已准备好
      await _controller!.setFlashMode(FlashMode.auto);
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      // 拍照
      final XFile image = await _controller!.takePicture();

      // 获取应用文档目录
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final receiptsDir = Directory(join(directory.path, 'receipts'));
      final String filePath = join(receiptsDir.path, fileName);

      // 确保目录存在
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      // 复制图片到应用目录
      await image.saveTo(filePath);

      return filePath;
    } on CameraException catch (e) {
      throw Exception('Failed to take picture: ${e.description}');
    }
  }

  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }

  Future<void> pausePreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.pausePreview();
    }
  }

  Future<void> resumePreview() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.resumePreview();
    }
  }
}

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isDisposing = false;
  final MethodChannel _cameraChannel = const MethodChannel('com.example.scan_ticket/camera');
  final Completer<void> _cameraCompleter = Completer<void>();

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  Future<void> initialize({ResolutionPreset resolutionPreset = ResolutionPreset.high}) async {
    if (_isInitialized || _isDisposing) {
      return;
    }

    try {
      // 初始化原生相机资源
      await _cameraChannel.invokeMethod('initializeCamera');
      
      // 等待一段时间确保原生相机已准备好
      await Future.delayed(const Duration(milliseconds: 500));
      
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('No cameras found', 'No cameras available on device');
      }

      // 默认使用后置相机
      final camera = _cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      await _disposeCurrentCamera();

      _controller = CameraController(
        camera,
        resolutionPreset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      // 设置相机参数以优化性能
      await _controller!.initialize();
      _isInitialized = true;
      
      // 设置自动曝光模式
      await _controller!.setExposureMode(ExposureMode.auto);
      await _controller!.lockCaptureOrientation();
      if (!_cameraCompleter.isCompleted) {
        _cameraCompleter.complete();
      }
    } on CameraException catch (e) {
      await _disposeCurrentCamera();
      throw Exception('Failed to initialize camera: ${e.description}');
    }
  }

  Future<void> _cleanupCameraResources() async {
    try {
      await _cameraChannel.invokeMethod('cleanupCameraResources');
      // 重置完成器
      if (!_cameraCompleter.isCompleted) {
        _cameraCompleter.complete();
      }
    } catch (e) {
      print('Error cleaning up camera resources: $e');
    }
  }

  Future<void> _disposeCurrentCamera() async {
    if (_controller != null) {
      final CameraController controller = _controller!;
      _controller = null;
      _isInitialized = false;

      if (controller.value.isInitialized) {
        try {
          await controller.pausePreview();
          await Future.delayed(const Duration(milliseconds: 100));
          await _cleanupCameraResources();
          await Future.delayed(const Duration(milliseconds: 100));
          await controller.dispose();
        } catch (e) {
          print('Error disposing camera: $e');
        }
      }
    }
  }

  Future<String> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isDisposing) {
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
      final appDir = await getApplicationDocumentsDirectory();
      
      // 在应用文档目录创建票据目录
      final receiptsDir = Directory(join(appDir.path, 'Pictures', 'Receipts'));
      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      // 生成文件名和路径
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = join(receiptsDir.path, fileName);

      // 复制图片到新位置
      final File imageFile = File(image.path);
      await imageFile.copy(filePath);

      return filePath;
    } on CameraException catch (e) {
      throw Exception('Failed to take picture: ${e.description}');
    }
  }

  Future<void> dispose() async {
    _isDisposing = true;
    await _disposeCurrentCamera();
  }

  Future<void> pausePreview() async {
    if (_controller != null && _controller!.value.isInitialized && !_isDisposing) {
      try {
        await _controller!.pausePreview();
        await Future.delayed(const Duration(milliseconds: 100));
        await _cleanupCameraResources();
      } catch (e) {
        print('Error pausing preview: $e');
      }
    }
  }

  Future<void> resumePreview() async {
    if (_controller != null && _controller!.value.isInitialized && !_isDisposing) {
      try {
        await _cameraChannel.invokeMethod('initializeCamera');
        await Future.delayed(const Duration(milliseconds: 500));
        await _controller!.resumePreview();
      } catch (e) {
        print('Error resuming preview: $e');
      }
    }
  }
}

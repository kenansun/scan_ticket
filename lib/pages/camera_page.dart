import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import 'package:flutter/scheduler.dart';
import 'image_preview_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  final CameraService _cameraService = CameraService();
  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    if (_isDisposing) return;

    try {
      // 设置相机分辨率
      final ResolutionPreset preset = ResolutionPreset.medium;
      await _cameraService.initialize(resolutionPreset: preset);
      
      if (mounted && !_isDisposing) {
        setState(() {
          _isCameraReady = true;
        });
      }
    } catch (e) {
      if (mounted && !_isDisposing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    WidgetsBinding.instance.removeObserver(this);
    
    _cameraService.dispose().then((_) {
      if (mounted) {
        setState(() {
          _isDisposing = false;
        });
      }
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposing) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // 页面不活跃时释放相机资源
      _isCameraReady = false;
      _cameraService.pausePreview().then((_) {
        _cameraService.dispose();
      });
    } else if (state == AppLifecycleState.resumed) {
      // 页面恢复时重新初始化相机
      _initializeCamera();
    }
  }

  Future<void> _takePicture() async {
    if (_isCapturing || _isDisposing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      final Map<String, String> result = await _cameraService.takePicture();
      if (mounted && !_isDisposing) {
        // 先暂停预览
        await _cameraService.pausePreview();
        
        // 打开预览页面
        if (mounted) {
          final previewResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImagePreviewPage(
                localPath: result['localPath']!,
                ossUrl: result['ossUrl']!,
              ),
            ),
          );
          
          if (mounted) {
            Navigator.pop(context, previewResult);
          }
        }
      }
    } catch (e) {
      if (mounted && !_isDisposing) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted && !_isDisposing) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraReady || _cameraService.controller == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 相机预览
          CameraPreview(_cameraService.controller!),
          
          // 顶部操作栏
          SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_auto, color: Colors.white),
                    onPressed: () async {
                      // TODO: 实现闪光灯控制
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // 底部操作栏
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 64), // 占位
                  FloatingActionButton(
                    heroTag: 'take_picture',
                    onPressed: _isCapturing ? null : _takePicture,
                    child: _isCapturing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.camera),
                  ),
                  const SizedBox(width: 64), // 占位
                ],
              ),
            ),
          ),
          
          // 取景框
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 1.2, // 适合收据的长宽比
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

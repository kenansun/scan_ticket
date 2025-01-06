import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImagePreviewPage extends StatefulWidget {
  final String imagePath;

  const ImagePreviewPage({super.key, required this.imagePath});

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage> {
  late String _currentImagePath;
  bool _isProcessing = false;
  final GlobalKey _cropKey = GlobalKey();
  Rect? _cropRect;

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.imagePath;
  }

  Future<String?> _cropImage() async {
    if (_cropRect == null) return null;

    setState(() => _isProcessing = true);
    try {
      final File imageFile = File(_currentImagePath);
      final bytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load image')),
          );
        }
        return null;
      }

      // 计算裁剪区域
      final RenderBox box = _cropKey.currentContext!.findRenderObject() as RenderBox;
      final Size imageSize = box.size;
      final double scale = originalImage.width / imageSize.width;
      
      final int x = (_cropRect!.left * scale).round();
      final int y = (_cropRect!.top * scale).round();
      final int w = (_cropRect!.width * scale).round();
      final int h = (_cropRect!.height * scale).round();

      // 确保裁剪区域在图片范围内
      final int safeX = x.clamp(0, originalImage.width - 1);
      final int safeY = y.clamp(0, originalImage.height - 1);
      final int safeW = w.clamp(1, originalImage.width - safeX);
      final int safeH = h.clamp(1, originalImage.height - safeY);

      // 裁剪图片
      final img.Image croppedImage = img.copyCrop(
        originalImage,
        safeX,
        safeY,
        safeW,
        safeH,
      );

      // 保存裁剪后的图片
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = path.join(
        directory.path,
        'cropped_${path.basename(_currentImagePath)}',
      );
      final File newImage = File(newPath);
      await newImage.writeAsBytes(img.encodeJpg(croppedImage));

      setState(() {
        _currentImagePath = newPath;
        _cropRect = null;
      });

      return newPath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to crop image: $e')),
        );
      }
      return null;
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<String?> _rotateImage() async {
    setState(() => _isProcessing = true);
    try {
      final File imageFile = File(_currentImagePath);
      final bytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load image')),
          );
        }
        return null;
      }

      // 旋转图片90度
      final img.Image rotatedImage = img.copyRotate(originalImage, 90);
      
      // 保存旋转后的图片
      final directory = await getApplicationDocumentsDirectory();
      final String newPath = path.join(
        directory.path,
        'rotated_${path.basename(_currentImagePath)}',
      );
      final File newImage = File(newPath);
      await newImage.writeAsBytes(img.encodeJpg(rotatedImage));
      
      setState(() {
        _currentImagePath = newPath;
      });
      
      return newPath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to rotate image: $e')),
        );
      }
      return null;
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _onPanStart(DragStartDetails details) {
    final RenderBox box = _cropKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    setState(() {
      _cropRect = Rect.fromPoints(localPosition, localPosition);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_cropRect == null) return;
    final RenderBox box = _cropKey.currentContext!.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);
    setState(() {
      _cropRect = Rect.fromPoints(_cropRect!.topLeft, localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_cropRect == null) return;
    if (_cropRect!.width < 20 || _cropRect!.height < 20) {
      setState(() {
        _cropRect = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.crop),
            onPressed: _cropRect != null ? _cropImage : null,
            tooltip: 'Crop',
          ),
          IconButton(
            icon: const Icon(Icons.rotate_right),
            onPressed: _isProcessing ? null : _rotateImage,
            tooltip: 'Rotate',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _currentImagePath),
            tooltip: 'Done',
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              key: _cropKey,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: Stack(
                children: [
                  Image.file(
                    File(_currentImagePath),
                    fit: BoxFit.contain,
                  ),
                  if (_cropRect != null)
                    Positioned.fromRect(
                      rect: _cropRect!,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

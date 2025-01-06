import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImagePreviewPage extends StatelessWidget {
  final String localPath;
  final String ossUrl;

  const ImagePreviewPage({
    super.key,
    required this.localPath,
    required this.ossUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('预览图片'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop({
                'localPath': localPath,
                'ossUrl': ossUrl,
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.file(File(localPath)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OSS URL:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(ossUrl, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'localPath': localPath,
                      'ossUrl': ossUrl,
                    });
                  },
                  child: const Text('确认使用'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

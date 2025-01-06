import 'package:flutter/material.dart';
import '../services/camera_service.dart';
import 'camera_page.dart';

class TestUploadPage extends StatefulWidget {
  const TestUploadPage({super.key});

  @override
  State<TestUploadPage> createState() => _TestUploadPageState();
}

class _TestUploadPageState extends State<TestUploadPage> {
  String? _localPath;
  String? _ossUrl;
  bool _isLoading = false;

  Future<void> _takePicture() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CameraPage(),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _localPath = result['localPath'];
          _ossUrl = result['ossUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测试上传'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _takePicture,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('拍照并上传'),
            ),
            const SizedBox(height: 16),
            if (_localPath != null) ...[
              const Text('本地路径:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_localPath!),
              const SizedBox(height: 16),
            ],
            if (_ossUrl != null) ...[
              const Text('OSS URL:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(_ossUrl!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL已复制到剪贴板')),
                  );
                },
                child: const Text('复制 URL'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

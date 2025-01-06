import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/oss_upload_service.dart';
import '../services/database_service.dart';
import 'dart:io';

class ImageUploadTestPage extends StatefulWidget {
  const ImageUploadTestPage({super.key});

  @override
  State<ImageUploadTestPage> createState() => _ImageUploadTestPageState();
}

class _ImageUploadTestPageState extends State<ImageUploadTestPage> {
  final ImagePicker _picker = ImagePicker();
  final OssUploadService _ossService = OssUploadService();
  final DatabaseService _dbService = DatabaseService.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  bool _isUploading = false;
  String? _selectedImagePath;
  String? _uploadedUrl;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _uploadedUrl = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '选择图片失败: $e';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImagePath == null) {
      setState(() {
        _errorMessage = '请先选择图片';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // 先上传到OSS
      final url = await _ossService.uploadFile(_selectedImagePath!);
      
      try {
        // 上传成功后保存到数据库
        await _dbService.insertReceipt(
          imageUrl: url,
          title: _titleController.text.isNotEmpty ? _titleController.text : null,
          description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        );

        setState(() {
          _uploadedUrl = url;
          _isUploading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('上传成功')),
          );
          // 延迟一下再返回，让用户看到成功消息
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
          });
        }
      } catch (dbError) {
        print('Database error: $dbError');
        // 数据库操作失败，但文件已上传成功
        setState(() {
          _errorMessage = '保存记录失败: $dbError';
          _isUploading = false;
        });
      }
    } catch (e) {
      print('Upload error: $e');
      setState(() {
        _errorMessage = '上传失败: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传收据'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '给收据起个名字（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '添加一些描述（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : _pickImage,
              child: const Text('选择图片'),
            ),
            if (_selectedImagePath != null) ...[
              const SizedBox(height: 16),
              Image.file(
                File(_selectedImagePath!),
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadImage,
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('上传图片'),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

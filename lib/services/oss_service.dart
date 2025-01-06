import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/oss_config.dart';

class OssService {
  static const String serverUrl = 'YOUR_SERVER_URL'; // 你的服务器地址

  // 获取OSS上传签名
  static Future<Map<String, dynamic>> getOssSignature({
    required String fileName,
    required String fileType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/oss/signature'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fileName': fileName,
          'fileType': fileType,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get OSS signature');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // 使用签名直传文件到OSS
  static Future<String> uploadFileWithSignature({
    required String filePath,
    required String fileName,
  }) async {
    try {
      // 1. 获取服务器签名
      final signature = await getOssSignature(
        fileName: fileName,
        fileType: 'image/jpeg',
      );

      // 2. 构建表单数据
      final uri = Uri.parse(OssConfig.endpoint);
      var request = http.MultipartRequest('POST', uri);
      
      // 添加OSS需要的表单字段
      request.fields.addAll({
        'key': '${OssConfig.receiptFolder}$fileName',
        'policy': signature['policy'],
        'OSSAccessKeyId': signature['accessId'],
        'success_action_status': '200',
        'signature': signature['signature'],
      });

      // 添加文件
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
      ));

      // 3. 发送请求
      final response = await request.send();
      
      if (response.statusCode == 200) {
        // 返回文件的访问URL
        return 'https://${OssConfig.bucket}.${OssConfig.endpoint}/${OssConfig.receiptFolder}$fileName';
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }
}

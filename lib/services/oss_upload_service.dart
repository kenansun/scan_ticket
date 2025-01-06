import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class OssUploadService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(minutes: 5),
    receiveTimeout: const Duration(minutes: 5),
    sendTimeout: const Duration(minutes: 5),
    validateStatus: (status) => status! < 500,
  ))
    ..interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ))
    ..httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      },
    );

  // 创建一个新的Dio实例用于OSS上传
  Dio _createOssDio() {
    return Dio(BaseOptions(
      connectTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
      sendTimeout: const Duration(minutes: 5),
      validateStatus: (status) => status! < 500,
    ))
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
  }

  // 获取服务器签名
  Future<Map<String, dynamic>> _getSignature(String fileName, String fileType) async {
    try {
      print('Getting signature from: ${ApiConfig.baseUrl}/oss/signature');
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/oss/signature',
        data: {
          'fileName': fileName,
          'fileType': fileType,
        },
      );
      
      print('\n*** Response ***');
      print('uri: ${ApiConfig.baseUrl}/oss/signature');
      print('statusCode: ${response.statusCode}');
      print('headers:');
      response.headers.forEach((name, values) {
        print(' $name: ${values.join(', ')}');
      });
      print('Response Text:');
      print(response.data);
      print('');
      
      if (response.statusCode == 200) {
        print('Signature response: ${response.data}');
        return response.data;
      } else {
        throw Exception('Failed to get signature: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting signature: $e');
      throw Exception('Network error while getting signature: $e');
    }
  }

  // 获取单个文件的签名URL
  Future<String> getSignedUrl(String objectKey) async {
    try {
      print('Getting signed URL for: $objectKey');
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/oss/get_url',
        data: {'object_key': objectKey},
      );
      
      print('\n*** Response ***');
      print('uri: ${ApiConfig.baseUrl}/oss/get_url');
      print('statusCode: ${response.statusCode}');
      print('Response data: ${response.data}');
      print('');
      
      if (response.statusCode == 200) {
        return response.data['url'];
      } else {
        throw Exception('Failed to get signed URL: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting signed URL: $e');
      rethrow;
    }
  }

  // 批量获取文件的签名URL
  Future<Map<String, String>> getBatchSignedUrls(List<String> objectKeys) async {
    try {
      print('Getting batch signed URLs for: $objectKeys');
      final response = await _dio.post(
        '${ApiConfig.baseUrl}/oss/get_batch_urls',
        data: {'object_keys': objectKeys},
      );
      
      print('\n*** Response ***');
      print('uri: ${ApiConfig.baseUrl}/oss/get_batch_urls');
      print('statusCode: ${response.statusCode}');
      print('Response data: ${response.data}');
      print('');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> urls = response.data['urls'];
        return urls.map((key, value) => MapEntry(key, value.toString()));
      } else {
        throw Exception('Failed to get batch signed URLs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting batch signed URLs: $e');
      rethrow;
    }
  }

  // 上传文件到OSS
  Future<String> uploadFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      // 获取文件信息
      final String fileName = path.basename(filePath);
      final String? mimeType = lookupMimeType(filePath);
      
      if (mimeType == null) {
        throw Exception('Could not determine file type');
      }

      // 获取签名
      final signatureData = await _getSignature(fileName, mimeType);
      final String key = '${signatureData['dir']}$fileName';
      final String uploadUrl = signatureData['host'].toString();
      
      print('Uploading to OSS: $uploadUrl');
      print('Using upload URL: $uploadUrl');

      // 准备表单数据
      final formData = FormData.fromMap({
        'key': key,
        'policy': signatureData['policy'],
        'OSSAccessKeyId': signatureData['accessId'],
        'success_action_status': '200',
        'signature': signatureData['signature'],
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        ),
      });

      // 使用新的Dio实例上传到OSS
      final ossDio = _createOssDio();
      final response = await ossDio.post(
        uploadUrl,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': '*/*',
            'Host': Uri.parse(uploadUrl).host,
            'User-Agent': 'ScanTicket/1.0',
            'Connection': 'keep-alive',
          },
          followRedirects: true,
          responseType: ResponseType.bytes,
        ),
      );

      print('\n*** Response ***');
      print('uri: $uploadUrl');
      print('statusCode: ${response.statusCode}');
      print('headers:');
      response.headers.forEach((name, values) {
        print(' $name: ${values.join(', ')}');
      });
      print('Response Text:');
      if (response.data != null) {
        print(String.fromCharCodes(response.data));
      }
      print('');
      
      if (response.statusCode == 200) {
        final url = '$uploadUrl/$key';
        print('Upload successful. URL: $url');
        return url;
      } else {
        final responseText = response.data != null ? String.fromCharCodes(response.data) : 'No response data';
        print('Upload failed with status: ${response.statusCode}');
        print('Response: $responseText');
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }
}

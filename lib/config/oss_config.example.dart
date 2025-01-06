class OssConfig {
  // OSS配置信息
  static const String endpoint = 'your-endpoint';  // 例如：'oss-cn-hangzhou.aliyuncs.com'
  static const String bucket = 'scantickedtest';
  static const String accessKeyId = 'your-access-key-id';
  static const String accessKeySecret = 'your-access-key-secret';
  
  // OSS文件存储路径配置
  static const String receiptFolder = 'receipts/';  // OSS中存储票据的文件夹路径
  
  // 可选：CDN域名配置
  static const String cdnDomain = 'your-cdn-domain';  // 如果使用CDN，配置CDN域名
}

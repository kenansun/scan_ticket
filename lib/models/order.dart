enum OrderType { receipt, takeout, shopping }
enum OrderStatus { pending, completed, failed }
enum RecognitionStatus { pending, processing, completed, failed }

class Order {
  final String id;
  final String userId;
  final OrderType orderType;
  final String merchantName;
  final String? platform;
  final double totalAmount;
  final double actualPaid;
  final double? discountAmount;
  final String currency;
  final DateTime orderDate;
  final String orderTime;
  final OrderStatus orderStatus;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? sourceImageUrl;
  final String? sourceImagePath;
  final String? rawTextContent;
  final RecognitionStatus recognitionStatus;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.orderType,
    required this.merchantName,
    this.platform,
    required this.totalAmount,
    required this.actualPaid,
    this.discountAmount,
    this.currency = 'CNY',
    required this.orderDate,
    required this.orderTime,
    required this.orderStatus,
    this.paymentMethod,
    this.paymentStatus,
    this.sourceImageUrl,
    this.sourceImagePath,
    this.rawTextContent,
    required this.recognitionStatus,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'order_type': orderType.toString().split('.').last,
      'merchant_name': merchantName,
      'platform': platform,
      'total_amount': totalAmount,
      'actual_paid': actualPaid,
      'discount_amount': discountAmount,
      'currency': currency,
      'order_date': orderDate.toIso8601String(),
      'order_time': orderTime,
      'order_status': orderStatus.toString().split('.').last,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'source_image_url': sourceImageUrl,
      'source_image_path': sourceImagePath,
      'raw_text_content': rawTextContent,
      'recognition_status': recognitionStatus.toString().split('.').last,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Order fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'],
      userId: map['user_id'],
      orderType: OrderType.values.firstWhere(
          (e) => e.toString().split('.').last == map['order_type']),
      merchantName: map['merchant_name'],
      platform: map['platform'],
      totalAmount: map['total_amount'],
      actualPaid: map['actual_paid'],
      discountAmount: map['discount_amount'],
      currency: map['currency'],
      orderDate: DateTime.parse(map['order_date']),
      orderTime: map['order_time'],
      orderStatus: OrderStatus.values.firstWhere(
          (e) => e.toString().split('.').last == map['order_status']),
      paymentMethod: map['payment_method'],
      paymentStatus: map['payment_status'],
      sourceImageUrl: map['source_image_url'],
      sourceImagePath: map['source_image_path'],
      rawTextContent: map['raw_text_content'],
      recognitionStatus: RecognitionStatus.values.firstWhere(
          (e) => e.toString().split('.').last == map['recognition_status']),
      errorMessage: map['error_message'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

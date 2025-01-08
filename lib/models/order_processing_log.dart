class OrderProcessingLog {
  final String id;
  final String orderId;
  final String action;
  final String status;
  final String? message;
  final DateTime createdAt;

  OrderProcessingLog({
    required this.id,
    required this.orderId,
    required this.action,
    required this.status,
    this.message,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'action': action,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static OrderProcessingLog fromMap(Map<String, dynamic> map) {
    return OrderProcessingLog(
      id: map['id'],
      orderId: map['order_id'],
      action: map['action'],
      status: map['status'],
      message: map['message'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

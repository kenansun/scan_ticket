class Receipt {
  final String id;
  final String userId;
  final String imagePath;
  final String merchantName;
  final double totalAmount;
  final String currency;
  final DateTime receiptDate;
  final DateTime createdAt;

  Receipt({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.merchantName,
    required this.totalAmount,
    required this.currency,
    required this.receiptDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'image_path': imagePath,
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'currency': currency,
      'receipt_date': receiptDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      userId: map['user_id'],
      imagePath: map['image_path'],
      merchantName: map['merchant_name'],
      totalAmount: map['total_amount'],
      currency: map['currency'],
      receiptDate: DateTime.parse(map['receipt_date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Receipt copyWith({
    String? id,
    String? userId,
    String? imagePath,
    String? merchantName,
    double? totalAmount,
    String? currency,
    DateTime? receiptDate,
    DateTime? createdAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      imagePath: imagePath ?? this.imagePath,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      currency: currency ?? this.currency,
      receiptDate: receiptDate ?? this.receiptDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ReceiptItem {
  final String id;
  final String receiptId;
  final String name;
  final double amount;
  final int? quantity;
  final DateTime createdAt;

  ReceiptItem({
    required this.id,
    required this.receiptId,
    required this.name,
    required this.amount,
    this.quantity,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_id': receiptId,
      'name': name,
      'amount': amount,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      id: map['id'],
      receiptId: map['receipt_id'],
      name: map['name'],
      amount: map['amount'],
      quantity: map['quantity'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

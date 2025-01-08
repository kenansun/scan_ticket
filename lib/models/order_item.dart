class OrderItem {
  final String id;
  final String orderId;
  final String name;
  final String? specification;
  final double quantity;
  final double unitPrice;
  final double amount;
  final String? category;
  final int itemIndex;
  final bool isValid;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.name,
    this.specification,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
    this.category,
    required this.itemIndex,
    this.isValid = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'order_id': orderId,
      'name': name,
      'specification': specification,
      'quantity': quantity,
      'unit_price': unitPrice,
      'amount': amount,
      'category': category,
      'item_index': itemIndex,
      'is_valid': isValid ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static OrderItem fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'],
      orderId: map['order_id'],
      name: map['name'],
      specification: map['specification'],
      quantity: map['quantity'],
      unitPrice: map['unit_price'],
      amount: map['amount'],
      category: map['category'],
      itemIndex: map['item_index'],
      isValid: map['is_valid'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

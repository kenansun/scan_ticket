enum MealType { breakfast, lunch, dinner, midnight }

class DiningOrder {
  final String orderId;
  final MealType mealType;
  final int? estimatedDiners;
  final int? tablewareCount;
  final int? setMealCount;
  final double? perPersonCost;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiningOrder({
    required this.orderId,
    required this.mealType,
    this.estimatedDiners,
    this.tablewareCount,
    this.setMealCount,
    this.perPersonCost,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'order_id': orderId,
      'meal_type': mealType.toString().split('.').last,
      'estimated_diners': estimatedDiners,
      'tableware_count': tablewareCount,
      'set_meal_count': setMealCount,
      'per_person_cost': perPersonCost,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static DiningOrder fromMap(Map<String, dynamic> map) {
    return DiningOrder(
      orderId: map['order_id'],
      mealType: MealType.values.firstWhere(
          (e) => e.toString().split('.').last == map['meal_type']),
      estimatedDiners: map['estimated_diners'],
      tablewareCount: map['tableware_count'],
      setMealCount: map['set_meal_count'],
      perPersonCost: map['per_person_cost'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }
}

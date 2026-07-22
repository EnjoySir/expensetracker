class Budget {
  int? id;
  int categoryId;
  double amountLimit;
  String? categoryName;
  String? categoryIcon;
  String? categoryColor;

  Budget({
    this.id,
    required this.categoryId,
    required this.amountLimit,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'amount_limit': amountLimit,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      categoryId: map['category_id'],
      amountLimit: (map['amount_limit'] as num).toDouble(),
      categoryName: map['category_name'],
      categoryIcon: map['category_icon'],
      categoryColor: map['category_color'],
    );
  }
}

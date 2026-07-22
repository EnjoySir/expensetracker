class Bill {
  int? id;
  String name;
  double amount;
  String dueDate; // yyyy-MM-dd
  int categoryId;
  int isPaid; // 0 = unpaid, 1 = paid
  String? categoryName;
  String? categoryIcon;
  String? categoryColor;

  Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.categoryId,
    this.isPaid = 0,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'due_date': dueDate,
      'category_id': categoryId,
      'is_paid': isPaid,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'],
      name: map['name'],
      amount: (map['amount'] as num).toDouble(),
      dueDate: map['due_date'],
      categoryId: map['category_id'],
      isPaid: map['is_paid'] ?? 0,
      categoryName: map['category_name'],
      categoryIcon: map['category_icon'],
      categoryColor: map['category_color'],
    );
  }
}

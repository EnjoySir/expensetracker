class Expense {
  int? id;
  double amount;
  int categoryId;
  String note;
  String date;
  String type; // 'expense' or 'income'
  String? categoryName;
  String? categoryIcon;
  String? categoryColor;

  Expense({
    this.id,
    required this.amount,
    required this.categoryId,
    this.note = '',
    required this.date,
    this.type = 'expense',
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'note': note,
      'date': date,
      'type': type,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      amount: map['amount'],
      categoryId: map['category_id'],
      note: map['note'] ?? '',
      date: map['date'],
      type: map['type'] ?? 'expense',
      categoryName: map['category_name'],
      categoryIcon: map['category_icon'],
      categoryColor: map['category_color'],
    );
  }
}
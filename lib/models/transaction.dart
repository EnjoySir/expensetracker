class Transaction {
  int? id;
  double amount;
  int categoryId;
  int accountId;
  String note;
  String date;
  String type; // 'expense' or 'income'
  String? merchant;
  String? receiptPath;
  String? location;
  
  // Joins
  String? categoryName;
  String? categoryIcon;
  String? categoryColor;
  String? accountName;

  Transaction({
    this.id,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.note = '',
    required this.date,
    this.type = 'expense',
    this.merchant,
    this.receiptPath,
    this.location,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.accountName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'account_id': accountId,
      'note': note,
      'date': date,
      'type': type,
      'merchant': merchant,
      'receipt_path': receiptPath,
      'location': location,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      amount: (map['amount'] as num).toDouble(),
      categoryId: map['category_id'],
      accountId: map['account_id'] ?? 1, // Fallback to Cash wallet
      note: map['note'] ?? '',
      date: map['date'],
      type: map['type'] ?? 'expense',
      merchant: map['merchant'],
      receiptPath: map['receipt_path'],
      location: map['location'],
      categoryName: map['category_name'],
      categoryIcon: map['category_icon'],
      categoryColor: map['category_color'],
      accountName: map['account_name'],
    );
  }
}

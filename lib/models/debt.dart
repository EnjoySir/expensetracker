class Debt {
  int? id;
  String person;
  double amount;
  String type; // 'borrowed' or 'lent'
  String dueDate; // yyyy-MM-dd
  double remainingBalance;
  String status; // 'active' or 'paid'

  Debt({
    this.id,
    required this.person,
    required this.amount,
    required this.type,
    required this.dueDate,
    required this.remainingBalance,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'person': person,
      'amount': amount,
      'type': type,
      'due_date': dueDate,
      'remaining_balance': remainingBalance,
      'status': status,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      person: map['person'],
      amount: (map['amount'] as num).toDouble(),
      type: map['type'],
      dueDate: map['due_date'],
      remainingBalance: (map['remaining_balance'] as num).toDouble(),
      status: map['status'] ?? 'active',
    );
  }
}

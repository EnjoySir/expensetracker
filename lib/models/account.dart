class Account {
  int? id;
  String name;
  String type; // Cash, Bank Account, Savings Account, EcoCash, Mukuru, etc.
  double balance;
  String currency; // USD, ZWG, ZAR, EUR, GBP

  Account({
    this.id,
    required this.name,
    required this.type,
    this.balance = 0.0,
    this.currency = 'USD',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
    );
  }
}

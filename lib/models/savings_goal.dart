class SavingsGoal {
  int? id;
  String name;
  double targetAmount;
  double savedAmount;
  String deadline; // yyyy-MM-dd

  SavingsGoal({
    this.id,
    required this.name,
    required this.targetAmount,
    this.savedAmount = 0.0,
    required this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'saved_amount': savedAmount,
      'deadline': deadline,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      name: map['name'],
      targetAmount: (map['target_amount'] as num).toDouble(),
      savedAmount: (map['saved_amount'] as num?)?.toDouble() ?? 0.0,
      deadline: map['deadline'],
    );
  }
}

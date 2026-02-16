enum PaymentMode { cash, bank, upi, credit }

class Expense {
  Expense({
    this.id,
    required this.category,
    required this.amount,
    this.note,
    required this.paymentMode,
    required this.createdAt,
  });

  final int? id;
  final String category;
  final double amount;
  final String? note;
  final PaymentMode paymentMode;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
        'id': id,
        'category': category,
        'amount': amount,
        'note': note,
        'paymentMode': paymentMode.name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int?,
        category: map['category'] as String,
        amount: (map['amount'] as num).toDouble(),
        note: map['note'] as String?,
        paymentMode: PaymentMode.values.byName(map['paymentMode'] as String),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

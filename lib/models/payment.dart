/// Represents a single payment transaction
class Payment {
  final String id;
  final double amount;
  final DateTime date;
  final String method; // cash, card, upi, cheque, bank_transfer
  final String notes;

  Payment({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    this.notes = '',
  });

  /// Convert payment to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'method': method,
      'notes': notes,
    };
  }

  /// Create payment from map
  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      method: map['method'] as String,
      notes: map['notes'] as String? ?? '',
    );
  }

  /// Create a copy with modified fields
  Payment copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? method,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      notes: notes ?? this.notes,
    );
  }
}

/// Payment method constants
class PaymentMethod {
  static const String cash = 'cash';
  static const String card = 'card';
  static const String upi = 'upi';
  static const String cheque = 'cheque';
  static const String bankTransfer = 'bank_transfer';

  static const List<String> all = [cash, card, upi, cheque, bankTransfer];

  static String getDisplayName(String method) {
    switch (method) {
      case cash:
        return 'Cash';
      case card:
        return 'Card';
      case upi:
        return 'UPI';
      case cheque:
        return 'Cheque';
      case bankTransfer:
        return 'Bank Transfer';
      default:
        return 'Unknown';
    }
  }
}

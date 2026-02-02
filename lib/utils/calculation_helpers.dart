/// Financial calculation utilities
class CalculationHelpers {
  /// Calculate percentage of an amount
  static double calculatePercentage(double amount, double percentage) {
    return (amount * percentage) / 100;
  }

  /// Calculate tax on a subtotal
  static double calculateTax(double subtotal, double taxRate) {
    return calculatePercentage(subtotal, taxRate);
  }

  /// Calculate discount
  /// If isPercentage is true, discount is treated as percentage, otherwise as fixed amount
  static double calculateDiscount(
    double amount,
    double discount,
    bool isPercentage,
  ) {
    if (isPercentage) {
      return calculatePercentage(amount, discount);
    }
    return discount;
  }

  /// Calculate final amount after discount and tax
  static double calculateFinalAmount({
    required double subtotal,
    required double discountAmount,
    required double taxRate,
  }) {
    final afterDiscount = subtotal - discountAmount;
    final taxAmount = calculateTax(afterDiscount, taxRate);
    return afterDiscount + taxAmount;
  }

  /// Generate installment plan
  static List<InstallmentPlan> generateInstallmentPlan({
    required double totalAmount,
    required int numberOfInstallments,
    required DateTime startDate,
    int intervalDays = 30,
  }) {
    if (numberOfInstallments <= 0) return [];

    final installmentAmount = totalAmount / numberOfInstallments;
    final List<InstallmentPlan> plan = [];

    for (int i = 0; i < numberOfInstallments; i++) {
      final dueDate = startDate.add(Duration(days: intervalDays * i));
      plan.add(
        InstallmentPlan(
          installmentNumber: i + 1,
          amount: installmentAmount,
          dueDate: dueDate,
          isPaid: false,
        ),
      );
    }

    return plan;
  }

  /// Calculate advance percentage
  static double calculateAdvancePercentage(double advance, double total) {
    if (total == 0) return 0;
    return (advance / total) * 100;
  }

  /// Calculate pending percentage
  static double calculatePendingPercentage(double pending, double total) {
    if (total == 0) return 0;
    return (pending / total) * 100;
  }

  /// Format currency
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  /// Format percentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}

/// Represents an installment in a payment plan
class InstallmentPlan {
  final int installmentNumber;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;

  InstallmentPlan({
    required this.installmentNumber,
    required this.amount,
    required this.dueDate,
    required this.isPaid,
  });

  InstallmentPlan copyWith({
    int? installmentNumber,
    double? amount,
    DateTime? dueDate,
    bool? isPaid,
  }) {
    return InstallmentPlan(
      installmentNumber: installmentNumber ?? this.installmentNumber,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
    );
  }
}

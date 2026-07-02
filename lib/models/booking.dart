import 'dart:convert';
import 'package:vownote/models/payment.dart';

class Booking {
  final String id;
  final String customerName;
  final String brideName;
  final String groomName;
  final List<DateTime> eventDates;
  final double totalAmount;
  final double totalAdvance;
  final double advanceReceived;
  final String address;
  final String phoneNumber;
  final String alternatePhone;
  final String notes;
  final String bookingCategory; // 'Male', 'Female', 'None'
  final String diaryCode; // e.g., '14'
  final DateTime createdAt;
  final DateTime updatedAt;

  // New fields for advanced features
  final String businessType; // wedding, photography, catering, etc.
  final List<Payment> payments;
  final double taxRate; // Percentage (e.g., 18 for 18% GST)
  final double discountAmount; // Fixed discount amount
  final double discountPercentage; // Percentage discount
  final bool isClosed;

  Booking({
    required this.id,
    required this.customerName,
    this.brideName = '',
    this.groomName = '',
    required this.eventDates,
    required this.totalAmount,
    this.totalAdvance = 0,
    this.advanceReceived = 0,
    required this.address,
    required this.phoneNumber,
    this.alternatePhone = '',
    this.notes = '',
    this.bookingCategory = 'None',
    this.diaryCode = '',
    this.businessType = 'wedding',
    this.payments = const [],
    this.taxRate = 0,
    this.discountAmount = 0,
    this.discountPercentage = 0,
    this.isClosed = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Basic getters
  double get receivedAmount => advanceReceived;

  // Advanced calculation getters
  double get subtotal => totalAmount;

  double get calculatedDiscount {
    if (discountPercentage > 0) {
      return (totalAmount * discountPercentage) / 100;
    }
    return discountAmount;
  }

  double get amountAfterDiscount => totalAmount - calculatedDiscount;

  double get taxAmount => (amountAfterDiscount * taxRate) / 100;

  double get totalWithTax => amountAfterDiscount + taxAmount;

  double get pendingAmount => totalWithTax - advanceReceived;

  double get advancePending => totalAdvance - advanceReceived;

  double get totalPaidViaPayments {
    return payments.fold(0.0, (sum, payment) => sum + payment.amount);
  }

  // Identity logic for manager view: Prefix/DiaryCode (e.g., F/14)
  String get displayIdentity {
    if (diaryCode.isEmpty) return customerName;
    String prefix = '';
    if (bookingCategory == 'Male') prefix = 'M';
    if (bookingCategory == 'Female') prefix = 'F';
    return prefix.isNotEmpty ? '$prefix/$diaryCode' : diaryCode;
  }

  bool get isCompleted {
    if (eventDates.isEmpty) return false;
    final lastDate = eventDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return lastDate.isBefore(today);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'brideName': brideName,
      'groomName': groomName,
      'eventDates': jsonEncode(
        eventDates.map((e) => e.toIso8601String()).toList(),
      ),
      'totalAmount': totalAmount,
      'totalAdvance': totalAdvance,
      'advanceReceived': advanceReceived,
      'address': address,
      'phoneNumber': phoneNumber,
      'alternatePhone': alternatePhone,
      'notes': notes,
      'bookingCategory': bookingCategory,
      'diaryCode': diaryCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'businessType': businessType,
      'payments': jsonEncode(payments.map((p) => p.toMap()).toList()),
      'taxRate': taxRate,
      'discountAmount': discountAmount,
      'discountPercentage': discountPercentage,
      'isClosed': isClosed ? 1 : 0,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    // Parse payments list
    List<Payment> parsedPayments = [];
    try {
      if (map['payments'] != null) {
        final paymentsList = jsonDecode(map['payments'] as String) as List;
        parsedPayments = paymentsList
            .map((p) => Payment.fromMap(p as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      parsedPayments = [];
    }

    return Booking(
      id: map['id'],
      customerName:
          map['customerName'] ?? map['brideName'] ?? 'Unnamed Customer',
      brideName: map['brideName'] ?? '',
      groomName: map['groomName'] ?? '',
      eventDates: (jsonDecode(map['eventDates'] ?? '[]') as List)
          .map((e) => DateTime.parse(e))
          .toList(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      totalAdvance: (map['totalAdvance'] as num?)?.toDouble() ?? 0,
      advanceReceived: (map['advanceReceived'] as num?)?.toDouble() ?? 0,
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      alternatePhone: map['alternatePhone'] ?? '',
      notes: map['notes'] ?? '',
      bookingCategory: map['bookingCategory'] ?? 'None',
      diaryCode: map['diaryCode'] ?? '',
      businessType: map['businessType'] ?? 'wedding',
      payments: parsedPayments,
      taxRate: (map['taxRate'] as num?)?.toDouble() ?? 0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0,
      discountPercentage: (map['discountPercentage'] as num?)?.toDouble() ?? 0,
      isClosed: map['isClosed'] == 1,
      createdAt: DateTime.parse(
        map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Booking copyWith({
    String? id,
    String? customerName,
    String? brideName,
    String? groomName,
    List<DateTime>? eventDates,
    double? totalAmount,
    double? totalAdvance,
    double? advanceReceived,
    String? address,
    String? phoneNumber,
    String? alternatePhone,
    String? notes,
    String? bookingCategory,
    String? diaryCode,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? businessType,
    List<Payment>? payments,
    double? taxRate,
    double? discountAmount,
    double? discountPercentage,
    bool? isClosed,
  }) {
    return Booking(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      brideName: brideName ?? this.brideName,
      groomName: groomName ?? this.groomName,
      eventDates: eventDates ?? this.eventDates,
      totalAmount: totalAmount ?? this.totalAmount,
      totalAdvance: totalAdvance ?? this.totalAdvance,
      advanceReceived: advanceReceived ?? this.advanceReceived,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      alternatePhone: alternatePhone ?? this.alternatePhone,
      notes: notes ?? this.notes,
      bookingCategory: bookingCategory ?? this.bookingCategory,
      diaryCode: diaryCode ?? this.diaryCode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      businessType: businessType ?? this.businessType,
      payments: payments ?? this.payments,
      taxRate: taxRate ?? this.taxRate,
      discountAmount: discountAmount ?? this.discountAmount,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

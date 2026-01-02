import 'dart:convert';

class Booking {
  final String id;
  final String brideName;
  final String
  groomName; // Optional, user mentioned bride mostly but good to have
  final List<DateTime>
  eventDates; // "multiple means some wedding is 2 day 3 day"
  final double totalAmount;
  final double advanceAmount;
  final double receivedAmount; // New field for total collected
  final String address;
  final String phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.brideName,
    this.groomName = '',
    required this.eventDates,
    required this.totalAmount,
    required this.advanceAmount,
    double? receivedAmount, // Optional in constructor, defaults to advance
    required this.address,
    required this.phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : receivedAmount =
           receivedAmount ??
           advanceAmount, // Default to advance if not provided
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Pending is Total - Received (instead of Advance)
  // Pending is Total - Received (instead of Advance)
  double get pendingAmount => totalAmount - receivedAmount;

  // Helper: Completed status
  bool get isCompleted {
    if (eventDates.isEmpty) return false;
    // Check if the last event date has passed (yesterday or earlier)
    final lastDate = eventDates.reduce((a, b) => a.isAfter(b) ? a : b);
    final now = DateTime.now();
    // Use start of today to compare
    final today = DateTime(now.year, now.month, now.day);
    return lastDate.isBefore(today);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'brideName': brideName,
      'groomName': groomName,
      'eventDates': jsonEncode(
        eventDates.map((e) => e.toIso8601String()).toList(),
      ),
      'totalAmount': totalAmount,
      'advanceAmount': advanceAmount,
      'receivedAmount': receivedAmount,
      'address': address,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      brideName: map['brideName'],
      groomName: map['groomName'] ?? '',
      eventDates: (jsonDecode(map['eventDates']) as List)
          .map((e) => DateTime.parse(e))
          .toList(),
      totalAmount: map['totalAmount'],
      advanceAmount: map['advanceAmount'],
      receivedAmount:
          map['receivedAmount'] ??
          map['advanceAmount'], // Backwards compatibility
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }
}

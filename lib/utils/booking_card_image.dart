import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vownote/models/booking.dart';

class BookingCardImage extends StatelessWidget {
  final Booking booking;
  final bool isDarkMode;
  const BookingCardImage({
    super.key,
    required this.booking,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final bgColor = isDarkMode
        ? const Color(0xFF1C1C1E)
        : const Color(0xFFFBFBF9);
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final accentColor = isDarkMode ? Colors.amber[300]! : Colors.amber;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Vownote',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.favorite, color: accentColor, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  booking.brideName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    color: textColor,
                  ),
                ),
                Text(
                  '&',
                  style: TextStyle(
                    fontSize: 20,
                    color: secondaryTextColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Text(
                  booking.groomName.isNotEmpty ? booking.groomName : 'Groom',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _row(
            'Dates',
            booking.eventDates
                .map((d) => DateFormat('dd MMM yyyy').format(d))
                .join('\n'), // Multi-line dates
            textColor,
            secondaryTextColor,
          ),
          Divider(
            height: 30,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          _row('Contact', booking.phoneNumber, textColor, secondaryTextColor),
          const SizedBox(height: 8),
          _row(
            'Address',
            booking.address,
            textColor,
            secondaryTextColor,
          ), // Changed label to Address
          const SizedBox(height: 8),
          // Add Groom details clearly if present
          if (booking.groomName.isNotEmpty)
            _row('Groom', booking.groomName, textColor, secondaryTextColor),
          Divider(
            height: 30,
            color: isDarkMode ? Colors.grey[800] : Colors.grey[300],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _financial(
                'Total',
                booking.totalAmount,
                textColor,
                secondaryTextColor,
              ),
              _financial(
                'Received',
                booking.receivedAmount,
                Colors.green,
                secondaryTextColor,
              ), // Show Received instead of Advance
              _financial(
                'Due',
                booking.pendingAmount,
                Colors.red,
                secondaryTextColor,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Thank you for booking!',
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color textColor, Color? labelColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, color: labelColor, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _financial(
    String label,
    double amount,
    Color valueColor,
    Color? labelColor,
  ) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(fontSize: 10, color: labelColor, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

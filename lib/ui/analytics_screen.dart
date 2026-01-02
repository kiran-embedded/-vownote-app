import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Booking> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookings = await DatabaseService().getBookings();
    setState(() {
      _allBookings = bookings;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final totalRevenue = _allBookings.fold(
      0.0,
      (sum, b) => sum + b.totalAmount,
    );
    final totalCollected = _allBookings.fold(
      0.0,
      (sum, b) => sum + b.receivedAmount,
    );
    final totalDue = _allBookings.fold(0.0, (sum, b) => sum + b.pendingAmount);
    final totalBookings = _allBookings.length;

    // Month-wise grouping
    final Map<String, int> monthCounts = {};
    for (var b in _allBookings) {
      if (b.eventDates.isEmpty) continue;
      final firstDate = List<DateTime>.from(b.eventDates)..sort();
      final key = DateFormat('MMMM yyyy').format(firstDate.first);
      monthCounts[key] = (monthCounts[key] ?? 0) + 1;
    }

    final sortedMonths = monthCounts.keys.toList()
      ..sort((a, b) {
        final da = DateFormat('MMMM yyyy').parse(a);
        final db = DateFormat('MMMM yyyy').parse(b);
        return da.compareTo(db);
      });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Business Insights',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(
            totalRevenue,
            totalCollected,
            totalDue,
            totalBookings,
          ),
          const SizedBox(height: 24),
          Text(
            'MONTHLY WEDDING LOAD',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...sortedMonths.map(
            (month) => _buildMonthTile(month, monthCounts[month]!),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double rev, double coll, double due, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD4AF37),
            const Color(0xFFD4AF37).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'TOTAL BUSINESS',
                '₹${NumberFormat.compact().format(rev)}',
                Colors.white,
              ),
              _buildStatItem('TOTAL EVENTS', count.toString(), Colors.white),
            ],
          ),
          const Divider(height: 32, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'COLLECTED',
                '₹${NumberFormat.compact().format(coll)}',
                Colors.white.withOpacity(0.9),
              ),
              _buildStatItem(
                'OUTSTANDING',
                '₹${NumberFormat.compact().format(due)}',
                Colors.red[100]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.7),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthTile(String month, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(month, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count Weddings',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Booking> _allBookings = [];
  bool _isLoading = true;

  double _totalRevenue = 0;
  double _totalCollected = 0;
  double _totalDue = 0;
  int _totalBookingsCount = 0;
  List<String> _sortedMonths = [];
  Map<String, int> _monthCounts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bookings = await DatabaseService().getBookings();

    // Perform calculations in one pass to save CPU/RAM
    double revenue = 0;
    double collected = 0;
    double due = 0;
    final Map<String, int> counts = {};

    for (var b in bookings) {
      revenue += b.totalAmount;
      collected += b.receivedAmount;
      due += b.pendingAmount;

      if (b.eventDates.isNotEmpty) {
        final firstDate = List<DateTime>.from(b.eventDates)..sort();
        final key = DateFormat('MMMM yyyy').format(firstDate.first);
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    final sorted = counts.keys.toList()
      ..sort((a, b) {
        final da = DateFormat('MMMM yyyy').parse(a);
        final db = DateFormat('MMMM yyyy').parse(b);
        return da.compareTo(db);
      });

    setState(() {
      _allBookings = bookings;
      _totalRevenue = revenue;
      _totalCollected = collected;
      _totalDue = due;
      _totalBookingsCount = bookings.length;
      _monthCounts = counts;
      _sortedMonths = sorted;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Business Insights',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 24, // Sized for the collapsed state Title
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildLuxeSummary(
                      _totalRevenue,
                      _totalCollected,
                      _totalDue,
                      _totalBookingsCount,
                      isDark,
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutQuad),
                const SizedBox(height: 32),
                Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Monthly Performance',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.1, curve: Curves.easeOutQuad),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final month = _sortedMonths[index];
                final count = _monthCounts[month] ?? 0;
                return _buildMonthTile(month, count, isDark)
                    .animate()
                    .fadeIn(delay: (index * 50).ms)
                    .slideX(begin: 0.1, curve: Curves.easeOut);
              }, childCount: _sortedMonths.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 60)),
        ],
      ),
    );
  }

  Widget _buildLuxeSummary(
    double rev,
    double coll,
    double due,
    int count,
    bool isDark,
  ) {
    return Column(
      children: [
        // Main Business Pill (Dynamic Island style)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL VALUATION',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${NumberFormat.decimalPattern().format(rev)}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count Events',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
        const SizedBox(height: 16),
        // Secondary Stats Pills
        Row(
          children: [
            Expanded(
              child: _buildSecondaryPill(
                'COLLECTED',
                '₹${NumberFormat.compact().format(coll)}',
                isDark ? const Color(0xFF1C1C1E) : Colors.white,
                Colors.green,
                isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryPill(
                'OUTSTANDING',
                '₹${NumberFormat.compact().format(due)}',
                isDark ? const Color(0xFF1C1C1E) : Colors.white,
                isDark
                    ? const Color(0xFFFF453A)
                    : const Color(0xFFFF2D55), // Apple System Red
                isDark,
                isWarning: true,
              ),
            ),
          ],
        ).animate().slideY(begin: 0.2).fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _buildSecondaryPill(
    String label,
    String value,
    Color bg,
    Color accent,
    bool isDark, {
    bool isWarning = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              color: isWarning
                  ? accent
                  : (isDark ? Colors.white : Colors.black),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthTile(String month, int count, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          month,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            '$count Weddings',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

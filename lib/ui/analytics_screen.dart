import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vownote/utils/pdf_generator.dart';
import 'package:vownote/services/localization_service.dart';
import 'package:vownote/utils/haptics.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Booking> _allBookings = [];
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

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

  Future<void> _generateGlobalPdf() async {
    Haptics.medium();
    setState(() => _isGeneratingPdf = true);

    // Simulate premium processing feel
    await Future.delayed(const Duration(seconds: 1));

    try {
      await PdfGenerator.generateGlobalReport(_allBookings);
      Haptics.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
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
                      fontSize: 24,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: _generateGlobalPdf,
                    icon: const Icon(
                      Icons.picture_as_pdf_outlined,
                      color: Color(0xFFD4AF37),
                    ),
                    tooltip: tr('full_report'),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildSummary(
                      _totalRevenue,
                      _totalCollected,
                      _totalDue,
                      _totalBookingsCount,
                      isDark,
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                    const SizedBox(height: 32),
                    Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Monthly Performance',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _generateGlobalPdf,
                                icon: const Icon(
                                  Icons.print_outlined,
                                  size: 16,
                                ),
                                label: Text(
                                  tr('full_report'),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFD4AF37),
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.1),
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
                        .slideX(begin: 0.1);
                  }, childCount: _sortedMonths.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
          if (_isGeneratingPdf) _buildPdfLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildPdfLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(
                radius: 20,
                color: Color(0xFFD4AF37),
              ),
              const SizedBox(height: 24),
              Text(
                tr('generating_pdf'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildSummary(
    double rev,
    double coll,
    double due,
    int count,
    bool isDark,
  ) {
    return Column(
      children: [
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
                isDark ? const Color(0xFFFF453A) : const Color(0xFFFF2D55),
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

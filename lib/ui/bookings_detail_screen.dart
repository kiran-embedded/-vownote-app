import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/services/localization_service.dart';
import 'package:vownote/ui/booking_form.dart';
import 'package:vownote/utils/calm_page_route.dart';
import 'package:vownote/utils/haptics.dart';

/// A beautiful dedicated screen to show a pre-filtered subset of bookings.
/// Used when tapping stat cards: Active, Pending Amount, Completed, This Month.
class BookingsDetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Booking> bookings;
  final Color accentColor;
  final IconData icon;
  final String? amountLabel; // e.g. "Total Pending" or "Total Revenue"

  const BookingsDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.bookings,
    required this.accentColor,
    required this.icon,
    this.amountLabel,
  });

  @override
  State<BookingsDetailScreen> createState() => _BookingsDetailScreenState();
}

class _BookingsDetailScreenState extends State<BookingsDetailScreen> {
  late List<Booking> _bookings;
  String _search = '';
  String _sort = 'Event Date';

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _bookings = List.from(widget.bookings);
    _applySort();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _applySort() {
    if (_sort == 'Newest') {
      _bookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sort == 'Oldest') {
      _bookings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sort == 'Event Date') {
      _bookings.sort((a, b) {
        if (a.eventDates.isEmpty) return 1;
        if (b.eventDates.isEmpty) return -1;
        return a.eventDates.first.compareTo(b.eventDates.first);
      });
    } else if (_sort == 'Amount') {
      _bookings.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }
  }

  List<Booking> get _filtered {
    if (_search.isEmpty) return _bookings;
    final q = _search.toLowerCase();
    return _bookings.where((b) =>
      b.brideName.toLowerCase().contains(q) ||
      b.groomName.toLowerCase().contains(q) ||
      b.customerName.toLowerCase().contains(q) ||
      b.phoneNumber.contains(q) ||
      b.address.toLowerCase().contains(q) ||
      b.notes.toLowerCase().contains(q) ||
      b.id.toLowerCase().contains(q),
    ).toList();
  }

  double get _totalAmount => _filtered.fold(0, (s, b) => s + b.totalAmount);
  double get _totalPending => _filtered.fold(0, (s, b) => s + b.pendingAmount);
  double get _totalReceived => _filtered.fold(0, (s, b) => s + b.advanceReceived);

  Map<String, List<Booking>> _groupByMonth(List<Booking> list) {
    final Map<String, List<Booking>> grouped = {};
    for (var b in list) {
      if (b.eventDates.isEmpty) {
        grouped.putIfAbsent('No Date', () => []).add(b);
        continue;
      }
      final dates = List<DateTime>.from(b.eventDates)..sort();
      final key = DateFormat('MMMM yyyy', LocalizationService().currentLanguage).format(dates.first);
      grouped.putIfAbsent(key, () => []).add(b);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final filtered = _filtered;
    final grouped = _groupByMonth(filtered);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, filtered.length, fmt),
            _buildSearchSortRow(),
            _buildSummaryRow(fmt, filtered),
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: grouped.entries.map((entry) {
                        return _buildMonthGroup(context, entry.key, entry.value, fmt);
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int count, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border(
          bottom: BorderSide(color: widget.accentColor.withValues(alpha: 0.15), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: widget.accentColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$count bookings',
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildSearchSortRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      autofocus: false,
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search by name, phone...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        filled: false,
                      ),
                    ),
                  ),
                  if (_search.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                      child: Icon(Icons.close, color: Colors.grey[600], size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() { _sort = v; _applySort(); }),
            color: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sort, color: Color(0xFFD4AF37), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _sort,
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            itemBuilder: (_) => ['Newest', 'Oldest', 'Event Date', 'Amount'].map((opt) =>
              PopupMenuItem(
                value: opt,
                child: Row(
                  children: [
                    Icon(
                      _sort == opt ? Icons.check : Icons.radio_button_unchecked,
                      color: _sort == opt ? const Color(0xFFD4AF37) : Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Text(opt, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiveConfirmSheet(BuildContext context, Booking booking, NumberFormat fmt) {
    final name = booking.brideName.isNotEmpty && booking.groomName.isNotEmpty
        ? '${booking.brideName} & ${booking.groomName}'
        : booking.customerName;
    final pending = fmt.format(booking.pendingAmount);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Warning icon
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.teal.withOpacity(0.3), width: 2),
            ),
            child: const Icon(Icons.payments_outlined, color: Colors.teal, size: 36),
          )
            .animate()
            .scale(begin: const Offset(0.7, 0.7), duration: 300.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 20),
          Text(
            'Mark Payment Received?',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 20),
          // Amount highlight
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  'Pending Amount',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(
                  pending,
                  style: const TextStyle(
                    color: Colors.teal,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )
            .animate()
            .fadeIn(delay: 100.ms, duration: 300.ms)
            .slideY(begin: 0.1, end: 0),
          const SizedBox(height: 12),
          // Warning note
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber[600], size: 15),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This will mark the full pending amount as received. This cannot be undone easily.',
                  style: TextStyle(color: Colors.amber[700], fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Haptics.light();
                    Navigator.pop(context, false);
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    Haptics.heavy();
                    Navigator.pop(context, true);
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Confirm $pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                  .animate()
                  .shimmer(delay: 400.ms, duration: 1200.ms, color: Colors.white24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(NumberFormat fmt, List<Booking> list) {
    final chips = <Map<String, dynamic>>[];
    if (widget.amountLabel != null) {
      chips.add({'label': widget.amountLabel!, 'value': fmt.format(_totalPending), 'color': Colors.amber});
    }
    chips.add({'label': 'Total Value', 'value': fmt.format(_totalAmount), 'color': widget.accentColor});
    chips.add({'label': 'Received', 'value': fmt.format(_totalReceived), 'color': Colors.green});

    return SizedBox(
      height: 64,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        itemCount: chips.length,
        itemBuilder: (_, i) {
          final c = chips[i];
          final color = c['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['label'] as String, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
                Text(c['value'] as String, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMonthGroup(BuildContext context, String month, List<Booking> bookings, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              month.toUpperCase(),
              style: GoogleFonts.outfit(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${bookings.length}',
                style: TextStyle(color: widget.accentColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...bookings.asMap().entries.map((entry) {
          final i = entry.key;
          final b = entry.value;
          return _buildBookingCard(context, b, fmt)
            .animate(delay: (i * 40).ms)
            .fadeIn(duration: 200.ms)
            .slideY(begin: 0.08, end: 0);
        }),
      ],
    );
  }

  String _buildShareMessage(Booking booking) {
    final dateStr = booking.eventDates.isEmpty
        ? 'your event'
        : DateFormat('d MMM yyyy').format(booking.eventDates.first);
    final name = booking.brideName.isNotEmpty && booking.groomName.isNotEmpty
        ? '${booking.brideName} & ${booking.groomName}'
        : booking.customerName;
    return '🎉 Thank you for choosing us, $name!\n\n'
        'Your booking on $dateStr has been successfully ${booking.isClosed ? "completed" : "registered"}.\n\n'
        'We truly appreciate your trust and look forward to serving you again. 💛\n\n'
        '— ${widget.title}';
  }

  Future<void> _shareViaWhatsApp(Booking booking) async {
    Haptics.success();
    final msg = Uri.encodeComponent(_buildShareMessage(booking));
    final phone = booking.phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final waUrl = phone.isNotEmpty
        ? 'https://wa.me/$phone?text=$msg'
        : 'https://wa.me/?text=$msg';
    final uri = Uri.parse(waUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Share.share(_buildShareMessage(booking));
    }
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, NumberFormat fmt) {
    final isPaid = booking.pendingAmount <= 0;
    final pendingColor = isPaid ? Colors.green : Colors.orange;
    final String dateStr = booking.eventDates.isEmpty
        ? 'No date'
        : DateFormat('d MMM yyyy').format(booking.eventDates.first);
    final bool canMarkReceived = widget.amountLabel != null && !isPaid;

    Future<void> markAsReceived() async {
      // Show premium confirmation bottom sheet
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _buildReceiveConfirmSheet(ctx, booking, fmt),
      );
      if (confirmed != true) return;

      Haptics.success();
      final updated = booking.copyWith(
        advanceReceived: booking.totalWithTax, // zeroes out pendingAmount
      );
      await DatabaseService().updateBooking(updated);
      if (mounted) {
        final idx = _bookings.indexWhere((b) => b.id == booking.id);
        if (idx != -1) {
          setState(() {
            _bookings[idx] = updated;
          });
        }
      }
    }

    return Dismissible(
      key: Key('detail_${booking.id}'),
      direction: canMarkReceived
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // Swipe right = WhatsApp share
          await _shareViaWhatsApp(booking);
        } else if (dir == DismissDirection.endToStart) {
          // Swipe left = mark as received
          await markAsReceived();
        }
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade800, Colors.green.shade400],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        child: const Row(
          children: [
            Icon(Icons.send, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Send thank you', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
      secondaryBackground: canMarkReceived
          ? Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade400, Colors.teal.shade800],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 26),
                  const SizedBox(height: 4),
                  Text(
                    'Mark Received\n${fmt.format(booking.pendingAmount)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : null,
      child: GestureDetector(
        onTap: () {
          Haptics.light();
          Navigator.push(
            context,
            CalmPageRoute(builder: (_) => BookingFormScreen(booking: booking)),
          ).then((_) async {
            final updated = await DatabaseService().getBookings();
            final found = updated.where((b) => b.id == booking.id);
            if (found.isNotEmpty && mounted) {
              final idx = _bookings.indexWhere((b) => b.id == booking.id);
              if (idx != -1) {
                setState(() {
                  _bookings[idx] = found.first;
                  _applySort();
                });
              }
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.brideName.isNotEmpty && booking.groomName.isNotEmpty
                                ? '${booking.brideName} & ${booking.groomName}'
                                : booking.customerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pendingColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPaid ? 'Paid ✓' : fmt.format(booking.pendingAmount),
                            style: TextStyle(
                              color: pendingColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 11),
                        const SizedBox(width: 4),
                        Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        if (booking.address.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 11),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              booking.address,
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          fmt.format(booking.totalAmount),
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            if (canMarkReceived) ...[
                              Icon(Icons.swipe_left_alt, color: Colors.teal.withValues(alpha: 0.6), size: 13),
                              const SizedBox(width: 2),
                              Text('← received', style: TextStyle(color: Colors.teal[400], fontSize: 10, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 8),
                            ],
                            Icon(Icons.swipe_right_alt, color: Colors.green.withValues(alpha: 0.5), size: 13),
                            const SizedBox(width: 2),
                            Text('share →', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Colors.grey[700], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.accentColor, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            'No ${widget.title}',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _search.isNotEmpty
                ? 'No results for "$_search"'
                : 'Nothing to show here yet',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

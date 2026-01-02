import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/ui/booking_form.dart';
import 'package:vownote/utils/pdf_generator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vownote/utils/booking_card_image.dart';
import 'package:vownote/ui/settings_screen.dart';
import 'package:vownote/ui/analytics_screen.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:vownote/utils/branding_utils.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Booking> _allBookings = [];
  List<Booking> _filteredBookings = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedMonthFilter = 'All';

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  final ScreenshotController _screenshotController = ScreenshotController();
  Booking? _bookingToCapture;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (_allBookings.isEmpty) setState(() => _isLoading = true);
    final bookings = await DatabaseService().getBookings();
    if (mounted) {
      setState(() {
        _allBookings = bookings;
        _isLoading = false;
      });
      _applyFilters();
    }
  }

  void _filterBookings(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final q = _searchQuery.toLowerCase();
    _filteredBookings = _allBookings.where((b) {
      final matchesSearch =
          q.isEmpty ||
          b.brideName.toLowerCase().contains(q) ||
          b.groomName.toLowerCase().contains(q) ||
          b.phoneNumber.contains(q) ||
          b.address.toLowerCase().contains(q);

      if (!matchesSearch) return false;
      if (_selectedMonthFilter == 'All') return true;
      if (b.eventDates.isEmpty) return false;
      final firstDate = List<DateTime>.from(b.eventDates)..sort();
      final monthKey = DateFormat('MMM').format(firstDate.first);
      return monthKey == _selectedMonthFilter;
    }).toList();
  }

  Map<String, List<Booking>> _groupBookingsByMonth() {
    final Map<String, List<Booking>> grouped = {};
    for (var booking in _filteredBookings) {
      if (booking.eventDates.isEmpty) continue;
      final dates = List<DateTime>.from(booking.eventDates)..sort();
      final key = DateFormat('MMMM yyyy').format(dates.first);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(booking);
    }
    return grouped;
  }

  Future<void> _shareText(String text) async {
    await Share.share(text);
  }

  Future<void> _shareScreenshot(Booking booking, bool isDark) async {
    setState(() => _bookingToCapture = booking);
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      final image = await _screenshotController.captureFromLongWidget(
        BookingCardImage(booking: booking, isDarkMode: isDark),
        context: context,
        pixelRatio: 3.0,
      );
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/booking_${booking.id}.png');
      await file.writeAsBytes(image);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Booking Confirmation for ${booking.brideName}');
    } catch (e) {
      debugPrint('Screenshot Error: $e');
    } finally {
      setState(() => _bookingToCapture = null);
    }
  }

  void _toggleSelectionMode(String? initialId) {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      _selectedIds.clear();
      if (_isSelectionMode && initialId != null) {
        _selectedIds.add(initialId);
        Haptics.selection();
      }
    });
  }

  void _toggleItemSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      Haptics.selection();
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${_selectedIds.length} Bookings?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      for (var id in _selectedIds) {
        await DatabaseService().deleteBooking(id);
      }
      Haptics.success();
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
      _loadBookings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedBookings = _groupBookingsByMonth();
    final sortedKeys = groupedBookings.keys.toList()
      ..sort((a, b) {
        final da = DateFormat('MMMM yyyy').parse(a);
        final db = DateFormat('MMMM yyyy').parse(b);
        return da.compareTo(db);
      });

    final months = [
      'All',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(
                  context,
                ).scaffoldBackgroundColor.withOpacity(0.95),
                surfaceTintColor: Colors.transparent,
                pinned: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
                  title: Text(
                    _isSelectionMode
                        ? '${_selectedIds.length} Selected'
                        : 'VowNote',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.displayLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.analytics_outlined,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                  if (_isSelectionMode)
                    TextButton(
                      onPressed: () => setState(() {
                        _isSelectionMode = false;
                        _selectedIds.clear();
                      }),
                      child: const Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                        _loadBookings();
                      },
                      icon: Icon(
                        Icons.settings,
                        color: Theme.of(context).iconTheme.color,
                      ),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        onChanged: _filterBookings,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: Icon(
                            Icons.search,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.black54
                                : Colors.grey,
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardTheme.color,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    SizedBox(
                      height: 50,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: months.length,
                        itemBuilder: (context, i) {
                          final m = months[i];
                          final isSelected = _selectedMonthFilter == m;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(m),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  Haptics.light();
                                  setState(() {
                                    _selectedMonthFilter = m;
                                    _applyFilters();
                                  });
                                }
                              },
                              selectedColor: const Color(0xFFD4AF37),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black87
                                          : Colors.grey),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).cardTheme.color,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              showCheckmark: false,
                              side: BorderSide.none,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_isLoading && groupedBookings.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Bookings found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_isLoading && groupedBookings.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final monthKey = sortedKeys[index];
                    final monthBookings = groupedBookings[monthKey]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                monthKey.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final isDark =
                                      Theme.of(context).brightness ==
                                      Brightness.dark;
                                  await PdfGenerator.generateMonthlyReport(
                                    monthKey,
                                    monthBookings,
                                    isDarkMode: isDark,
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.amber,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Export PDF',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: monthBookings.asMap().entries.map((
                              entry,
                            ) {
                              final i = entry.key;
                              final booking = entry.value;
                              final isLast = i == monthBookings.length - 1;
                              final isSelected = _selectedIds.contains(
                                booking.id,
                              );

                              return RepaintBoundary(
                                    child: GestureDetector(
                                      onLongPress: () {
                                        if (!_isSelectionMode) {
                                          Haptics.medium();
                                          _toggleSelectionMode(booking.id);
                                        }
                                      },
                                      onTap: () async {
                                        if (_isSelectionMode) {
                                          _toggleItemSelection(booking.id);
                                        } else {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => BookingFormScreen(
                                                booking: booking,
                                              ),
                                            ),
                                          );
                                          _loadBookings();
                                        }
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Column(
                                          children: [
                                            ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              leading: _isSelectionMode
                                                  ? Icon(
                                                      isSelected
                                                          ? Icons.check_circle
                                                          : Icons
                                                                .circle_outlined,
                                                      color: isSelected
                                                          ? Theme.of(
                                                              context,
                                                            ).primaryColor
                                                          : Colors.grey,
                                                    )
                                                  : null,
                                              title: Text(
                                                booking.brideName,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      decoration:
                                                          booking.isCompleted
                                                          ? TextDecoration
                                                                .lineThrough
                                                          : null,
                                                      color: booking.isCompleted
                                                          ? Colors.grey
                                                          : null,
                                                    ),
                                              ),
                                              subtitle: Text(
                                                "${booking.eventDates.map((d) => DateFormat('d').format(d)).join(', ')} • ₹${booking.totalAmount.toStringAsFixed(0)}",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color:
                                                          Theme.of(
                                                                context,
                                                              ).brightness ==
                                                              Brightness.light
                                                          ? Colors.black54
                                                          : Colors.white60,
                                                    ),
                                              ),
                                              trailing: _isSelectionMode
                                                  ? null
                                                  : Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        if (booking
                                                                .pendingAmount >
                                                            0)
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      10,
                                                                  vertical: 4,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color: Colors.red
                                                                  .withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              "Due: ₹${booking.pendingAmount.toStringAsFixed(0)}",
                                                              style: const TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    Colors.red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons.ios_share,
                                                            color: Colors.green,
                                                            size: 18,
                                                          ),
                                                          onPressed: () =>
                                                              _showShareOptions(
                                                                context,
                                                                booking,
                                                              ),
                                                        ),
                                                        Icon(
                                                          Icons.chevron_right,
                                                          size: 20,
                                                          color:
                                                              Theme.of(
                                                                    context,
                                                                  ).brightness ==
                                                                  Brightness
                                                                      .light
                                                              ? Colors.black26
                                                              : Colors.white24,
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                            if (!isLast)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 16,
                                                  right: 16,
                                                ),
                                                child: Divider(
                                                  height: 1,
                                                  thickness: 0.5,
                                                  color: Colors.grey
                                                      .withOpacity(
                                                        Theme.of(
                                                                  context,
                                                                ).brightness ==
                                                                Brightness.light
                                                            ? 0.1
                                                            : 0.05,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                  .animate(
                                    onPlay: (controller) =>
                                        controller.repeat(reverse: true),
                                    autoPlay: false,
                                  )
                                  .scale(
                                    end: const Offset(0.98, 0.98),
                                    duration: 100.ms,
                                    curve: Curves.easeInOut,
                                  )
                                  .animate()
                                  .fadeIn(delay: (i * 30).ms, duration: 400.ms)
                                  .slideX(
                                    begin: 0.05,
                                    delay: (i * 30).ms,
                                    duration: 400.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  }, childCount: sortedKeys.length),
                ),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(child: GitHubWatermark(compact: true)),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
          if (_bookingToCapture != null)
            Positioned(
              left: -1000,
              child: BookingCardImage(
                booking: _bookingToCapture!,
                isDarkMode: Theme.of(context).brightness == Brightness.dark,
              ),
            ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? FloatingActionButton.extended(
              onPressed: _deleteSelected,
              backgroundColor: Colors.red,
              icon: const Icon(Icons.delete),
              label: Text('Delete (${_selectedIds.length})'),
            )
          : FloatingActionButton(
              backgroundColor: const Color(0xFFD4AF37),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              onPressed: () async {
                Haptics.light();
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookingFormScreen()),
                );
                _loadBookings();
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  void _showShareOptions(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.green),
              title: const Text('Share Text (WhatsApp/Other)'),
              onTap: () {
                Navigator.pop(context);
                _shareText(_formatBookingMessage(booking));
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.amber),
              title: const Text('Share Card Image'),
              onTap: () {
                Navigator.pop(context);
                _shareScreenshot(
                  booking,
                  Theme.of(context).brightness == Brightness.dark,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatBookingMessage(Booking booking) {
    final dates = booking.eventDates
        .map((d) => DateFormat('dd MMM yyyy').format(d))
        .join(', ');
    return """Wedding Booking Confirmed!

Bride: ${booking.brideName}
Groom: ${booking.groomName.isNotEmpty ? booking.groomName : 'N/A'}

📅 Dates: $dates
📍 Address: ${booking.address.isNotEmpty ? booking.address : 'N/A'}
📞 Contact: ${booking.phoneNumber}

Financials:
Total: ₹${booking.totalAmount.toStringAsFixed(0)}
Received: ₹${booking.receivedAmount.toStringAsFixed(0)}
Due: ₹${booking.pendingAmount.toStringAsFixed(0)}

Thank you!""";
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:vownote/utils/display_engine.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/services/backup_service.dart';
import 'package:vownote/ui/booking_form.dart';
import 'package:vownote/utils/pdf_generator.dart';
import 'package:vownote/services/localization_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vownote/utils/booking_card_image.dart';
import 'package:vownote/ui/settings_screen.dart';
import 'package:vownote/ui/analytics_screen.dart';
import 'package:vownote/ui/calendar_screen.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:vownote/utils/calm_page_route.dart';
import 'package:vownote/services/business_service.dart';
import 'dart:ui';
import 'package:vownote/ui/widgets/shimmer_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vownote/services/google_drive_service.dart';
import 'package:vownote/models/business_type.dart';
import 'package:vownote/ui/bookings_detail_screen.dart';

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
  final Set<String> _deletingIds = {};
  int _activeTab = 0; // 0: Active, 1: Closed & Completed
  int _currentBottomNavIndex = 0;

  // New filtering options requested
  String _dateRangeFilter = 'All'; // Today, This Week, This Month, Last Month, Custom Range
  DateTimeRange? _customDateRange;
  String? _selectedClientFilter;
  String _paymentStatusFilter = 'All'; // All, Paid, Advance, Due, Upcoming, Cancelled
  String? _serviceFilter;
  String? _locationFilter;
  String? _amountRangeFilter;
  String _sortBy = 'Event Date'; // Newest, Oldest, Event Date, Amount

  // Clickable header chips filters
  bool _filterActiveOnly = false;
  bool _filterDueOnly = false;
  bool _filterTodayOnly = false;

  bool _showFilters = false;
  late PageController _pageController;

  final ScreenshotController _screenshotController = ScreenshotController();
  Booking? _bookingToCapture;
  bool _isFlashing = false;
  final FocusNode _searchFocus = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  String? _activeDismissibleId;
  int _lastHapticLevel = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _searchFocus.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentBottomNavIndex);
    _initRestoreAndLoad();
  }

  Future<void> _initRestoreAndLoad() async {
    setState(() => _isLoading = true);
    await _loadBookings();
    
    if (_allBookings.isEmpty) {
      try {
        final restored = await BackupService().checkForAutoRestore().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⚠️ Auto-restore check timed out');
            return false;
          },
        );
        if (restored) {
          Haptics.success();
          await _loadBookings();
        }
      } catch (e) {
        debugPrint('Error performing auto-restore check: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _loadBookings() async {
    if (_allBookings.isEmpty) {
      if (mounted) setState(() => _isLoading = true);
    }
    final currentBusiness = BusinessService().currentType.name;
    final bookings = await DatabaseService().getBookings(
      businessType: currentBusiness,
    );
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
      // 1. Better Search (Client Name, Phone, Email, Location/Address, Event/Service type, ID)
      if (q.isNotEmpty) {
        final matchesSearch =
            b.brideName.toLowerCase().contains(q) ||
            b.groomName.toLowerCase().contains(q) ||
            b.customerName.toLowerCase().contains(q) ||
            b.phoneNumber.contains(q) ||
            b.alternatePhone.contains(q) ||
            b.address.toLowerCase().contains(q) ||
            b.businessType.toLowerCase().contains(q) ||
            b.notes.toLowerCase().contains(q) ||
            b.id.toLowerCase().contains(q);
        if (!matchesSearch) return false;
      }

      // 2. Clickable Header chips override
      if (_filterActiveOnly && b.isClosed) return false;
      if (_filterDueOnly && b.pendingAmount <= 0) return false;
      if (_filterTodayOnly) {
        final today = DateTime.now();
        final hasToday = b.eventDates.any((d) => d.year == today.year && d.month == today.month && d.day == today.day);
        if (!hasToday) return false;
      }

      // If no override chips are active, filter by tab selection
      if (!_filterActiveOnly && !_filterDueOnly && !_filterTodayOnly) {
        final matchesTab = _activeTab == 0 ? !b.isClosed : b.isClosed;
        if (!matchesTab) return false;
      }

      // 3. Client Filter
      if (_selectedClientFilter != null && b.customerName != _selectedClientFilter) return false;

      // 4. Payment Status Filter
      if (_paymentStatusFilter != 'All') {
        if (_paymentStatusFilter == 'Paid' && b.pendingAmount > 0) return false;
        if (_paymentStatusFilter == 'Advance' && (b.advanceReceived <= 0 || b.pendingAmount <= 0)) return false;
        if (_paymentStatusFilter == 'Due' && b.pendingAmount <= 0) return false;
        if (_paymentStatusFilter == 'Upcoming' && b.isClosed) return false;
        if (_paymentStatusFilter == 'Cancelled' && !b.isClosed) return false;
      }

      // 5. Service Type Filter
      if (_serviceFilter != null) {
        final s = _serviceFilter!.toLowerCase();
        final matchesService = b.businessType.toLowerCase().contains(s) || b.notes.toLowerCase().contains(s);
        if (!matchesService) return false;
      }

      // 6. Location Filter
      if (_locationFilter != null) {
        final loc = _locationFilter!.toLowerCase();
        final matchesLoc = b.address.toLowerCase().contains(loc);
        if (!matchesLoc) return false;
      }

      // 7. Amount Range Filter
      if (_amountRangeFilter != null) {
        final total = b.totalAmount;
        if (_amountRangeFilter == '₹0–₹10k' && total > 10000) return false;
        if (_amountRangeFilter == '₹10k–₹50k' && (total < 10000 || total > 50000)) return false;
        if (_amountRangeFilter == '₹50k+' && total < 50000) return false;
      }

      // 8. Month Chips Filter (Clicking Jul only filters July bookings instantly)
      if (_selectedMonthFilter != 'All') {
        if (b.eventDates.isEmpty) return false;
        final firstDate = List<DateTime>.from(b.eventDates)..sort();
        final monthKey = DateFormat('MMM', LocalizationService().currentLanguage).format(firstDate.first);
        if (monthKey != _selectedMonthFilter) return false;
      }

      // 9. Date Range Filter
      if (_dateRangeFilter != 'All') {
        if (b.eventDates.isEmpty) return false;
        final eventDate = b.eventDates.first;
        final now = DateTime.now();
        if (_dateRangeFilter == 'Today') {
          if (eventDate.year != now.year || eventDate.month != now.month || eventDate.day != now.day) return false;
        } else if (_dateRangeFilter == 'This Week') {
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6));
          if (eventDate.isBefore(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day)) ||
              eventDate.isAfter(DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59))) return false;
        } else if (_dateRangeFilter == 'This Month') {
          if (eventDate.year != now.year || eventDate.month != now.month) return false;
        } else if (_dateRangeFilter == 'Last Month') {
          final lastMonth = now.month == 1 ? 12 : now.month - 1;
          final lastMonthYear = now.month == 1 ? now.year - 1 : now.year;
          if (eventDate.year != lastMonthYear || eventDate.month != lastMonth) return false;
        } else if (_dateRangeFilter == 'Custom Range' && _customDateRange != null) {
          if (eventDate.isBefore(_customDateRange!.start) || eventDate.isAfter(_customDateRange!.end.add(const Duration(days: 1)))) return false;
        }
      }

      return true;
    }).toList();

    // 10. Sort By
    if (_sortBy == 'Newest') {
      _filteredBookings.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'Oldest') {
      _filteredBookings.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'Event Date') {
      _filteredBookings.sort((a, b) {
        if (a.eventDates.isEmpty) return 1;
        if (b.eventDates.isEmpty) return -1;
        return a.eventDates.first.compareTo(b.eventDates.first);
      });
    } else if (_sortBy == 'Amount') {
      _filteredBookings.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    }
  }

  Map<String, List<Booking>> _groupBookingsByMonth() {
    final Map<String, List<Booking>> grouped = {};
    for (var booking in _filteredBookings) {
      if (booking.eventDates.isEmpty) continue;
      final dates = List<DateTime>.from(booking.eventDates)..sort();
      final key = DateFormat(
        'MMMM yyyy',
        LocalizationService().currentLanguage,
      ).format(dates.first);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(booking);
    }
    return grouped;
  }

  Future<void> _shareText(String text) async {
    await Share.share(text);
  }

  Future<void> _shareScreenshot(Booking booking, bool isDark) async {
    setState(() {
      _bookingToCapture = booking;
      _isFlashing = true;
    });
    Haptics.selection();
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _isFlashing = false);

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
        title: Text('${tr("delete_bookings")} ${_selectedIds.length}?'),
        content: Text(tr('cannot_undo')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        _deletingIds.addAll(_selectedIds);
      });
      Haptics.success();
      await Future.delayed(const Duration(milliseconds: 400));

      for (var id in _selectedIds) {
        await DatabaseService().deleteBooking(id);
      }
      setState(() {
        _isSelectionMode = false;
        _deletingIds.clear();
        _selectedIds.clear();
      });
      _loadBookings();
    }
  }

  Future<void> _deleteBooking(String id) async {
    setState(() {
      _deletingIds.add(id);
    });
    Haptics.medium();
    await Future.delayed(const Duration(milliseconds: 400));
    await DatabaseService().deleteBooking(id);
    Haptics.success();
    setState(() {
      _deletingIds.remove(id);
    });
    _loadBookings();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getCurrentMonthShort() {
    return DateFormat('MMM', LocalizationService().currentLanguage).format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final config = BusinessService().config;
    final greeting = _getGreeting();
    final userName = GoogleDriveService().currentUser?.displayName ?? 'Kiran';

    // Calculate dynamic stats
    final activeBookingsCount = _allBookings.where((b) => !b.isClosed).length;
    final totalPendingAmount = _allBookings
        .where((b) => !b.isClosed)
        .fold<double>(0, (sum, b) => sum + b.pendingAmount);
    final completedCount = _allBookings.where((b) => b.isClosed).length;
    
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final bookingsThisMonth = _allBookings.where((b) {
      if (b.eventDates.isEmpty) return false;
      return b.eventDates.any((d) => d.month == currentMonth && d.year == currentYear);
    }).length;

    final today = DateTime.now();
    final bookingsToday = _allBookings.where((b) {
      return b.eventDates.any((d) => d.year == today.year && d.month == today.month && d.day == today.day);
    }).length;

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // If in selection mode, cancel it instead of exiting
        if (_isSelectionMode) {
          setState(() { _isSelectionMode = false; _selectedIds.clear(); });
          return;
        }
        // If not on home tab, go back to home
        if (_currentBottomNavIndex != 0) {
          _pageController.animateToPage(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          setState(() => _currentBottomNavIndex = 0);
          return;
        }
        // Show exit confirmation
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.7),
          builder: (ctx) => Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4AF37).withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.exit_to_app_rounded,
                      color: Color(0xFFD4AF37), size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text('Exit App?',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    )),
                  const SizedBox(height: 10),
                  Text(
                    'Are you sure you want to close the app?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () { Haptics.light(); Navigator.pop(ctx, false); },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Stay',
                              style: TextStyle(color: Colors.white,
                                fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () { Haptics.heavy(); Navigator.pop(ctx, true); },
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD4AF37), Color(0xFFF0D060)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: const Text('Exit',
                              style: TextStyle(color: Colors.black,
                                fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        if (shouldExit == true && context.mounted) {
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            Haptics.light();
            setState(() => _currentBottomNavIndex = index);
          },
          children: [
            _buildDashboard(context, config, greeting, userName, activeBookingsCount, totalPendingAmount, completedCount, bookingsThisMonth, bookingsToday, currencyFormat, isDark),
            const CalendarScreen(),
            const AnalyticsScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: _buildAnimatedNavBar(),
      ),
    );
  }

  Widget _buildAnimatedNavBar() {
    const items = [
      (Icons.home_rounded, Icons.home_outlined, 'Home'),
      (Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Calendar'),
      (Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Reports'),
      (Icons.settings_rounded, Icons.settings_outlined, 'Settings'),
    ];
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final (activeIcon, inactiveIcon, label) = entry.value;
          final isSelected = _currentBottomNavIndex == i;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (_currentBottomNavIndex == i) return;
                Haptics.light();
                _pageController.animateToPage(i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
                setState(() => _currentBottomNavIndex = i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon with scale + fade animation
                    AnimatedScale(
                      scale: isSelected ? 1.18 : 1.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutBack,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: isSelected
                            ? Stack(
                                alignment: Alignment.center,
                                key: ValueKey('active_$i'),
                                children: [
                                  // Glow blob
                                  Container(
                                    width: 36,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  Icon(activeIcon, color: const Color(0xFFD4AF37), size: 22),
                                ],
                              )
                            : Icon(inactiveIcon,
                                key: ValueKey('inactive_$i'),
                                color: Colors.grey[600], size: 22),
                      ),
                    ),
                    const SizedBox(height: 3),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[600]!,
                        fontSize: isSelected ? 10.5 : 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                      child: Text(label),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    BusinessConfig config,
    String greeting,
    String userName,
    int activeBookingsCount,
    double totalPendingAmount,
    int completedCount,
    int bookingsThisMonth,
    int bookingsToday,
    NumberFormat currencyFormat,
    bool isDark,
  ) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadBookings,
        color: const Color(0xFFD4AF37),
        child: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: _isSelectionMode ? 90 : 16,
              ),
              children: [
                _buildHeader(context, config, greeting, userName, activeBookingsCount, totalPendingAmount, bookingsToday, currencyFormat),
                const SizedBox(height: 18),
                _buildSearchBar(isDark),
                const SizedBox(height: 14),
                _buildFilterPillsRow(),
                const SizedBox(height: 18),
                _buildStatsGrid(activeBookingsCount, totalPendingAmount, completedCount, bookingsThisMonth, currencyFormat),
                const SizedBox(height: 18),
                _buildTabsRow(activeBookingsCount, completedCount),
                const SizedBox(height: 12),
                _buildMonthFilterRow(),
                const SizedBox(height: 16),
                _buildBookingsSection(isDark),
              ],
            ),
            if (_isFlashing)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            // ── Selection Delete Bar ──────────────────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              bottom: _isSelectionMode ? 0 : -100,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Cancel
                    GestureDetector(
                      onTap: () {
                        Haptics.light();
                        setState(() {
                          _isSelectionMode = false;
                          _selectedIds.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Count indicator
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _selectedIds.isEmpty
                                ? 'Long press to select'
                                : '${_selectedIds.length} selected',
                            key: ValueKey(_selectedIds.length),
                            style: TextStyle(
                              color: _selectedIds.isEmpty ? Colors.grey[600] : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Delete button
                    GestureDetector(
                      onTap: _selectedIds.isEmpty ? null : () {
                        Haptics.heavy();
                        _deleteSelected();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedIds.isEmpty
                              ? Colors.red.withOpacity(0.2)
                              : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Delete${_selectedIds.isEmpty ? '' : ' (${_selectedIds.length})'}',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BusinessConfig config, String greeting, String userName, int activeCount, double pendingAmt, int todayCount, NumberFormat currencyFormat) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.appTitle,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD4AF37),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '$greeting, $userName',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 10),
              // Business selector dropdown
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BusinessType>(
                    value: BusinessService().currentType,
                    dropdownColor: const Color(0xFF121212),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
                    onChanged: (val) async {
                      if (val != null) {
                        Haptics.light();
                        await BusinessService().setBusinessType(val);
                        _loadBookings();
                      }
                    },
                    selectedItemBuilder: (context) {
                      return BusinessType.values.map((type) {
                        return Center(
                          child: Text(
                            BusinessService().getConfigFor(type).displayName,
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList();
                    },
                    items: BusinessType.values.map((type) {
                      final cfg = BusinessService().getConfigFor(type);
                      return DropdownMenuItem<BusinessType>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(cfg.primaryIcon, color: cfg.accentColor, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              cfg.displayName,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () {
            Haptics.medium();
            Navigator.push(
              context,
              CalmPageRoute(builder: (_) => const BookingFormScreen()),
            ).then((_) => _loadBookings());
          },
          icon: const Icon(Icons.add, color: Colors.black, size: 18),
          label: const Text(
            'New',
            style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderChip({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1E1E) : const Color(0xFF121212),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 8),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[400],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    onChanged: _filterBookings,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Search bookings...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                      filled: false,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Haptics.light();
                      _searchController.clear();
                      _filterBookings('');
                    },
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            Haptics.light();
            _showMoreFiltersSheet();
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Color(0xFFD4AF37), size: 20),
                const SizedBox(width: 6),
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPillsRow() {
    final bool hasActiveFilter = _dateRangeFilter != 'All' ||
        _paymentStatusFilter != 'All' ||
        _serviceFilter != null ||
        _locationFilter != null ||
        _amountRangeFilter != null;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // Date range pill
          GestureDetector(
            onTap: () { Haptics.light(); _showDateRangeFilterSheet(); },
            child: _buildFilterPill(
              icon: Icons.calendar_month,
              label: _dateRangeFilter == 'All' ? 'Date' : _dateRangeFilter,
              isSelected: _dateRangeFilter != 'All',
            ),
          ),
          const SizedBox(width: 8),
          // Payment pill
          GestureDetector(
            onTap: () { Haptics.light(); _showPaymentFilterSheet(); },
            child: _buildFilterPill(
              icon: Icons.currency_rupee,
              label: _paymentStatusFilter == 'All' ? 'Payment' : _paymentStatusFilter,
              isSelected: _paymentStatusFilter != 'All',
            ),
          ),
          const SizedBox(width: 8),
          // More Filters pill
          GestureDetector(
            onTap: () { Haptics.light(); _showMoreFiltersSheet(); },
            child: _buildFilterPill(
              icon: Icons.tune,
              label: 'More Filters',
              isSelected: _serviceFilter != null || _locationFilter != null || _amountRangeFilter != null,
            ),
          ),
          if (hasActiveFilter) ...[  
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Haptics.light();
                setState(() {
                  _dateRangeFilter = 'All';
                  _paymentStatusFilter = 'All';
                  _serviceFilter = null;
                  _locationFilter = null;
                  _amountRangeFilter = null;
                  _applyFilters();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, size: 13, color: Colors.red),
                    SizedBox(width: 4),
                    Text('Clear', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFD4AF37) : const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: isSelected ? Colors.black : Colors.grey[400],
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey[400],
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(int active, double pending, int completed, int thisMonth, NumberFormat currencyFormat) {
    // Accurate percentages
    final total = _allBookings.length;
    final completedPct = total > 0 ? ((completed / total) * 100).round() : 0;
    final thisMonthPct = total > 0 ? ((thisMonth / total) * 100).round() : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double cardAspectRatio = constraints.maxWidth > 600 ? 2.2 : 1.65;
        return GridView.count(
          crossAxisCount: constraints.maxWidth > 600 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: cardAspectRatio,
          children: [
            // ── Active Bookings ──────────────────────────────────
            GestureDetector(
              onTap: () {
                Haptics.medium();
                final activeList = _allBookings.where((b) => !b.isClosed).toList();
                Navigator.push(
                  context,
                  CalmPageRoute(
                    builder: (_) => BookingsDetailScreen(
                      title: 'Active Bookings',
                      subtitle: 'Currently open & in-progress',
                      bookings: activeList,
                      accentColor: Colors.green,
                      icon: Icons.business_center_outlined,
                    ),
                  ),
                ).then((_) => _loadBookings());
              },
              child: _buildStatCard(
                icon: Icons.business_center_outlined,
                iconColor: Colors.green,
                value: active.toString(),
                label: 'Active Bookings',
                subLabel: 'Tap to view all',
                trendColor: Colors.green,
              ),
            ),
            // ── Pending Amount ────────────────────────────────────
            GestureDetector(
              onTap: () {
                Haptics.medium();
                final dueList = _allBookings.where((b) => !b.isClosed && b.pendingAmount > 0).toList();
                Navigator.push(
                  context,
                  CalmPageRoute(
                    builder: (_) => BookingsDetailScreen(
                      title: 'Pending Amount',
                      subtitle: 'Bookings with outstanding dues',
                      bookings: dueList,
                      accentColor: Colors.amber,
                      icon: Icons.currency_rupee,
                      amountLabel: 'Total Due',
                    ),
                  ),
                ).then((_) => _loadBookings());
              },
              child: _buildStatCard(
                icon: Icons.currency_rupee,
                iconColor: Colors.amber,
                value: '₹${NumberFormat.compact().format(pending)}',
                label: 'Pending Amount',
                subLabel: 'Tap to view dues',
                trendColor: Colors.amber,
              ),
            ),
            // ── Completed ─────────────────────────────────────────
            GestureDetector(
              onTap: () {
                Haptics.medium();
                final closedList = _allBookings.where((b) => b.isClosed).toList();
                Navigator.push(
                  context,
                  CalmPageRoute(
                    builder: (_) => BookingsDetailScreen(
                      title: 'Completed',
                      subtitle: '$completedPct% of all bookings closed',
                      bookings: closedList,
                      accentColor: const Color(0xFF4488FF),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                ).then((_) => _loadBookings());
              },
              child: _buildStatCard(
                icon: Icons.check_circle_outline,
                iconColor: const Color(0xFF4488FF),
                value: completed.toString(),
                label: 'Completed',
                subLabel: total > 0 ? '$completedPct% of total' : 'No bookings yet',
                trendColor: const Color(0xFF4488FF),
              ),
            ),
            // ── This Month ────────────────────────────────────────
            GestureDetector(
              onTap: () {
                Haptics.medium();
                final currentMonth = DateTime.now().month;
                final currentYear = DateTime.now().year;
                final monthList = _allBookings.where((b) {
                  if (b.eventDates.isEmpty) return false;
                  return b.eventDates.any((d) => d.month == currentMonth && d.year == currentYear);
                }).toList();
                final monthName = DateFormat('MMMM yyyy').format(DateTime.now());
                Navigator.push(
                  context,
                  CalmPageRoute(
                    builder: (_) => BookingsDetailScreen(
                      title: 'This Month',
                      subtitle: '$monthName • $thisMonthPct% of all bookings',
                      bookings: monthList,
                      accentColor: Colors.purpleAccent,
                      icon: Icons.calendar_month_outlined,
                    ),
                  ),
                ).then((_) => _loadBookings());
              },
              child: _buildStatCard(
                icon: Icons.calendar_month_outlined,
                iconColor: Colors.purpleAccent,
                value: thisMonth.toString(),
                label: 'This Month',
                subLabel: total > 0 ? '$thisMonthPct% of total' : 'No bookings yet',
                trendColor: Colors.purpleAccent,
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String subLabel,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: iconColor.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 15),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios, color: iconColor.withValues(alpha: 0.4), size: 12),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subLabel,
            style: TextStyle(color: trendColor.withValues(alpha: 0.7), fontSize: 10, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabsRow(int activeCount, int closedCount) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildSegmentedTab(title: 'Active', count: activeCount, index: 0)),
          Expanded(child: _buildSegmentedTab(title: 'Completed', count: closedCount, index: 1)),
        ],
      ),
    );
  }

  Widget _buildSegmentedTab({
    required String title,
    required int count,
    required int index,
  }) {
    final isSelected = _activeTab == index && !_filterActiveOnly && !_filterDueOnly && !_filterTodayOnly;
    return GestureDetector(
      onTap: () {
        Haptics.light();
        setState(() {
          _activeTab = index;
          _filterActiveOnly = false;
          _filterDueOnly = false;
          _filterTodayOnly = false;
          _applyFilters();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tr(title) ?? title,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[400],
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.black.withOpacity(0.15) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthFilterRow() {
    final List<String> months = ['All', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final m = months[index];
          final isSel = _selectedMonthFilter == m;
          return GestureDetector(
            onTap: () {
              Haptics.light();
              setState(() {
                _selectedMonthFilter = m;
                _applyFilters();
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFFD4AF37) : const Color(0xFF121212),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSel ? const Color(0xFFD4AF37) : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Text(
                m,
                style: TextStyle(
                  color: isSel ? Colors.black : Colors.grey[400],
                  fontSize: 13,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBookingsSection(bool isDark) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    final grouped = _groupBookingsByMonth();
    if (grouped.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, color: Colors.grey[700], size: 54),
              const SizedBox(height: 12),
              Text(
                BusinessService().config.emptyStateMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        final monthName = entry.key.toUpperCase();
        final bookings = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  monthName,
                  style: GoogleFonts.outfit(
                    color: Colors.grey[500],
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Haptics.light();
                    _exportPdfReport(bookings, monthName);
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Color(0xFFD4AF37), size: 18),
                  label: const Text(
                    'Export PDF',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.length,
              itemBuilder: (context, i) {
                final booking = bookings[i];
                final isLast = i == bookings.length - 1;
                final isSelected = _selectedIds.contains(booking.id);
                final isDeleting = _deletingIds.contains(booking.id);

                return AnimatedSize(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: isDeleting ? 0.0 : 1.0,
                    child: isDeleting
                        ? const SizedBox(width: double.infinity, height: 0)
                        : RepaintBoundary(
                            child: Dismissible(
                              key: Key('dismiss_${booking.id}'),
                              direction: DismissDirection.horizontal,
                              onUpdate: (details) {
                                final itemId = booking.id;
                                if (_activeDismissibleId != itemId) {
                                  _activeDismissibleId = itemId;
                                  _lastHapticLevel = 0;
                                }
                                int currentLevel = 0;
                                if (details.progress > 0.75) {
                                  currentLevel = 3;
                                } else if (details.progress > 0.45) {
                                  currentLevel = 2;
                                } else if (details.progress > 0.15) {
                                  currentLevel = 1;
                                }
                                if (currentLevel != _lastHapticLevel) {
                                  _lastHapticLevel = currentLevel;
                                  if (currentLevel == 1) {
                                    Haptics.light();
                                  } else if (currentLevel == 2) {
                                    Haptics.medium();
                                  } else if (currentLevel == 3) {
                                    Haptics.heavy();
                                  }
                                }
                              },
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.share, color: Colors.blue, size: 26),
                                    SizedBox(width: 8),
                                    Text('Share', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 8),
                                    Icon(Icons.delete, color: Colors.red, size: 26),
                                  ],
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.endToStart) {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Delete Booking?'),
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
                                    await _deleteBooking(booking.id);
                                    return true;
                                  }
                                  return false;
                                } else if (direction == DismissDirection.startToEnd) {
                                  Haptics.medium();
                                  _showShareOptions(context, booking);
                                  return false;
                                }
                                return false;
                              },
                              child: BookingCard(
                                booking: booking,
                                isSelected: isSelected,
                                isSelectionMode: _isSelectionMode,
                                isLast: isLast,
                                onTap: () {
                                  if (_isSelectionMode) {
                                    _toggleItemSelection(booking.id);
                                  } else {
                                    Navigator.push(
                                      context,
                                      CalmPageRoute(
                                        builder: (_) => BookingFormScreen(booking: booking),
                                      ),
                                    ).then((_) => _loadBookings());
                                  }
                                },
                                onLongPress: () {
                                  if (!_isSelectionMode) {
                                    _toggleSelectionMode(booking.id);
                                  }
                                },
                                onShare: () => _showShareOptions(context, booking),
                                onToggleClosed: () async {
                                  final updated = booking.copyWith(
                                    isClosed: !booking.isClosed,
                                  );
                                  Haptics.success();
                                  await Future.delayed(const Duration(milliseconds: 300));
                                  await DatabaseService().updateBooking(updated);
                                  _loadBookings();
                                },
                              ),
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _exportPdfReport(List<Booking> bookings, String monthName) async {
    setState(() => _isLoading = true);
    try {
      await PdfGenerator.generateMonthlyReport(
        monthName,
        bookings,
        isDarkMode: Theme.of(context).brightness == Brightness.dark,
      );
      Haptics.success();
    } catch (e) {
      debugPrint('PDF Export Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showShareOptions(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.green),
              title: Text(tr('share_text')),
              onTap: () {
                Navigator.pop(context);
                _shareText(_formatBookingMessage(booking));
              },
            ),
            ListTile(
              leading: Icon(
                booking.isClosed ? Icons.restore : Icons.check_circle_outline,
                color: booking.isClosed ? Colors.amber : const Color(0xFFD4AF37),
              ),
              title: Text(
                booking.isClosed ? tr('reopen_booking') : tr('mark_completed'),
              ),
              onTap: () async {
                Navigator.pop(context);
                final updated = booking.copyWith(
                  isClosed: !booking.isClosed,
                );
                Haptics.success();
                await Future.delayed(const Duration(milliseconds: 300));
                await DatabaseService().updateBooking(updated);
                _loadBookings();
              },
            ),
            ListTile(
              leading: Icon(Icons.image, color: Theme.of(context).primaryColor),
              title: Text(tr('share_image_card')),
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

  // --- FILTER BOTTOM SHEETS ---

  // 1. Date Range Sheet
  void _showDateRangeFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161616),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📅 Select Period',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...['All', 'Today', 'This Week', 'This Month', 'Last Month'].map((opt) {
                final isSel = _dateRangeFilter == opt;
                return ListTile(
                  title: Text(opt, style: TextStyle(color: isSel ? const Color(0xFFD4AF37) : Colors.white)),
                  trailing: isSel ? const Icon(Icons.check, color: Color(0xFFD4AF37)) : null,
                  onTap: () {
                    setState(() {
                      _dateRangeFilter = opt;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                );
              }),
              ListTile(
                title: Text('Custom Range', style: TextStyle(color: _dateRangeFilter == 'Custom Range' ? const Color(0xFFD4AF37) : Colors.white)),
                trailing: _dateRangeFilter == 'Custom Range' ? const Icon(Icons.check, color: Color(0xFFD4AF37)) : null,
                onTap: () async {
                  final pickedRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDateRange: _customDateRange,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFD4AF37),
                            onPrimary: Colors.black,
                            surface: Color(0xFF161616),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedRange != null) {
                    setState(() {
                      _dateRangeFilter = 'Custom Range';
                      _customDateRange = pickedRange;
                      _applyFilters();
                    });
                  }
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Client Filter Sheet
  void _showClientFilterSheet() {
    final clients = _allBookings.map((b) => b.customerName).toSet().toList();
    String sheetSearch = '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '👤 Clients',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            setSheetState(() {
                              sheetSearch = val.toLowerCase();
                            });
                          },
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search Client',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.people_outline, color: Color(0xFFD4AF37)),
                        title: const Text('All Clients', style: TextStyle(color: Colors.white)),
                        onTap: () {
                          setState(() {
                            _selectedClientFilter = null;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                      ),
                      ...clients.where((c) => c.toLowerCase().contains(sheetSearch)).map((client) {
                        return ListTile(
                          leading: const Icon(Icons.person, color: Colors.grey),
                          title: Text(client, style: const TextStyle(color: Colors.white)),
                          onTap: () {
                            setState(() {
                              _selectedClientFilter = client;
                              _applyFilters();
                            });
                            Navigator.pop(context);
                          },
                        );
                      }),
                      ListTile(
                        leading: const Icon(Icons.add, color: Color(0xFF4CAF50)),
                        title: const Text('+ New Client', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            CalmPageRoute(builder: (_) => const BookingFormScreen()),
                          ).then((_) => _loadBookings());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. Payment Filter Sheet
  void _showPaymentFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161616),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '💰 Payment Status',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...[
              {'label': 'All', 'iconColor': Colors.grey},
              {'label': 'Paid', 'iconColor': const Color(0xFF4CAF50)},
              {'label': 'Advance', 'iconColor': const Color(0xFFFF9800)},
              {'label': 'Due', 'iconColor': const Color(0xFFF44336)},
              {'label': 'Upcoming', 'iconColor': const Color(0xFF2196F3)},
              {'label': 'Cancelled', 'iconColor': Colors.grey[700]!},
            ].map((status) {
              final String label = status['label'] as String;
              final Color color = status['iconColor'] as Color;
              final isSel = _paymentStatusFilter == label;
              return ListTile(
                leading: Icon(Icons.circle, color: color, size: 10),
                title: Text(label, style: TextStyle(color: isSel ? const Color(0xFFD4AF37) : Colors.white)),
                trailing: isSel ? const Icon(Icons.check, color: Color(0xFFD4AF37)) : null,
                onTap: () {
                  setState(() {
                    _paymentStatusFilter = label;
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // 4. More Filters Sheet
  void _showMoreFiltersSheet() {
    final config = BusinessService().config;
    // Services are dynamic based on business type
    final List<String> services = config.serviceTypes.isNotEmpty
        ? config.serviceTypes
        : ['Package 1', 'Package 2', 'Package 3'];
    final List<String> amounts = ['₹0–₹10k', '₹10k–₹50k', '₹50k+'];
    final List<String> sorts = ['Newest', 'Oldest', 'Event Date', 'Amount'];

    String? localService = _serviceFilter;
    String? localLocation = _locationFilter;
    String? localAmount = _amountRangeFilter;
    String localSort = _sortBy;
    final TextEditingController locationCtrl = TextEditingController(text: localLocation ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '⚙ Filter Bookings',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Services — dynamic per business type
                Text('📸 ${config.eventLabel}', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: services.map((s) {
                    final isSel = localService == s;
                    return GestureDetector(
                      onTap: () => setSheetState(() => localService = isSel ? null : s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFD4AF37) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? const Color(0xFFD4AF37) : Colors.white12),
                        ),
                        child: Text(s, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Location — worldwide free text search
                const Text('📍 Location', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: locationCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Any city, country or place...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            filled: false,
                          ),
                          onChanged: (v) => setSheetState(() => localLocation = v.trim().isEmpty ? null : v.trim()),
                        ),
                      ),
                      if (locationCtrl.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            locationCtrl.clear();
                            setSheetState(() => localLocation = null);
                          },
                          child: const Icon(Icons.close, color: Colors.grey, size: 16),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Amount Range
                const Text('💵 Amount', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: amounts.map((a) {
                    final isSel = localAmount == a;
                    return GestureDetector(
                      onTap: () => setSheetState(() => localAmount = isSel ? null : a),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFD4AF37) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? const Color(0xFFD4AF37) : Colors.white12),
                        ),
                        child: Text(a, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Sort
                const Text('📅 Sort By', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: sorts.map((s) {
                    final isSel = localSort == s;
                    return GestureDetector(
                      onTap: () => setSheetState(() => localSort = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFD4AF37) : const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSel ? const Color(0xFFD4AF37) : Colors.white12),
                        ),
                        child: Text(s, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontSize: 13, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          locationCtrl.clear();
                          setState(() {
                            _serviceFilter = null;
                            _locationFilter = null;
                            _amountRangeFilter = null;
                            _sortBy = 'Event Date';
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Reset', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          setState(() {
                            _serviceFilter = localService;
                            _locationFilter = localLocation;
                            _amountRangeFilter = localAmount;
                            _sortBy = localSort;
                            _applyFilters();
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatBookingMessage(Booking booking) {
    final dates = booking.eventDates
        .map((d) => DateFormat('dd MMM yyyy').format(d))
        .join(', ');
    return """${tr('booking_confirmed_title')}!

${tr(BusinessService().config.client1Label)}: ${booking.brideName}
${tr(BusinessService().config.client2Label)}: ${booking.groomName.isNotEmpty ? booking.groomName : tr('not_applicable')}

📅 ${tr(BusinessService().config.eventLabel)}: $dates
📍 ${tr('address')}: ${booking.address.isNotEmpty ? booking.address : tr('not_applicable')}
📞 ${tr('contact')}: ${booking.phoneNumber}

${tr('financials')}:
${tr('total')}: ₹${booking.totalAmount.toStringAsFixed(0)}
${tr('received')}: ₹${booking.receivedAmount.toStringAsFixed(0)}
${tr('due')}: ₹${booking.pendingAmount.toStringAsFixed(0)}

${tr('thank_you')}!""";
  }
}

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onShare;
  final VoidCallback onToggleClosed;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
    required this.onShare,
    required this.onToggleClosed,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return '??';
    final parts = name.split('&').map((p) => p.trim()).toList();
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    final nameParts = name.trim().split(RegExp(r'\s+'));
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF2E7D32), // Green
      const Color(0xFFE65100), // Orange
      const Color(0xFF1565C0), // Blue
      const Color(0xFF6A1B9A), // Purple
      const Color(0xFFAD1457), // Pink
    ];
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length];
  }

  String _getStatusText() {
    if (booking.isClosed) return 'Closed';
    if (booking.pendingAmount == 0) return 'Paid';
    if (booking.advanceReceived > 0) return 'Advance';
    return 'Upcoming';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Paid': return const Color(0xFF4CAF50);
      case 'Advance': return const Color(0xFFFF9800);
      case 'Upcoming': return const Color(0xFF2196F3);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final initials = _getInitials(booking.customerName);
    final avatarColor = _getAvatarColor(booking.customerName);
    final status = _getStatusText();
    final statusColor = _getStatusColor(status);

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () {
        Haptics.light();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.06),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (isSelectionMode) ...[
                    Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? const Color(0xFFD4AF37) : Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                  ],
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: avatarColor.withOpacity(0.15),
                    child: Text(
                      initials,
                      style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                booking.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                border: Border.all(color: statusColor.withOpacity(0.5)),
                                color: statusColor.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (status == 'Paid')
                                    const Icon(Icons.check, color: Color(0xFF4CAF50), size: 12),
                                  if (status == 'Paid') const SizedBox(width: 2),
                                  Text(
                                    status,
                                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.grey, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${booking.eventDates.map((d) => DateFormat('d MMM').format(d)).join(', ')} • ${booking.businessType.toUpperCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        if (booking.address.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.grey, size: 12),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  booking.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${booking.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Paid: ₹${booking.receivedAmount.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: Colors.grey[700], size: 18),
                ],
              ),
            ),
            Container(
              height: 0.5,
              color: Colors.white.withOpacity(0.08),
            ),
            Container(
              height: 42,
              color: const Color(0xFF161616),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Text(
                    'Balance: ₹${booking.pendingAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: booking.pendingAmount > 0 ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  _buildCardAction(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: onShare,
                  ),
                  _buildActionDivider(),
                  _buildCardAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: onTap,
                  ),
                  _buildActionDivider(),
                  _buildCardAction(
                    icon: booking.isClosed ? Icons.refresh_outlined : Icons.check_circle_outline,
                    label: booking.isClosed ? 'Reopen' : 'Complete',
                    onTap: onToggleClosed,
                    color: booking.isClosed ? Colors.amber : const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? Colors.grey[400]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, color: c, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: c, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionDivider() {
    return Container(
      width: 0.5,
      height: 14,
      color: Colors.white24,
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/ui/booking_form.dart';
import 'package:vownote/utils/pdf_generator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vownote/utils/booking_card_image.dart';
import 'package:vownote/ui/settings_screen.dart';
import 'package:vownote/ui/analytics_screen.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:vownote/utils/calm_page_route.dart';
import 'package:vownote/services/business_service.dart';
import 'dart:ui';
import 'package:vownote/ui/widgets/shimmer_text.dart';

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

  final ScreenshotController _screenshotController = ScreenshotController();
  Booking? _bookingToCapture;
  bool _isFlashing = false;
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (_allBookings.isEmpty) setState(() => _isLoading = true);
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
      final monthKey = DateFormat('MMM', 'en_US').format(firstDate.first);
      return monthKey == _selectedMonthFilter;
    }).toList();
  }

  Map<String, List<Booking>> _groupBookingsByMonth() {
    final Map<String, List<Booking>> grouped = {};
    for (var booking in _filteredBookings) {
      if (booking.eventDates.isEmpty) continue;
      final dates = List<DateTime>.from(booking.eventDates)..sort();
      final key = DateFormat('MMMM yyyy', 'en_US').format(dates.first);
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
      _isFlashing = true; // Trigger flash
    });
    Haptics.selection(); // Sound/Feel of shutter
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() => _isFlashing = false); // End flash

    try {
      final image = await _screenshotController.captureFromLongWidget(
        BookingCardImage(booking: booking, isDarkMode: isDark),
        context: context,
        pixelRatio: 3.0, // High quality
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
      setState(() {
        _deletingIds.addAll(_selectedIds);
      });

      // Wait for "Magic Sprinkle" animation to complete
      await Future.delayed(const Duration(milliseconds: 600));

      for (var id in _selectedIds) {
        await DatabaseService().deleteBooking(id);
      }
      Haptics.success();
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
    await Future.delayed(const Duration(milliseconds: 600));
    await DatabaseService().deleteBooking(id);
    Haptics.success();
    setState(() {
      _deletingIds.remove(id);
    });
    _loadBookings();
  }

  @override
  Widget build(BuildContext context) {
    final groupedBookings = _groupBookingsByMonth();
    final sortedKeys = groupedBookings.keys.toList()
      ..sort((a, b) {
        final da = DateFormat('MMMM yyyy', 'en_US').parse(a);
        final db = DateFormat('MMMM yyyy', 'en_US').parse(b);
        return da.compareTo(db);
      });

    // Dynamic Month Pills
    final Set<String> months = {'All'};
    if (_allBookings.isNotEmpty) {
      final sortedBookings = List<Booking>.from(_allBookings)
        ..sort((a, b) {
          if (a.eventDates.isEmpty) return 1;
          if (b.eventDates.isEmpty) return -1;
          return a.eventDates.first.compareTo(b.eventDates.first);
        });

      for (var b in sortedBookings) {
        if (b.eventDates.isNotEmpty) {
          // Logic: Check if we are using strict 'MMM' or something else
          // Using 'MMM' (Jan, Feb) means merging years (Jan 2025 and Jan 2026 -> Jan)
          // User requested "month alll,jan,feb,mar apr". This implies short format.
          months.add(DateFormat('MMM', 'en_US').format(b.eventDates.first));
        }
      }
    }

    final monthList = months.toList();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              _isSelectionMode = false;
              _selectedIds.clear();
            });
            Haptics.medium();
          }
          FocusManager.instance.primaryFocus?.unfocus();
        },
        behavior: HitTestBehavior.translucent, // Catch taps on empty space
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification &&
                    notification.dragDetails != null) {
                  if (_searchFocus.hasFocus) {
                    _searchFocus.unfocus();
                  }
                }
                return false;
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withOpacity(0.8),
                    surfaceTintColor: Colors.transparent,
                    pinned: true,
                    stretch: true,
                    expandedHeight: 110,
                    flexibleSpace: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: FlexibleSpaceBar(
                          centerTitle: false,
                          titlePadding: const EdgeInsets.only(
                            left: 20,
                            bottom: 12,
                          ),
                          title: _isSelectionMode
                              ? Text(
                                  '${_selectedIds.length} Selected',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : ShimmerText(
                                  BusinessService().config.appTitle,
                                  style: GoogleFonts.outfit(
                                    // Remove color here so shimmer gradient takes over, or use white/black base
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  // Bright Gold Shimmer for maximum visibility
                                  shimmerColors: const [
                                    Color(0xFFD4AF37), // Gold
                                    Color(0xFFF7EF8A), // Bright Yellow Gold
                                    Color(0xFFD4AF37), // Gold
                                    Color(0xFFC5A028), // Dark Gold
                                    Color(0xFFD4AF37), // Gold
                                  ],
                                  duration: const Duration(milliseconds: 2500),
                                ),
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
                          icon:
                              Icon(
                                    Icons.settings,
                                    color: Theme.of(context).iconTheme.color,
                                  )
                                  .animate(
                                    onPlay: (controller) => controller.repeat(),
                                  )
                                  .shimmer(
                                    duration: 2500.ms,
                                    color: const Color(
                                      0xFFF5F5F5,
                                    ), // Platinum white
                                    angle: 45,
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
                            vertical: 12,
                          ),
                          child: AnimatedBuilder(
                            animation: _searchFocus,
                            builder: (context, child) {
                              final bool hasFocus = _searchFocus.hasFocus;
                              return AnimatedContainer(
                                    duration: 300.ms,
                                    curve: Curves.easeOutCubic,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: hasFocus ? 4 : 0,
                                    ),
                                    child: TextField(
                                      focusNode: _searchFocus,
                                      onChanged: _filterBookings,
                                      decoration: InputDecoration(
                                        hintText: 'Search Bookings...',
                                        hintStyle: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.search,
                                          size: 20,
                                          color: hasFocus
                                              ? const Color(0xFFD4AF37)
                                              : (isDark
                                                    ? Colors.white54
                                                    : Colors.black54),
                                        ),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                                onPressed: () {
                                                  _filterBookings('');
                                                  // Clear the controller if we had one,
                                                  // but since we don't use one, let's just trigger rebuild.
                                                },
                                              )
                                            : null,
                                        filled: true,
                                        fillColor: hasFocus
                                            ? (isDark
                                                  ? Colors.white.withOpacity(
                                                      0.08,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.03,
                                                    ))
                                            : Theme.of(context).cardTheme.color,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            hasFocus ? 14 : 10,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 0,
                                            ),
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(fontSize: 15),
                                    ),
                                  )
                                  .animate(target: hasFocus ? 1 : 0)
                                  .shimmer(
                                    duration: 1.seconds,
                                    color: Colors.white10,
                                  );
                            },
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                        SizedBox(
                          height: 52,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: monthList.length,
                            itemBuilder: (context, i) {
                              final m = monthList[i];
                              final isSelected = _selectedMonthFilter == m;
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child:
                                    ChoiceChip(
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
                                          selectedColor: const Color(
                                            0xFFD4AF37,
                                          ),
                                          labelStyle: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : (Theme.of(
                                                            context,
                                                          ).brightness ==
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
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          showCheckmark: false,
                                          side: BorderSide.none,
                                        )
                                        .animate(
                                          target: isSelected ? 1 : 0,
                                          onPlay: (c) => isSelected
                                              ? c.repeat(reverse: true)
                                              : null,
                                        )
                                        .scale(
                                          begin: const Offset(1.0, 1.0),
                                          end: const Offset(1.08, 1.08),
                                          duration: 1500.ms,
                                          curve: Curves.easeInOutSine,
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
                              BusinessService().config.emptyStateMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_isLoading && groupedBookings.isNotEmpty)
                    ...sortedKeys.asMap().entries.map((entry) {
                      final monthKey = entry.value;
                      final monthBookings = groupedBookings[monthKey]!;
                      return SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      Haptics.heavy();

                                      // Show premium processing dialog
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => Center(
                                          child:
                                              Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 32,
                                                          vertical: 24,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Theme.of(
                                                        context,
                                                      ).cardColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.2),
                                                          blurRadius: 20,
                                                          spreadRadius: 5,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        const CircularProgressIndicator(
                                                          color: Color(
                                                            0xFFD4AF37,
                                                          ),
                                                          strokeWidth: 3,
                                                        ),
                                                        const SizedBox(
                                                          height: 20,
                                                        ),
                                                        Text(
                                                              "Generating PDF...",
                                                              style: GoogleFonts.inter(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                decoration:
                                                                    TextDecoration
                                                                        .none,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .textTheme
                                                                        .bodyLarge
                                                                        ?.color,
                                                                fontSize: 15,
                                                              ),
                                                            )
                                                            .animate(
                                                              onPlay: (c) =>
                                                                  c.repeat(),
                                                            )
                                                            .shimmer(
                                                              duration:
                                                                  1.5.seconds,
                                                              color:
                                                                  const Color(
                                                                    0xFFD4AF37,
                                                                  ),
                                                            ),
                                                      ],
                                                    ),
                                                  )
                                                  .animate()
                                                  .scale(
                                                    duration: 400.ms,
                                                    curve: Curves.easeOutBack,
                                                  )
                                                  .fadeIn(),
                                        ),
                                      );

                                      try {
                                        final isDark =
                                            Theme.of(context).brightness ==
                                            Brightness.dark;

                                        // Artificial delay to show off the animation (optional, but feels premium)
                                        await Future.delayed(800.ms);

                                        await PdfGenerator.generateMonthlyReport(
                                          monthKey,
                                          monthBookings,
                                          isDarkMode: isDark,
                                        );
                                      } finally {
                                        Navigator.of(
                                          context,
                                        ).pop(); // Close dialog
                                        Haptics.success();
                                      }
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
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
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
                                children: [
                                  ...monthBookings
                                      .asMap()
                                      .entries
                                      .map((entry) {
                                        final i = entry.key;
                                        final booking = entry.value;
                                        final isLast =
                                            i == monthBookings.length - 1;
                                        final isSelected = _selectedIds
                                            .contains(booking.id);

                                        return Dismissible(
                                          key: Key('dismiss_${booking.id}'),
                                          direction:
                                              DismissDirection.endToStart,
                                          background: Container(
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.only(
                                              right: 20,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.redAccent,
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                            ),
                                            child: const Icon(
                                              Icons.delete,
                                              color: Colors.white,
                                            ),
                                          ),
                                          onDismissed: (_) {
                                            Haptics.heavy();
                                            _deleteBooking(booking.id);
                                          },
                                          confirmDismiss: (_) async {
                                            return await showDialog(
                                              context: context,
                                              builder: (c) => AlertDialog(
                                                title: const Text(
                                                  'Delete Booking?',
                                                ),
                                                content: const Text(
                                                  'This action cannot be undone.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c, false),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(c, true),
                                                    child: const Text(
                                                      'Delete',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                          child:
                                              BookingCard(
                                                    booking: booking,
                                                    isSelected: isSelected,
                                                    isSelectionMode:
                                                        _isSelectionMode,
                                                    isLast: isLast,
                                                    onTap: () {
                                                      if (_isSelectionMode) {
                                                        _toggleItemSelection(
                                                          booking.id,
                                                        );
                                                      } else {
                                                        Navigator.push(
                                                          context,
                                                          CalmPageRoute(
                                                            builder: (_) =>
                                                                BookingFormScreen(
                                                                  booking:
                                                                      booking,
                                                                ),
                                                          ),
                                                        ).then(
                                                          (_) =>
                                                              _loadBookings(),
                                                        );
                                                      }
                                                    },
                                                    onLongPress: () {
                                                      if (!_isSelectionMode) {
                                                        _toggleSelectionMode(
                                                          booking.id,
                                                        );
                                                      }
                                                    },
                                                    onShare: () =>
                                                        _showShareOptions(
                                                          context,
                                                          booking,
                                                        ),
                                                  )
                                                  .animate(
                                                    target:
                                                        _deletingIds.contains(
                                                          booking.id,
                                                        )
                                                        ? 1
                                                        : 0,
                                                  )
                                                  .shake(duration: 400.ms)
                                                  .scale(
                                                    end: Offset.zero,
                                                    duration: 400.ms,
                                                  )
                                                  .fadeOut(),
                                        );
                                      })
                                      .toList()
                                      .animate(interval: 50.ms)
                                      .fadeIn(duration: 400.ms)
                                      .move(
                                        begin: const Offset(0, 10),
                                        curve: Curves.easeOutCubic,
                                      ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
            if (_bookingToCapture != null)
              Positioned(
                left: -1000,
                child: BookingCardImage(
                  booking: _bookingToCapture!,
                  isDarkMode: isDark,
                ),
              ),
            // Flash Overlay
            if (_isFlashing)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.8),
                ).animate().fadeOut(duration: 300.ms, curve: Curves.easeOut),
              ),
          ],
        ),
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
                  CalmPageRoute(builder: (_) => const BookingFormScreen()),
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

class BookingCard extends StatelessWidget {
  final Booking booking;
  final bool isSelected;
  final bool isSelectionMode;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onShare;

  const BookingCard({
    super.key,
    required this.booking,
    required this.isSelected,
    required this.isSelectionMode,
    required this.isLast,
    required this.onTap,
    required this.onLongPress,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: () {
        Haptics.light();
        onTap();
      },
      child:
          Container(
                color: Colors.transparent, // Ensures tap detection
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isSelectionMode)
                            Padding(
                              padding: const EdgeInsets.only(right: 12, top: 4),
                              child:
                                  Icon(
                                        isSelected
                                            ? Icons.check_circle
                                            : Icons.circle_outlined,
                                        color: isSelected
                                            ? const Color(0xFFD4AF37)
                                            : Colors.grey,
                                      )
                                      .animate()
                                      .scale(
                                        curve: Curves.easeOutBack,
                                        duration: 200.ms,
                                      )
                                      .fadeIn(),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (booking.diaryCode.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          booking.displayIdentity,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        booking.customerName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              decoration: booking.isCompleted
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                              color: booking.isCompleted
                                                  ? Colors.grey
                                                  : null,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if (booking.phoneNumber.isNotEmpty)
                                  _buildInfoRow(
                                    context,
                                    Icons.phone,
                                    booking.phoneNumber,
                                    isDark,
                                  ),
                                if (booking.address.isNotEmpty)
                                  _buildInfoRow(
                                    context,
                                    Icons.location_on,
                                    booking.address,
                                    isDark,
                                  ),
                                _buildInfoRow(
                                  context,
                                  Icons.calendar_today,
                                  booking.eventDates
                                      .map(
                                        (d) => DateFormat(
                                          'd MMM',
                                          'en_US',
                                        ).format(d),
                                      )
                                      .join(', '),
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      'Total: ₹${booking.totalAmount.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white70
                                            : Colors.grey[800],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (booking.pendingAmount > 0)
                                      Text(
                                        'Due: ₹${booking.pendingAmount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Paid',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                    const Spacer(),
                                    if (!isSelectionMode)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.ios_share,
                                          color: Colors.green,
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          Haptics.selection();
                                          onShare();
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isSelectionMode)
                            Padding(
                              padding: const EdgeInsets.only(left: 8, top: 4),
                              child: Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(
                          height: 1,
                          thickness: 0.5,
                          color: Colors.grey.withOpacity(isDark ? 0.1 : 0.2),
                        ),
                      ),
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .custom(
                duration: 3.seconds,
                builder: (context, value, child) => Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFD4AF37,
                              ).withOpacity(0.1 + (value * 0.1)),
                              blurRadius: 10 + (value * 10),
                              spreadRadius: 1 + (value * 2),
                            ),
                          ]
                        : [],
                  ),
                  child: child,
                ),
              ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            icon,
            size: 12,
            color: isDark ? Colors.white54 : Colors.grey[500],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

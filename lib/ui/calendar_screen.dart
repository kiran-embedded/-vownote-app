import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/services/localization_service.dart';
import 'package:vownote/services/business_service.dart';
import 'package:vownote/models/business_type.dart';
import 'package:vownote/utils/display_engine.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:vownote/ui/booking_form.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  List<Booking> _allBookings = [];
  bool _isLoading = true;
  final Map<String, List<Booking>> _eventMap = {};

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    final currentBusiness = BusinessService().currentType.name;
    final bookings = await DatabaseService().getBookings(
      businessType: currentBusiness,
    );
    if (mounted) {
      setState(() {
        _allBookings = bookings;
        _eventMap.clear();
        for (var b in bookings) {
          for (var date in b.eventDates) {
            final key = "${date.year}-${date.month}-${date.day}";
            _eventMap.putIfAbsent(key, () => []).add(b);
          }
        }
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    Haptics.selection();
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
    });
  }

  List<DateTime?> _generateMonthDays(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday; // 1 = Mon, 7 = Sun

    final List<DateTime?> days = [];
    
    // Add empty slots for weekday alignment (Monday starts first)
    final int prefixEmpty = startWeekday - 1;
    for (int i = 0; i < prefixEmpty; i++) {
      days.add(null);
    }

    // Add actual days
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monthDays = _generateMonthDays(_focusedMonth);
    final weekdayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final selectedKey = "${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}";
    final selectedEvents = _eventMap[selectedKey] ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          tr('calendar') ?? 'Calendar',
          style: DisplayEngine.font(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: const Color(0xFFD4AF37),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : SafeArea(
              child: Column(
                children: [
                  // Month Selector
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: const Icon(Icons.chevron_left, color: Color(0xFFD4AF37)),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.15),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Text(
                            DateFormat('MMMM yyyy', LocalizationService().currentLanguage).format(_focusedMonth),
                            key: ValueKey('${_focusedMonth.year}-${_focusedMonth.month}'),
                            style: DisplayEngine.font(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: const Icon(Icons.chevron_right, color: Color(0xFFD4AF37)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Weekday Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: weekdayHeaders.map((h) {
                        return SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              h,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.grey[500] : Colors.grey[600],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Calendar Grid
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: monthDays.length,
                        itemBuilder: (context, index) {
                          final date = monthDays[index];
                          if (date == null) return const SizedBox.shrink();

                          final isSelected = date.year == _selectedDate.year &&
                              date.month == _selectedDate.month &&
                              date.day == _selectedDate.day;

                          final isToday = date.year == DateTime.now().year &&
                              date.month == DateTime.now().month &&
                              date.day == DateTime.now().day;

                          final dayKey = "${date.year}-${date.month}-${date.day}";
                          final hasEvents = _eventMap.containsKey(dayKey);

                          return GestureDetector(
                            onTap: () {
                              Haptics.light();
                              setState(() {
                                _selectedDate = date;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFD4AF37)
                                    : isToday
                                        ? const Color(0xFFD4AF37).withOpacity(0.15)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFD4AF37)
                                      : isToday
                                          ? const Color(0xFFD4AF37).withOpacity(0.5)
                                          : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    '${date.day}',
                                    style: DisplayEngine.font(
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 14,
                                      color: isSelected
                                          ? Colors.black
                                          : isDark
                                              ? Colors.white
                                              : Colors.black,
                                    ),
                                  ),
                                  if (hasEvents)
                                    Positioned(
                                      bottom: 4,
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.black
                                              : const Color(0xFFD4AF37),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // Selected Day Events Detail Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.event,
                          size: 16,
                          color: isDark ? const Color(0xFFD4AF37) : Colors.amber[800],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('MMMM d, yyyy', LocalizationService().currentLanguage).format(_selectedDate).toUpperCase(),
                          style: DisplayEngine.font(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFD4AF37) : Colors.amber[800],
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Event List below the calendar
                  Expanded(
                    flex: 2,
                    child: selectedEvents.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event_busy,
                                  size: 40,
                                  color: Colors.grey.withOpacity(0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tr('no_bookings_today') ?? 'No weddings scheduled',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            itemCount: selectedEvents.length,
                            itemBuilder: (context, index) {
                              final booking = selectedEvents[index];
                              final config = BusinessConfig.fromType(BusinessService().currentType);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.grey.withOpacity(0.2),
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                                    child: Icon(
                                      config.primaryIcon,
                                      color: const Color(0xFFD4AF37),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    booking.brideName.isNotEmpty
                                        ? '${booking.brideName} & ${booking.groomName}'
                                        : booking.customerName,
                                    style: DisplayEngine.font(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              booking.address,
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                                  onTap: () async {
                                    Haptics.light();
                                    final updated = await Navigator.push<Booking>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BookingFormScreen(booking: booking),
                                      ),
                                    );
                                    if (updated != null) {
                                      _loadBookings();
                                    }
                                  },
                                ),
                              ).animate().slideY(
                                    begin: 0.2,
                                    end: 0,
                                    duration: 300.ms,
                                    curve: Curves.easeOutCubic,
                                  );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

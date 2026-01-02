import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/services/notification_service.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:uuid/uuid.dart';

class BookingFormScreen extends StatefulWidget {
  final Booking? booking;

  const BookingFormScreen({super.key, this.booking});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _brideNameController;
  late TextEditingController _groomNameController;
  late TextEditingController _totalAmountController;
  late TextEditingController _advanceAmountController;
  late TextEditingController _receivedAmountController; // New Controller
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  List<DateTime> _selectedDates = [];
  double _pendingAmount = 0;
  bool _isSaving = false;
  List<Booking> _allBookings = [];
  List<Booking> _filteredLookupResults = [];
  bool _isLookupFocused = false;

  @override
  void initState() {
    super.initState();
    _brideNameController = TextEditingController(
      text: widget.booking?.brideName ?? '',
    );
    _groomNameController = TextEditingController(
      text: widget.booking?.groomName ?? '',
    );
    _totalAmountController = TextEditingController(
      text: widget.booking?.totalAmount.toString() ?? '',
    );
    _advanceAmountController = TextEditingController(
      text: widget.booking?.advanceAmount.toString() ?? '',
    );
    _receivedAmountController = TextEditingController(
      text: widget.booking?.receivedAmount.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: widget.booking?.address ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.booking?.phoneNumber ?? '',
    );
    _notesController = TextEditingController(text: widget.booking?.notes ?? '');
    _selectedDates = widget.booking?.eventDates ?? [];

    // If new booking, listen to advance to auto-fill received
    if (widget.booking == null) {
      _advanceAmountController.addListener(() {
        // Only auto-fill if received is empty or same as old advance
        if (_receivedAmountController.text.isEmpty) {
          _receivedAmountController.text = _advanceAmountController.text;
        }
      });
    }

    _calculatePending();

    _totalAmountController.addListener(_calculatePending);
    _receivedAmountController.addListener(_calculatePending);

    _loadExistingBookings();
  }

  Future<void> _loadExistingBookings() async {
    final bookings = await DatabaseService().getBookings();
    setState(() {
      _allBookings = bookings;
    });
  }

  void _calculatePending() {
    final total = double.tryParse(_totalAmountController.text) ?? 0;
    final received = double.tryParse(_receivedAmountController.text) ?? 0;
    setState(() {
      _pendingAmount = total - received;
    });
  }

  @override
  void dispose() {
    _brideNameController.dispose();
    _groomNameController.dispose();
    _totalAmountController.dispose();
    _advanceAmountController.dispose();
    _receivedAmountController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDates(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      if (!_selectedDates.any((d) => isSameDay(d, picked))) {
        setState(() {
          _selectedDates.add(picked);
          _selectedDates.sort();
        });
      }
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _extractFromText(String text) {
    if (text.isEmpty) return;

    setState(() {
      // Extract Phone: 10 digits
      final phoneRegex = RegExp(r'\b\d{10}\b');
      final phoneMatch = phoneRegex.firstMatch(text);
      if (phoneMatch != null) _phoneController.text = phoneMatch.group(0)!;

      // Extract Amounts: Look for numbers following keywords
      final totalRegex = RegExp(
        r'(?:total|bill|amount|rate)[:\-\s]*([0-9,.]+)',
        caseSensitive: false,
      );
      final totalMatch = totalRegex.firstMatch(text);
      if (totalMatch != null) {
        _totalAmountController.text = totalMatch.group(1)!.replaceAll(',', '');
      }

      final advanceRegex = RegExp(
        r'(?:advance|initial|paid|token)[:\-\s]*([0-9,.]+)',
        caseSensitive: false,
      );
      final advanceMatch = advanceRegex.firstMatch(text);
      if (advanceMatch != null) {
        _advanceAmountController.text = advanceMatch
            .group(1)!
            .replaceAll(',', '');
        if (_receivedAmountController.text.isEmpty) {
          _receivedAmountController.text = _advanceAmountController.text;
        }
      }

      // Extract Names: Look for "Bride: Name" or "Groom: Name"
      final brideRegex = RegExp(
        r'bride[:\-\s]*([a-zA-Z\s]+)',
        caseSensitive: false,
      );
      final brideMatch = brideRegex.firstMatch(text);
      if (brideMatch != null) {
        _brideNameController.text = brideMatch.group(1)!.trim();
      }

      final groomRegex = RegExp(
        r'groom[:\-\s]*([a-zA-Z\s]+)',
        caseSensitive: false,
      );
      final groomMatch = groomRegex.firstMatch(text);
      if (groomMatch != null) {
        _groomNameController.text = groomMatch.group(1)!.trim();
      }

      // Extract Address: Look for "Address: ..." until newline
      final addressRegex = RegExp(
        r'address[:\-\s]*([^\n\r]+)',
        caseSensitive: false,
      );
      final addressMatch = addressRegex.firstMatch(text);
      if (addressMatch != null) {
        _addressController.text = addressMatch.group(1)!.trim();
      }

      _calculatePending();
    });

    Haptics.success();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Details extracted successfully!'),
        backgroundColor: Color(0xFFD4AF37),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _saveBooking() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDates.isEmpty) {
        Haptics.medium();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one wedding date'),
          ),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final booking = Booking(
          id: widget.booking?.id ?? const Uuid().v4(),
          brideName: _brideNameController.text.trim(),
          groomName: _groomNameController.text.trim(),
          eventDates: _selectedDates,
          totalAmount: double.tryParse(_totalAmountController.text) ?? 0,
          advanceAmount: double.tryParse(_advanceAmountController.text) ?? 0,
          receivedAmount: double.tryParse(_receivedAmountController.text) ?? 0,
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          notes: _notesController.text.trim(),
          createdAt: widget.booking?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.booking == null) {
          await DatabaseService().insertBooking(booking);
        } else {
          await DatabaseService().updateBooking(booking);
        }

        // Schedule Notifications - DO NOT AWAIT to keep UI snappy
        NotificationService().scheduleBookingReminders(booking).catchError((e) {
          debugPrint('Silent Notification Error: $e');
        });

        Haptics.success();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Booking saved successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        Haptics.medium();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving booking: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Dynamic
      appBar: AppBar(
        title: Text(
          widget.booking == null ? 'New Booking' : 'Edit Booking',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        backgroundColor: Colors.transparent,
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveBooking,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSmartFillSection(),
            const SizedBox(height: 24),
            _buildSection([
              _buildTextField(
                _brideNameController,
                'Bride Name',
                Icons.person_outline,
              ),
              const Divider(height: 1, indent: 50),
              _buildTextField(_groomNameController, 'Groom Name', Icons.person),
            ]),

            const SizedBox(height: 24),
            const Text(
              'WEDDING DATES',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  ..._selectedDates.map(
                    (date) => Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.calendar_today,
                            color: Colors.amber,
                          ),
                          title: Text(DateFormat('MMMM d, yyyy').format(date)),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _selectedDates.remove(date);
                              });
                            },
                          ),
                        ),
                        if (date != _selectedDates.last)
                          const Divider(height: 1, indent: 16),
                      ],
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.add_circle_outline,
                      color: Color(0xFFD4AF37),
                    ),
                    onTap: () {
                      Haptics.light();
                      _selectDates(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              'FINANCES (₹)',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black54
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildSection([
              _buildTextField(
                _totalAmountController,
                'Total Amount',
                Icons.currency_rupee,
                keyboardType: TextInputType.number,
              ),
              const Divider(height: 1, indent: 50),
              _buildTextField(
                _advanceAmountController,
                'Advance (Initial)',
                Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const Divider(height: 1, indent: 50),
              _buildTextField(
                _receivedAmountController,
                'Total Received',
                Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
              ),
              const Divider(height: 1, indent: 50),
              ListTile(
                leading: const Icon(
                  Icons.pending_actions,
                  color: Colors.redAccent,
                ),
                title: const Text('Pending Amount'),
                trailing: Text(
                  '₹${_pendingAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 24),
            Text(
              'CONTACT DETAILS',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black54
                    : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildSection([
              _buildTextField(
                _phoneController,
                'Phone Number',
                Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const Divider(height: 1, indent: 50),
              _buildTextField(
                _addressController,
                'Address',
                Icons.location_on_outlined,
                maxLines: 3,
              ),
            ]),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartFillSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFD4AF37).withOpacity(0.1),
                const Color(0xFFD4AF37).withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFD4AF37),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LUXE SMART FILL',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD4AF37),
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  if (_phoneController.text.isNotEmpty ||
                      _brideNameController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _brideNameController.clear();
                          _groomNameController.clear();
                          _phoneController.clear();
                          _addressController.clear();
                          _totalAmountController.clear();
                          _receivedAmountController.clear();
                          _advanceAmountController.clear();
                          _selectedDates.clear();
                        });
                        Haptics.light();
                      },
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Notes / Special Requests',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.black54
                      : Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                _notesController,
                'Special instructions...',
                Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Search "Kiran" or paste WhatsApp message...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (val) {
                  if (val.isEmpty) {
                    setState(() {
                      _filteredLookupResults = [];
                      _isLookupFocused = false;
                    });
                    return;
                  }

                  setState(() {
                    _isLookupFocused = true;
                    _filteredLookupResults = _allBookings.where((b) {
                      final q = val.toLowerCase();
                      return b.brideName.toLowerCase().contains(q) ||
                          b.groomName.toLowerCase().contains(q) ||
                          b.phoneNumber.contains(q);
                    }).toList();
                  });

                  if (val.length > 20 || val.split(' ').length > 8) {
                    _extractFromText(val);
                  }
                },
              ),
            ],
          ),
        ),
        if (_isLookupFocused && _filteredLookupResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 250),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _filteredLookupResults.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  itemBuilder: (context, index) {
                    final b = _filteredLookupResults[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      title: Text(
                        b.brideName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Text(
                        '${b.phoneNumber} • ${b.address}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFFD4AF37),
                      ),
                      onTap: () {
                        setState(() {
                          _brideNameController.text = b.brideName;
                          _groomNameController.text = b.groomName;
                          _phoneController.text = b.phoneNumber;
                          _addressController.text = b.address;
                          _totalAmountController.text = b.totalAmount
                              .toStringAsFixed(0);
                          _receivedAmountController.text = b.receivedAmount
                              .toStringAsFixed(0);
                          _isLookupFocused = false;
                          _filteredLookupResults = [];
                        });
                        _calculatePending();
                        Haptics.selection();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: const Color(0xFFD4AF37).withOpacity(0.7),
            size: 18,
          ),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
          border: InputBorder.none,
          floatingLabelStyle: const TextStyle(color: Color(0xFFD4AF37)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        validator: (value) {
          if (label == 'Bride Name' ||
              label == 'Total Amount' ||
              label == 'Total Received') {
            if (value == null || value.trim().isEmpty) return 'Required';
          }
          return null;
        },
      ),
    );
  }
}

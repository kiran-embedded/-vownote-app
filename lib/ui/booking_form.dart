import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/services/notification_service.dart';
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

  List<DateTime> _selectedDates = [];
  double _pendingAmount = 0;
  bool _isSaving = false;

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
    _receivedAmountController.addListener(
      _calculatePending,
    ); // Listen to received, not advance for pending
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

  Future<void> _saveBooking() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDates.isEmpty) {
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

      final booking = Booking(
        id: widget.booking?.id ?? const Uuid().v4(),
        brideName: _brideNameController.text,
        groomName: _groomNameController.text,
        eventDates: _selectedDates,
        totalAmount: double.parse(_totalAmountController.text),
        advanceAmount: double.parse(_advanceAmountController.text),
        receivedAmount: double.parse(_receivedAmountController.text),
        address: _addressController.text,
        phoneNumber: _phoneController.text,
        createdAt: widget.booking?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.booking == null) {
        await DatabaseService().insertBooking(booking);
      } else {
        await DatabaseService().updateBooking(booking);
      }

      // Schedule Notifications
      await NotificationService().scheduleBookingReminders(booking);

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
                    title: const Text('Add Date'),
                    onTap: () => _selectDates(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'FINANCES (₹)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
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
            const Text(
              'CONTACT DETAILS',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
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
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: Theme.of(context).textTheme.bodyLarge,
        validator: (value) {
          if (label == 'Bride Name' ||
              label == 'Total Amount' ||
              label == 'Total Received') {
            if (value == null || value.isEmpty) return 'Required';
          }
          return null;
        },
      ),
    );
  }
}

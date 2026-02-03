import 'package:flutter/material.dart';

import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:vownote/utils/display_engine.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/services/notification_service.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:uuid/uuid.dart';
import 'package:vownote/services/localization_service.dart';
import 'package:vownote/services/snapshot_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vownote/services/business_service.dart';

class BookingFormScreen extends StatefulWidget {
  final Booking? booking;

  const BookingFormScreen({super.key, this.booking});

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _brideNameController;
  late TextEditingController _groomNameController;
  late TextEditingController _totalAmountController;
  late TextEditingController _totalAdvanceController;
  late TextEditingController _advReceivedController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _altPhoneController;
  late TextEditingController _notesController;
  late TextEditingController _diaryCodeController;

  List<DateTime> _selectedDates = [];
  String _selectedCategory = 'None';
  double _pendingAmount = 0;
  bool _isSuccess = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(
      text: widget.booking?.customerName ?? '',
    );
    _brideNameController = TextEditingController(
      text: widget.booking?.brideName ?? '',
    );
    _groomNameController = TextEditingController(
      text: widget.booking?.groomName ?? '',
    );
    _totalAmountController = TextEditingController(
      text: widget.booking?.totalAmount.toString() ?? '',
    );
    _totalAdvanceController = TextEditingController(
      text: widget.booking?.totalAdvance.toString() ?? '',
    );
    _advReceivedController = TextEditingController(
      text: widget.booking?.advanceReceived.toString() ?? '',
    );
    _addressController = TextEditingController(
      text: widget.booking?.address ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.booking?.phoneNumber ?? '',
    );
    _altPhoneController = TextEditingController(
      text: widget.booking?.alternatePhone ?? '',
    );
    _notesController = TextEditingController(text: widget.booking?.notes ?? '');
    _diaryCodeController = TextEditingController(
      text: widget.booking?.diaryCode ?? '',
    );
    _selectedDates = List.from(widget.booking?.eventDates ?? []);
    _selectedCategory = widget.booking?.bookingCategory ?? 'None';

    _calculateFinance();
    _totalAmountController.addListener(_calculateFinance);
    _totalAdvanceController.addListener(_calculateFinance);
    _advReceivedController.addListener(_calculateFinance);
  }

  void _calculateFinance() {
    final total = double.tryParse(_totalAmountController.text) ?? 0;
    final totalAdv = double.tryParse(_totalAdvanceController.text) ?? 0;
    final advRec = double.tryParse(_advReceivedController.text) ?? 0;
    setState(() {
      _pendingAmount = total - advRec;
    });
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _brideNameController.dispose();
    _groomNameController.dispose();
    _totalAmountController.dispose();
    _totalAdvanceController.dispose();
    _advReceivedController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();
    _notesController.dispose();
    _diaryCodeController.dispose();
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
        Haptics.medium();
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select wedding dates')),
          );
        return;
      }

      setState(() => _isSaving = true);

      try {
        final booking = Booking(
          id: widget.booking?.id ?? const Uuid().v4(),
          customerName: _customerNameController.text.trim(),
          brideName: _brideNameController.text.trim(),
          groomName: _groomNameController.text.trim(),
          eventDates: _selectedDates,
          totalAmount: double.tryParse(_totalAmountController.text) ?? 0,
          totalAdvance: double.tryParse(_totalAdvanceController.text) ?? 0,
          advanceReceived: double.tryParse(_advReceivedController.text) ?? 0,
          address: _addressController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          alternatePhone: _altPhoneController.text.trim(),
          notes: _notesController.text.trim(),
          bookingCategory: _selectedCategory,
          diaryCode: _diaryCodeController.text.trim(),
          businessType:
              widget.booking?.businessType ??
              BusinessService().currentType.name,
          createdAt: widget.booking?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (widget.booking == null) {
          await DatabaseService().insertBooking(booking);
        } else {
          await DatabaseService().updateBooking(booking);
        }

        NotificationService()
            .scheduleBookingReminders(booking)
            .catchError((e) => debugPrint('Notification Error: $e'));

        if (mounted) {
          setState(() {
            _isSuccess = true;
            _isSaving = false;
          });
          Haptics.success();
          await Future.delayed(const Duration(milliseconds: 2000));
          Navigator.pop(context, booking);
        }
      } catch (e) {
        Haptics.medium();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareAsImage() async {
    final booking = Booking(
      id: '',
      customerName: _customerNameController.text,
      brideName: _brideNameController.text,
      groomName: _groomNameController.text,
      eventDates: _selectedDates,
      totalAmount: double.tryParse(_totalAmountController.text) ?? 0,
      totalAdvance: double.tryParse(_totalAdvanceController.text) ?? 0,
      advanceReceived: double.tryParse(_advReceivedController.text) ?? 0,
      address: _addressController.text,
      phoneNumber: _phoneController.text,
      alternatePhone: _altPhoneController.text,
      notes: _notesController.text,
      bookingCategory: _selectedCategory,
      diaryCode: _diaryCodeController.text,
    );

    final shareWidget = Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VowNote',
                style: TextStyle(
                  color: Color(0xFFD4AF37),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              if (booking.diaryCode.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    booking.displayIdentity,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            booking.customerName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Divider(),
          _buildShareInfo(
            Icons.calendar_today,
            BusinessService().config.eventLabel,
            booking.eventDates
                .map((d) => DateFormat('MMM d, yyyy').format(d))
                .join('\n'),
          ),
          if (booking.phoneNumber.isNotEmpty)
            _buildShareInfo(Icons.phone, 'Phone', booking.phoneNumber),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildShareFinance('Total', booking.totalAmount, Colors.black),
                _buildShareFinance(
                  'Advance Paid',
                  booking.advanceReceived,
                  Colors.orange,
                ),
                const Divider(),
                _buildShareFinance(
                  'Pending',
                  booking.pendingAmount,
                  Colors.red,
                  isBold: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await SnapshotService().captureAndShare(
      shareWidget,
      fileName: 'VowNote_Booking_${booking.customerName}',
    );
  }

  Widget _buildShareInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareFinance(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    DisplayEngine.init(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _isSuccess
              ? 'Saved!'
              : (widget.booking == null ? 'New Booking' : 'Edit Booking'),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          if (widget.booking != null)
            IconButton(
              icon: const Icon(Icons.share_outlined, color: Color(0xFFD4AF37)),
              onPressed: _shareAsImage,
            ),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: CupertinoActivityIndicator(),
                )
              : GestureDetector(
                  onTapDown: (_) => Haptics.light(),
                  onTap: _saveBooking,
                  child:
                      Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              tr('done').toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD4AF37),
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.stop())
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(0.9, 0.9),
                            duration: 100.ms,
                          ),
                ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              cacheExtent: 1000,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children:
                  [
                        RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(tr('diary_mgmt')),
                              _buildSection([
                                if (BusinessService()
                                    .config
                                    .showEventCategory) ...[
                                  _buildCategorySelector(),
                                  const Divider(height: 1, indent: 50),
                                ],
                                _buildTextField(
                                  _diaryCodeController,
                                  tr('diary_code'),
                                  Icons.auto_stories_outlined,
                                ),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Customer Information'),
                              _buildSection([
                                _buildTextField(
                                  _customerNameController,
                                  tr('customer'),
                                  Icons.badge_outlined,
                                  required: true,
                                ),
                                const Divider(height: 1, indent: 50),
                                // Business-specific client fields
                                if (BusinessService()
                                    .config
                                    .showClientFields) ...[
                                  _buildTextField(
                                    _brideNameController,
                                    BusinessService().config.client1Label,
                                    Icons.person_outline,
                                  ),
                                  const Divider(height: 1, indent: 50),
                                  _buildTextField(
                                    _groomNameController,
                                    BusinessService().config.client2Label,
                                    Icons.person,
                                  ),
                                ],
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(
                                BusinessService().config.eventLabel,
                              ),
                              _buildDatesSection(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Finance details (₹)'),
                              _buildSection([
                                _buildTextField(
                                  _totalAmountController,
                                  tr('total'),
                                  Icons.currency_rupee,
                                  keyboardType: TextInputType.number,
                                ),
                                const Divider(height: 1, indent: 50),
                                _buildTextField(
                                  _totalAdvanceController,
                                  tr('total_adv'),
                                  Icons.payments_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                                const Divider(height: 1, indent: 50),
                                _buildTextField(
                                  _advReceivedController,
                                  tr('adv_received'),
                                  Icons.check_circle_outline,
                                  keyboardType: TextInputType.number,
                                ),
                                const Divider(height: 1, indent: 50),
                                _buildPendingTile(
                                  tr('due'),
                                  _pendingAmount,
                                  Colors.red,
                                ),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('Contact details'),
                              _buildSection([
                                _buildTextField(
                                  _phoneController,
                                  tr('phone'),
                                  Icons.phone,
                                  keyboardType: TextInputType.phone,
                                ),
                                const Divider(height: 1, indent: 50),
                                _buildTextField(
                                  _altPhoneController,
                                  tr('alt_phone'),
                                  Icons.phone_android_outlined,
                                  keyboardType: TextInputType.phone,
                                ),
                                const Divider(height: 1, indent: 50),
                                _buildTextField(
                                  _addressController,
                                  tr('address'),
                                  Icons.location_on_outlined,
                                  maxLines: 2,
                                ),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle(tr('notes')),
                              _buildSection([
                                _buildTextField(
                                  _notesController,
                                  'Internal notes...',
                                  Icons.notes,
                                  maxLines: 4,
                                ),
                              ]),
                            ],
                          ),
                        ),
                      ]
                      .animate(interval: 50.ms)
                      .fadeIn(duration: 400.ms)
                      .move(
                        begin: const Offset(0, 10),
                        duration: 400.ms,
                        curve: Curves.easeOut,
                      ),
            ),
          ),
          if (_isSuccess) _buildSuccessAnimation(),
        ],
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      color: Colors.black.withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Colors.white,
                    size: 80,
                  ),
                )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  duration: 1000.ms,
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.1, 1.1),
                  curve: Curves.easeInOutBack,
                )
                .shimmer(
                  delay: 500.ms,
                  duration: 1500.ms,
                  color: Colors.white24,
                ),
            const SizedBox(height: 24),
            Text(
                  'Saved Successfully',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFD4AF37),
                    letterSpacing: 0.5,
                  ),
                )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  curve: Curves.easeOutBack,
                ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.category_outlined,
            color: Color(0xFFD4AF37),
            size: 18,
          ),
          const SizedBox(width: 12),
          Text(tr('category'), style: const TextStyle(fontSize: 13)),
          const Spacer(),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'Male',
                label: Text(tr('male'), style: const TextStyle(fontSize: 10)),
              ),
              ButtonSegment(
                value: 'Female',
                label: Text(tr('female'), style: const TextStyle(fontSize: 10)),
              ),
              const ButtonSegment(
                value: 'None',
                label: Text('N/A', style: TextStyle(fontSize: 10)),
              ),
            ],
            selected: {_selectedCategory},
            onSelectionChanged: (v) =>
                setState(() => _selectedCategory = v.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(15),
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
                    size: 20,
                  ),
                  title: Text(DateFormat('MMMM d, yyyy').format(date)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        setState(() => _selectedDates.remove(date)),
                  ),
                ),
                if (date != _selectedDates.last)
                  const Divider(height: 1, indent: 50),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFFD4AF37),
            ),
            title: const Text(
              'Add Date',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () => _selectDates(context),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTile(String label, double amount, Color color) {
    return ListTile(
      leading: Icon(Icons.pending_actions, color: color.withOpacity(0.8)),
      title: Text(label, style: const TextStyle(fontSize: 13)),
      trailing: Text(
        '₹${amount.toStringAsFixed(0)}',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

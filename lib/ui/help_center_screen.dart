import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:vownote/services/business_service.dart';
import 'package:vownote/services/localization_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expandedIndex;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  static const _gold = Color(0xFFD4AF37);

  String _localTr(String key, String fallback) {
    final val = tr(key);
    return val == key ? fallback : val;
  }

  List<_HelpItem> get _helpItems => [
    _HelpItem(
      icon: Icons.add_circle_outline_rounded,
      emoji: '➕',
      color: const Color(0xFFD4AF37),
      title: tr('help_create_title'),
      summary: 'Create and manage your bookings',
      steps: [
        tr('help_create_step1'),
        tr('help_create_step2'),
        tr('help_create_step3'),
        tr('help_create_step4'),
        tr('help_create_step5'),
      ],
    ),
    _HelpItem(
      icon: Icons.business_center_rounded,
      emoji: '🏢',
      color: const Color(0xFF6366F1),
      title: tr('help_biz_title'),
      summary: 'Configure your business type & profile',
      steps: [tr('help_biz_step1'), tr('help_biz_step2'), tr('help_biz_step3')],
    ),
    _HelpItem(
      icon: Icons.calculate_rounded,
      emoji: '💰',
      color: const Color(0xFF10B981),
      title: tr('help_calc_title'),
      summary: 'Understand amounts, tax, and pending',
      steps: [
        tr('help_calc_step1'),
        tr('help_calc_step2'),
        tr('help_calc_step3'),
      ],
    ),
    _HelpItem(
      icon: Icons.payments_outlined,
      emoji: '✅',
      color: Colors.teal,
      title: 'Mark Payment Received',
      summary: 'How to record payment from a client',
      steps: [
        'Go to Home and tap the "Pending Amount" stat card.',
        'In the pending list, swipe LEFT (←) on a booking.',
        'A confirmation sheet will appear showing the exact amount.',
        'Tap "Confirm" to mark it as fully received.',
        'The booking immediately updates to Paid ✓ in the list.',
      ],
    ),
    _HelpItem(
      icon: Icons.swipe_rounded,
      emoji: '👆',
      color: const Color(0xFF8B5CF6),
      title: _localTr('help_gestures_title', 'Gestures & Shortcuts'),
      summary: 'Swipe, tap, long-press quick actions',
      steps: [
        'Swipe LEFT ← on a home booking card to DELETE it (with confirmation).',
        'Swipe RIGHT → on a home booking card to open Share options.',
        'Swipe RIGHT → on detail page cards to send WhatsApp thank-you.',
        'Swipe LEFT ← on pending detail cards to Mark as Received.',
        'Long-press any booking to enter SELECTION MODE for bulk delete.',
        'Tap a booking card to open and edit full details.',
      ],
    ),
    _HelpItem(
      icon: Icons.share_rounded,
      emoji: '📤',
      color: const Color(0xFF06B6D4),
      title: tr('help_share_title'),
      summary: 'Share bookings via WhatsApp or PDF',
      steps: [
        tr('help_share_step1'),
        tr('help_share_step2'),
        tr('help_share_step3'),
        'Swipe right → on detail page booking cards to send a personalised WhatsApp thank-you message.',
      ],
    ),
    _HelpItem(
      icon: Icons.delete_sweep_outlined,
      emoji: '🗑️',
      color: Colors.red,
      title: 'Delete Bookings',
      summary: 'Delete single or multiple bookings',
      steps: [
        'Single delete: Swipe LEFT on any booking card on the home screen.',
        'A confirmation dialog will appear — tap Delete to confirm.',
        'Bulk delete: Long-press any booking to enter selection mode.',
        'A bar slides up from the bottom — tap more cards to select them.',
        'Tap the red "Delete (N)" button to delete all selected at once.',
        'Tap "Cancel" to exit selection mode without deleting.',
      ],
    ),
    _HelpItem(
      icon: Icons.calendar_month_rounded,
      emoji: '📅',
      color: const Color(0xFFEF4444),
      title: _localTr('help_calendar_title', 'Using the Calendar'),
      summary: 'View and manage bookings by date',
      steps: [
        _localTr('help_calendar_step1', 'Tap the Calendar tab at the bottom of the screen.'),
        _localTr('help_calendar_step2', 'Dates with bookings are highlighted with a gold dot.'),
        _localTr('help_calendar_step3', 'Tap any highlighted date to see its bookings below.'),
        _localTr('help_calendar_step4', 'Tap a booking from the list to open and edit it.'),
      ],
    ),
    _HelpItem(
      icon: Icons.filter_list_rounded,
      emoji: '🔍',
      color: const Color(0xFFF59E0B),
      title: 'Filters & Search',
      summary: 'Find bookings quickly with smart filters',
      steps: [
        'Use the search bar on the home screen to search by name, phone, location, or ID.',
        'Tap filter pills (This Month, Client, Payment, More Filters) to narrow results.',
        '"This Month" pill has a dropdown: Today, This Week, Last Month, Custom Range.',
        '"Payment" filter: All, Paid, Advance, Due, Upcoming, Cancelled.',
        '"More Filters" lets you filter by Service, Location, Amount range, and Sort.',
        'All filters work across all business modes (Wedding, Photography, Catering, etc.).',
      ],
    ),
    _HelpItem(
      icon: Icons.backup_rounded,
      emoji: '☁️',
      color: const Color(0xFF3B82F6),
      title: tr('help_backup_title'),
      summary: 'Backup and restore your data',
      steps: [
        tr('help_backup_step1'),
        tr('help_backup_step2'),
        tr('help_backup_step3'),
        tr('help_backup_step4'),
      ],
    ),
  ];

  List<_HelpItem> get _filtered {
    if (_searchQuery.isEmpty) return _helpItems;
    final q = _searchQuery.toLowerCase();
    return _helpItems.where((item) =>
      item.title.toLowerCase().contains(q) ||
      item.summary.toLowerCase().contains(q) ||
      item.steps.any((s) => s.toLowerCase().contains(q))
    ).toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = BusinessService().config;
    final items = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ───────────────────────────────────────────────
            _buildHeader(config),
            // ─── Search ───────────────────────────────────────────────
            _buildSearch(),
            // ─── Quick actions row ────────────────────────────────────
            if (_searchQuery.isEmpty) _buildQuickActions(),
            // ─── List ─────────────────────────────────────────────────
            Expanded(
              child: items.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      itemCount: items.length,
                      itemBuilder: (_, i) => _buildCard(i, items[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(businessConfig) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0A0A0A),
        border: Border(bottom: BorderSide(color: Color(0xFF1A1A1A))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () { Haptics.light(); Navigator.pop(context); },
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _gold.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: _gold, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      businessConfig.displayName,
                      style: const TextStyle(color: _gold, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.help_outline_rounded, color: _gold, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help Centre',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Everything you need to know',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
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
            Icon(Icons.search, color: Colors.grey[600], size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                autofocus: false,
                onChanged: (v) => setState(() { _searchQuery = v; _expandedIndex = null; }),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search help topics...',
                  hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  filled: false,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchCtrl.clear();
                  setState(() { _searchQuery = ''; _expandedIndex = null; });
                },
                child: Icon(Icons.close, color: Colors.grey[600], size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final chips = [
      ('Getting Started', Icons.rocket_launch_outlined, const Color(0xFFD4AF37)),
      ('Payments', Icons.payments_outlined, Colors.teal),
      ('Gestures', Icons.swipe_rounded, const Color(0xFF8B5CF6)),
      ('Delete', Icons.delete_outline, Colors.red),
    ];
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
        itemCount: chips.length,
        itemBuilder: (_, i) {
          final (label, icon, color) = chips[i];
          return GestureDetector(
            onTap: () {
              Haptics.light();
              setState(() { _searchQuery = label.split(' ').last.toLowerCase(); });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 14),
                  const SizedBox(width: 6),
                  Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(int index, _HelpItem item) {
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () {
        Haptics.light();
        setState(() => _expandedIndex = isExpanded ? null : index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isExpanded ? item.color.withOpacity(0.4) : Colors.white.withOpacity(0.05),
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: isExpanded
              ? [BoxShadow(color: item.color.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 4))]
              : null,
        ),
        child: Column(
          children: [
            // ─── Header row ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(item.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.summary,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isExpanded ? item.color.withOpacity(0.15) : Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: isExpanded ? item.color : Colors.grey[600],
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            // ─── Expanded steps ─────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      child: Column(
                        children: [
                          Divider(color: item.color.withOpacity(0.15), height: 1),
                          const SizedBox(height: 14),
                          ...item.steps.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24, height: 24,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 13,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate(delay: (entry.key * 40).ms).fadeIn(duration: 200.ms).slideX(begin: -0.05, end: 0);
                          }),
                          const SizedBox(height: 4),
                          // Helpful?
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('Helpful?', style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                              const SizedBox(width: 8),
                              _feedbackBtn(Icons.thumb_up_outlined, 'Yes', Colors.green, () {
                                Haptics.success();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Thanks for your feedback! 👍'), duration: Duration(seconds: 1)),
                                );
                              }),
                              const SizedBox(width: 4),
                              _feedbackBtn(Icons.thumb_down_outlined, 'No', Colors.red, () {
                                Haptics.medium();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('We\'ll improve this. Thanks!'), duration: Duration(seconds: 1)),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ).animate(delay: (index * 40).ms).fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0),
    );
  }

  Widget _feedbackBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            'No results for "$_searchQuery"',
            style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
            child: Text('Clear search', style: TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}

class _HelpItem {
  final IconData icon;
  final String emoji;
  final Color color;
  final String title;
  final String summary;
  final List<String> steps;
  const _HelpItem({
    required this.icon,
    required this.emoji,
    required this.color,
    required this.title,
    required this.summary,
    required this.steps,
  });
}

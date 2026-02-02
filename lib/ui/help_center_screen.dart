import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:vownote/services/business_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _expandedIndex;

  final List<HelpSection> _helpSections = [
    HelpSection(
      icon: Icons.add_circle_outline,
      title: 'Creating a Booking',
      content:
          'Tap the + button to create a new booking. Fill in customer details, event dates, and financial information. The app will automatically calculate pending amounts and tax if configured.',
      steps: [
        'Tap the floating + button on the home screen',
        'Enter customer name (required)',
        'Select event dates using the calendar',
        'Add financial details (total, advance, payments)',
        'Optionally add client names, phone, address',
        'Tap DONE to save',
      ],
    ),
    HelpSection(
      icon: Icons.business_center,
      title: 'Business Types',
      content:
          'VowNote supports multiple business types. Each type customizes the app with appropriate terminology and icons for your industry.',
      steps: [
        'Go to Settings → Business Type',
        'Choose from Wedding, Photography, Catering, Events, or General',
        'Confirm your selection',
        'App UI will update automatically',
      ],
    ),
    HelpSection(
      icon: Icons.palette_outlined,
      title: 'Material You Theming',
      content:
          'Enable Material You to make the app match your device wallpaper colors (Android 12+). Toggle between dynamic and static themes anytime.',
      steps: [
        'Go to Settings',
        'Find "Material You" toggle',
        'Enable to use system colors',
        'Disable to use classic gold theme',
      ],
    ),
    HelpSection(
      icon: Icons.calculate,
      title: 'Advanced Calculations',
      content:
          'Track payments with detailed calculations including tax, discounts, and multiple payment methods. View installment plans and payment history.',
      steps: [
        'In booking form, add total amount',
        'Add advance and received amounts',
        'App auto-calculates pending',
        'Add tax rate (e.  g., 18 for GST)',
        'Apply discounts (% or fixed)',
        'Track multiple payments',
      ],
    ),
    HelpSection(
      icon: Icons.share,
      title: 'Sharing & Export',
      content:
          'Export bookings as images or PDFs. Customize what information appears in exports from Settings.',
      steps: [
        'Open any booking',
        'Tap share icon',
        'Choose export format',
        'Customize export settings in Settings',
      ],
    ),
    HelpSection(
      icon: Icons.dark_mode,
      title: 'Dark Mode',
      content:
          'Switch between light and dark themes with optimized animations. Dark mode uses true black for OLED battery savings.',
      steps: [
        'Go to Settings',
        'Toggle "Dark Mode"',
        'Theme changes instantly with smooth animation',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleSection(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
        Haptics.light();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final businessConfig = BusinessService().config;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Help Center',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.3),
                      theme.colorScheme.primary.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child:
                      Icon(
                            Icons.help_outline_rounded,
                            size: 80,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          )
                          .animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            duration: 2000.ms,
                            begin: const Offset(0.9, 0.9),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scale(
                            duration: 2000.ms,
                            begin: const Offset(1.1, 1.1),
                            end: const Offset(0.9, 0.9),
                            curve: Curves.easeInOut,
                          ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child:
                  Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withOpacity(
                            0.3,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              businessConfig.primaryIcon,
                              size: 48,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Using ${businessConfig.appTitle}',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Configured for ${businessConfig.displayName}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final section = _helpSections[index];
                final isExpanded = _expandedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _toggleSection(index),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isExpanded
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isExpanded
                              ? [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      section.icon,
                                      color: theme.colorScheme.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      section.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                            AnimatedSize(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              child: isExpanded
                                  ? Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        0,
                                        20,
                                        20,
                                      ),
                                      child:
                                          Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Divider(),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    section.content,
                                                    style: TextStyle(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurface
                                                          .withOpacity(0.7),
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Text(
                                                    'Steps:',
                                                    style: GoogleFonts.inter(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ...section.steps.asMap().entries.map((
                                                    entry,
                                                  ) {
                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 8,
                                                          ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Container(
                                                            width: 24,
                                                            height: 24,
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: theme
                                                                      .colorScheme
                                                                      .primary,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            child: Center(
                                                              child: Text(
                                                                '${entry.key + 1}',
                                                                style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              entry.value,
                                                              style: TextStyle(
                                                                color: theme
                                                                    .colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                      0.8,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }),
                                                ],
                                              )
                                              .animate()
                                              .fadeIn(duration: 200.ms)
                                              .slideY(
                                                begin: -0.1,
                                                end: 0,
                                                curve: Curves.easeOut,
                                              ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                );
              }, childCount: _helpSections.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class HelpSection {
  final IconData icon;
  final String title;
  final String content;
  final List<String> steps;

  HelpSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.steps,
  });
}

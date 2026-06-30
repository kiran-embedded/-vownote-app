import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vownote/utils/display_engine.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:vownote/services/business_service.dart';
import 'package:vownote/services/localization_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _expandedIndex;
  String _searchQuery = '';

  String _localTr(String key, String fallback) {
    final val = tr(key);
    return val == key ? fallback : val;
  }

  List<HelpSection> getHelpSections(BuildContext context) {
    return [
      HelpSection(
        icon: Icons.add_circle_outline,
        title: tr('help_create_title'),
        content: tr('help_create_content'),
        steps: [
          tr('help_create_step1'),
          tr('help_create_step2'),
          tr('help_create_step3'),
          tr('help_create_step4'),
          tr('help_create_step5'),
        ],
      ),
      HelpSection(
        icon: Icons.business_center,
        title: tr('help_biz_title'),
        content: tr('help_biz_content'),
        steps: [tr('help_biz_step1'), tr('help_biz_step2'), tr('help_biz_step3')],
      ),
      HelpSection(
        icon: Icons.calculate,
        title: tr('help_calc_title'),
        content: tr('help_calc_content'),
        steps: [
          tr('help_calc_step1'),
          tr('help_calc_step2'),
          tr('help_calc_step3'),
        ],
      ),
      HelpSection(
        icon: Icons.share,
        title: tr('help_share_title'),
        content: tr('help_share_content'),
        steps: [
          tr('help_share_step1'),
          tr('help_share_step2'),
          tr('help_share_step3'),
        ],
      ),
      HelpSection(
        icon: Icons.gesture_rounded,
        title: _localTr('help_gestures_title', 'Gestures & Shortcuts'),
        content: _localTr('help_gestures_content', 'Use swipe actions and shortcuts on the home screen to manage bookings quickly and efficiently.'),
        steps: [
          _localTr('help_gestures_step1', 'Swipe LEFT on any booking to trigger delete confirmation.'),
          _localTr('help_gestures_step2', 'Swipe RIGHT on any booking to instantly trigger clients share options.'),
          _localTr('help_gestures_step3', 'Tap any booking card to open and edit its details.'),
          _localTr('help_gestures_step4', 'Long-press a booking card to activate selection mode for bulk delete/share.'),
        ],
      ),
      HelpSection(
        icon: Icons.dark_mode,
        title: tr('help_dark_title'),
        content: tr('help_dark_content'),
        steps: [tr('help_dark_step1'), tr('help_dark_step2')],
      ),
      HelpSection(
        icon: Icons.backup,
        title: tr('help_backup_title'),
        content: tr('help_backup_content'),
        steps: [
          tr('help_backup_step1'),
          tr('help_backup_step2'),
          tr('help_backup_step3'),
          tr('help_backup_step4'),
        ],
      ),
    ];
  }

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

    return AnimatedBuilder(
      animation: LocalizationService(),
      builder: (context, child) {
        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar.large(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    tr('help_center'),
                    style: DisplayEngine.font(fontWeight: FontWeight.bold),
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
                                color: theme.colorScheme.primary.withOpacity(
                                  0.5,
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
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
                              color: theme.colorScheme.primaryContainer
                                  .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.2,
                                ),
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
                                  style: DisplayEngine.font(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Configured for ${businessConfig.displayName}',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(
                            begin: -0.2,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _expandedIndex = null;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: _localTr('search_help', 'Search help topics...'),
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: theme.colorScheme.primary.withOpacity(0.6),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _expandedIndex = null;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.cardColor,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                sliver: Builder(
                  builder: (context) {
                    final sections = getHelpSections(context);
                    final filteredSections = sections.where((section) {
                      if (_searchQuery.isEmpty) return true;
                      final query = _searchQuery.toLowerCase();
                      final titleMatch = section.title.toLowerCase().contains(query);
                      final contentMatch = section.content.toLowerCase().contains(query);
                      final stepsMatch = section.steps.any((step) => step.toLowerCase().contains(query));
                      return titleMatch || contentMatch || stepsMatch;
                    }).toList();

                    if (filteredSections.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 64,
                                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _localTr('no_results', 'No help topics found'),
                                  style: DisplayEngine.font(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final section = filteredSections[index];
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
                                              borderRadius: BorderRadius.circular(
                                                12,
                                              ),
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
                                              style: DisplayEngine.font(
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
                                              child: Column(
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
                                                    _localTr('steps', 'Steps:'),
                                                    style: DisplayEngine.font(
                                                      fontWeight: FontWeight.w600,
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
                                                                style:
                                                                    const TextStyle(
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
                                                          const SizedBox(width: 12),
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
                                                  const SizedBox(height: 12),
                                                  const Divider(),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        _localTr('was_helpful', 'Was this helpful?'),
                                                        style: TextStyle(
                                                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      Row(
                                                        children: [
                                                          TextButton.icon(
                                                            onPressed: () {
                                                              Haptics.success();
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(_localTr('feedback_thanks', 'Thanks for your feedback!')),
                                                                  duration: const Duration(seconds: 1),
                                                                ),
                                                              );
                                                            },
                                                            icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                                                            label: Text(_localTr('yes', 'Yes')),
                                                          ),
                                                          TextButton.icon(
                                                            onPressed: () {
                                                              Haptics.medium();
                                                              ScaffoldMessenger.of(context).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(_localTr('feedback_improve', 'We will improve this topic.')),
                                                                  duration: const Duration(seconds: 1),
                                                                ),
                                                              );
                                                            },
                                                            icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                                                            label: Text(_localTr('no', 'No')),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.1, end: 0, curve: Curves.easeOut),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate(delay: (index * 50).ms).fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
                        );
                      }, childCount: filteredSections.length),
                    );
                  }
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        );
      },
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

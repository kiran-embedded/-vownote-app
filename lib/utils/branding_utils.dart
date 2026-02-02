import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vownote/utils/haptics.dart';
import 'package:flutter/cupertino.dart';

class BrandingUtils {
  static const String githubUrl = 'https://github.com/kiran-embedded';

  static Future<void> launchGitHub() async {
    final Uri url = Uri.parse(githubUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $githubUrl');
    }
  }
}

class GitHubWatermark extends StatelessWidget {
  final bool compact;
  const GitHubWatermark({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              Haptics.light();
              BrandingUtils.launchGitHub();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 16,
                vertical: compact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black).withOpacity(
                    0.1,
                  ),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.code_rounded,
                    size: compact ? 14 : 16,
                    color: const Color(0xFFF5F5F5), // Platinum white
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'github.com/kiran-embedded',
                    style: GoogleFonts.inter(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 2500.ms,
          color: const Color(0xFFF5F5F5), // Platinum white shimmer
          angle: 45,
        )
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.2, curve: Curves.easeOutCubic)
        .scale(end: const Offset(1.0, 1.0), duration: 200.ms);
  }
}

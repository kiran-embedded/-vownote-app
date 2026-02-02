import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ShimmerText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color> shimmerColors;
  final Duration duration;

  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.shimmerColors = const [
      Color(0xFFD4AF37), // Gold
      Color(0xFFFFD700), // Lighter Gold
      Color(0xFFD4AF37), // Gold
      Color(0xFFC5A028), // Darker Gold
      Color(0xFFD4AF37), // Gold
    ],
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style)
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: duration,
          colors: shimmerColors,
          angle: 45, // Angled shimmer for premium look
        );
  }
}

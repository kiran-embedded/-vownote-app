import 'package:flutter/material.dart';
import 'package:vownote/services/performance_service.dart';

class GlobalPerformanceOverlay extends StatelessWidget {
  final Widget? child;

  const GlobalPerformanceOverlay({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          if (child != null) child!,
          Positioned(
            top: MediaQuery.of(context).padding.top + 5,
            right: 16,
            child: IgnorePointer(
              child: ValueListenableBuilder<bool>(
                valueListenable:
                    PerformanceService().isFpsOverlayEnabledNotifier,
                builder: (context, isEnabled, _) {
                  if (!isEnabled) return const SizedBox.shrink();

                  return ValueListenableBuilder<double>(
                    valueListenable: PerformanceService().fpsNotifier,
                    builder: (context, fps, _) {
                      final service = PerformanceService();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: fps < 50 ? Colors.red : Colors.green,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'FPS: ',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  fps.toInt().toString(),
                                  style: TextStyle(
                                    color: fps < 50
                                        ? Colors.redAccent
                                        : Colors.greenAccent,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                            _buildMetric('UI', service.uiTimeMs),
                            _buildMetric('GPU', service.gpuTimeMs),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          '${value.toStringAsFixed(1)}ms',
          style: TextStyle(
            color: value > 16.6 ? Colors.orangeAccent : Colors.white70,
            fontSize: 8,
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

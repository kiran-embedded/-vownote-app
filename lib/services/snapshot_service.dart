import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnapshotService {
  static final SnapshotService _instance = SnapshotService._internal();
  factory SnapshotService() => _instance;
  SnapshotService._internal();

  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> captureAndShare(
    Widget widget, {
    String fileName = 'VowNote_Share',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final use4K = prefs.getBool('use_4k_screenshots') ?? true;

    // 4K pixel ratio is typically 3.0 to 4.5 depending on device,
    // we use a high multiplier for pro results.
    final double pixelRatio = use4K ? 4.0 : 2.0;

    try {
      final image = await screenshotController.captureFromWidget(
        Material(color: Colors.transparent, child: widget),
        pixelRatio: pixelRatio,
        delay: const Duration(milliseconds: 200),
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/$fileName.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([
        XFile(imagePath.path),
      ], text: 'Shared from VowNote Professional');
    } catch (e) {
      debugPrint('Snapshot Error: $e');
    }
  }
}

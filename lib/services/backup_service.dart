import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:intl/intl.dart';

class BackupService {
  // Helper for background JSON encoding
  static String _encodeBookings(List<Booking> bookings) {
    return jsonEncode(bookings.map((e) => e.toMap()).toList());
  }

  // Helper for background JSON decoding
  static List<Booking> _decodeBookings(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((map) => Booking.fromMap(map)).toList();
  }

  // Request: Manage External Storage for Android 11+
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }
      return status.isGranted;
    }
    return true;
  }

  // Silent Backup: Saves to App Documents or External if allowed
  Future<void> silentBackup() async {
    try {
      final db = DatabaseService();
      final bookings = await db.getBookings();
      // Use compute to move encoding off the main thread
      final data = await compute(_encodeBookings, bookings);

      Directory? directory;
      if (Platform.isAndroid) {
        // Try to get external storage directory first (App Specific)
        directory = await getExternalStorageDirectory();
        // Or if MANAGE_EXTERNAL_STORAGE is truly granted, use specific folder
        if (await Permission.manageExternalStorage.isGranted) {
          final publicDir = Directory('/storage/emulated/0/Documents/VowNote');
          if (!await publicDir.exists()) {
            await publicDir.create(recursive: true);
          }
          directory = publicDir;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        final file = File('${directory.path}/vownote_master_backup.json');
        await file.writeAsString(data);
        debugPrint('Silent auto-sync saved to: ${file.path}');
      }
    } catch (e) {
      debugPrint('Silent backup failed: $e');
    }
  }

  // Export: Shared storage (/Documents/VowNote) or Share Sheet
  Future<String> exportBackup() async {
    final db = DatabaseService();
    final bookings = await db.getBookings();

    if (bookings.isEmpty) {
      throw Exception("No bookings to backup.");
    }

    // Use compute to move encoding off the main thread
    final data = await compute(_encodeBookings, bookings);
    const fileName = 'vownote_master_backup.json';

    // 1. Try to save to "Documents/VowNote" (Persistent Master File)
    try {
      if (Platform.isAndroid) {
        if (await requestStoragePermission()) {
          final directory = Directory('/storage/emulated/0/Documents/VowNote');
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(data);
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('Manual export to storage failed, falling back: $e');
    }

    // 2. Fallback to Temporary & Share
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final tempFileName = 'VowNote_Export_$dateStr.json';
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$tempFileName');
    await file.writeAsString(data);
    await Share.shareXFiles([XFile(file.path)], text: 'VowNote Backup');
    return file.path;
  }

  // Import: File Picker, parses JSON, inserts to DB
  Future<int> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      try {
        // Use compute to move decoding off the main thread
        final List<Booking> importedBookings = await compute(
          _decodeBookings,
          jsonString,
        );
        if (importedBookings.isEmpty) return 0;

        final db = DatabaseService();
        int count = 0;
        for (var booking in importedBookings) {
          await db.insertBooking(booking);
          count++;
        }
        return count;
      } catch (e) {
        throw Exception("Invalid backup file format.");
      }
    }
    return -1; // Canceled
  }
}

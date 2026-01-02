import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';
import 'package:intl/intl.dart';

class BackupService {
  // Export: Shared storage (/Documents/VowNote) or Share Sheet
  Future<String> exportBackup() async {
    final db = DatabaseService();
    final bookings = await db.getBookings();

    if (bookings.isEmpty) {
      throw Exception("No bookings to backup.");
    }

    final data = jsonEncode(bookings.map((e) => e.toMap()).toList());
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'VowNote_Backup_$dateStr.json';

    // 1. Try to save to "Documents/VowNote" (Persistent)
    try {
      if (Platform.isAndroid) {
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }

        // Variable validation logic for storage path
        if (status.isGranted) {
          Directory? directory = Directory(
            '/storage/emulated/0/Documents/VowNote',
          );
          if (!await directory.exists()) {
            directory = await directory.create(recursive: true);
          }
          final file = File('${directory.path}/$fileName');
          await file.writeAsString(data);
          return file.path; // Saved to global storage
        }
      }
    } catch (e) {
      // Fallback if permission denied
    }

    // 2. Fallback to Temporary & Share (Existing logic)
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(data);
    await Share.shareXFiles([XFile(file.path)], text: 'VowNote Backup');
    return file.path;
  }

  // Import: Organs File Picker, parses JSON, inserts to DB
  Future<int> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        if (jsonList.isEmpty) return 0;

        final db = DatabaseService();
        int count = 0;
        for (var map in jsonList) {
          // Validate structure loosely
          if (map['id'] != null && map['brideName'] != null) {
            await db.insertBooking(Booking.fromMap(map));
            count++;
          }
        }
        return count;
      } catch (e) {
        throw Exception("Invalid backup file format.");
      }
    }
    return -1; // Canceled
  }
}

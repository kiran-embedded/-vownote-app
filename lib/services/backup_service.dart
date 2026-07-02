import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vownote/services/database_service.dart';
import 'package:vownote/services/google_drive_service.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  static const String _primaryFolder = 'BizLedger';
  static const String _documentsFolder = 'BizLedger';
  static const String _masterFileName = 'BizLedger_master_backup.db';

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

  Future<File> _getDbFile() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'BizLedger.db');
    return File(path);
  }

  Future<Map<String, bool>> tripleBackup({int retryCount = 0}) async {
    try {
      final dbFile = await _getDbFile();
      if (!await dbFile.exists()) {
        debugPrint('⚠️ No database file to backup, skipping...');
        return {'external': true, 'documents': true, 'appStorage': true};
      }

      debugPrint('🔒 Starting triple backup (DB size: ${await dbFile.length()} bytes)...');

      // Checkpoint the database to flush WAL changes to the main .db file
      final db = await DatabaseService().database;
      await db.rawQuery('PRAGMA wal_checkpoint(FULL);');

      final results = await Future.wait([
        _backupToExternal(dbFile),
        _backupToDocuments(dbFile),
        _backupToAppStorage(dbFile),
      ]);

      final resultMap = {
        'external': results[0],
        'documents': results[1],
        'appStorage': results[2],
      };

      final successCount = resultMap.values.where((v) => v).length;

      if (successCount > 0) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
        } catch (_) {}
      }

      if (successCount == 0 && retryCount < 1) {
        await Future.delayed(const Duration(seconds: 1));
        return tripleBackup(retryCount: retryCount + 1);
      }
      return resultMap;
    } catch (e) {
      debugPrint('❌ Triple backup critical error: $e');
      return {'external': false, 'documents': false, 'appStorage': false};
    }
  }

  Future<bool> _backupToExternal(File dbFile) async {
    try {
      if (!Platform.isAndroid) return false;
      if (await requestStoragePermission()) {
        final directory = Directory('/storage/emulated/0/$_primaryFolder/Backups');
        if (!await directory.exists()) await directory.create(recursive: true);

        final masterFile = File('${directory.path}/$_masterFileName');
        await dbFile.copy(masterFile.path);
        return true;
      }
    } catch (e) {
      debugPrint('❌ Lock 1 failed: $e');
    }
    return false;
  }

  Future<bool> _backupToDocuments(File dbFile) async {
    try {
      if (!Platform.isAndroid) return false;
      if (await requestStoragePermission()) {
        final directory = Directory('/storage/emulated/0/Documents/$_documentsFolder');
        if (!await directory.exists()) await directory.create(recursive: true);

        final masterFile = File('${directory.path}/$_masterFileName');
        await dbFile.copy(masterFile.path);
        return true;
      }
    } catch (e) {
      debugPrint('❌ Lock 2 failed: $e');
    }
    return false;
  }

  Future<bool> _backupToAppStorage(File dbFile) async {
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) directory = Directory('${directory.path}/Backups');
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        if (!await directory.exists()) await directory.create(recursive: true);
        final masterFile = File('${directory.path}/$_masterFileName');
        await dbFile.copy(masterFile.path);
        return true;
      }
    } catch (e) {
      debugPrint('❌ Lock 3 failed: $e');
    }
    return false;
  }

  Future<bool> verifyBackup(File file) async {
    Database? testDb;
    try {
      if (!await file.exists()) return false;
      final key = await DatabaseService().getEncryptionKey();

      testDb = await openDatabase(file.path, password: key, readOnly: true);
      final count = Sqflite.firstIntValue(await testDb.rawQuery('SELECT COUNT(*) FROM bookings'));
      
      debugPrint('✅ Backup verified: $count bookings');
      return true;
    } catch (e) {
      debugPrint('❌ Backup verification failed: $e');
      return false;
    } finally {
      try { await testDb?.close(); } catch (_) {}
    }
  }

  Future<void> silentBackup() async {
    try {
      await tripleBackup();
      final drive = GoogleDriveService();
      if (drive.isSignedIn) {
        debugPrint('☁️ Starting background silent cloud backup to Google Drive...');
        await drive.backupToDrive();
      }
    } catch (e) {
      debugPrint('⚠️ Silent backup error: $e');
    }
  }

  Future<String> exportBackup() async {
    final dbFile = await _getDbFile();
    if (!await dbFile.exists()) throw Exception("No database to backup.");

    // Checkpoint the database to flush WAL changes to the main .db file
    final db = await DatabaseService().database;
    await db.rawQuery('PRAGMA wal_checkpoint(FULL);');

    const fileName = 'BizLedger_master_backup.db';

    try {
      if (Platform.isAndroid && await requestStoragePermission()) {
        final directory = Directory('/storage/emulated/0/Documents/BizLedger');
        if (!await directory.exists()) await directory.create(recursive: true);
        final file = File('${directory.path}/$fileName');
        await dbFile.copy(file.path);
        if (await verifyBackup(file)) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
          } catch (_) {}
          return file.path;
        }
      }
    } catch (e) {
      debugPrint('Manual export failed, falling back: $e');
    }

    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final tempFileName = 'BizLedger_Export_$dateStr.db';
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$tempFileName');
    await dbFile.copy(file.path);
    await Share.shareXFiles([XFile(file.path)], text: 'BizLedger Backup');
    return file.path;
  }

  Future<int> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['db', 'json'], // allow json for legacy migrations if needed, but primarily db
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      
      if (file.path.endsWith('.json')) {
        throw Exception("Legacy JSON backups cannot be imported directly in this optimized version.");
      }

      if (!await verifyBackup(file)) {
        throw Exception("Backup file is corrupted, invalid, or encrypted with a different key.");
      }

      final dbFile = await _getDbFile();
      // Replace active DB
      
      // Close active DB first (DatabaseService handles reopening and resets reference)
      await DatabaseService().closeDatabase();
      
      // Copy over
      await file.copy(dbFile.path);
      
      return 1; // Success indicator
    }
    return -1;
  }

  /// Checks for any existing local or cloud backups and auto-restores them on app startup if the database is empty
  Future<bool> checkForAutoRestore() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = p.join(dbPath, 'BizLedger.db');
      
      // If database already exists and contains data, don't auto-restore
      if (await databaseExists(path)) {
        try {
          final db = await DatabaseService().database;
          final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM bookings'));
          if (count != null && count > 0) {
            debugPrint('📊 Database already contains $count bookings. Skipping auto-restore.');
            return false;
          }
        } catch (e) {
          debugPrint('Error testing active DB for auto-restore: $e');
        }
      }

      // Check 1: Local Backup Auto Restore
      final localBackup = File('/storage/emulated/0/Documents/BizLedger/BizLedger_master_backup.db');
      if (await localBackup.exists()) {
        final isValid = await verifyBackup(localBackup);
        if (isValid) {
          debugPrint('📥 Auto-restoring from local backup file...');
          await DatabaseService().closeDatabase();
          await localBackup.copy(path);
          return true;
        }
      }

      // Check 2: Google Drive Auto Restore
      final drive = GoogleDriveService();
      if (!drive.isSignedIn) {
        await drive.init(); // Silent sign-in
      }
      if (drive.isSignedIn) {
        debugPrint('📥 Auto-restoring from Google Drive cloud backup...');
        final restored = await drive.restoreFromDrive();
        return restored;
      }
    } catch (e) {
      debugPrint('⚠️ Auto restore check failed: $e');
    }
    return false;
  }
}

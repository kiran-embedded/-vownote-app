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
import 'package:crypto/crypto.dart';

/// Triple-Lock Backup Service
///
/// Provides three independent backup locations:
/// 1. External Storage (/storage/emulated/0/VowNote/) - Survives app uninstall
/// 2. Documents Folder (/storage/emulated/0/Documents/VowNote/) - User accessible
/// 3. App External Storage (Android/data/.../files/) - Fast automatic backups
class BackupService {
  // Backup folder names
  static const String _primaryFolder = 'VowNote';
  static const String _documentsFolder = 'VowNote';
  static const String _masterFileName = 'vownote_master_backup.json';
  static const int _maxIncrementalBackups = 10;

  // Helper for background JSON encoding
  static String _encodeBookings(List<Booking> bookings) {
    return jsonEncode(bookings.map((e) => e.toMap()).toList());
  }

  // Helper for background JSON decoding
  static List<Booking> _decodeBookings(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((map) => Booking.fromMap(map)).toList();
  }

  // Generate checksum for verification
  String _generateChecksum(String data) {
    return md5.convert(utf8.encode(data)).toString();
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

  /// Triple-Lock Backup System
  /// Saves to all 3 locations simultaneously for maximum data safety
  /// Returns a map indicating success/failure for each backup location
  Future<Map<String, bool>> tripleBackup({int retryCount = 0}) async {
    try {
      final db = DatabaseService();
      final bookings = await db.getBookings();

      // Skip backup if no data to backup
      if (bookings.isEmpty) {
        debugPrint('⚠️ No bookings to backup, skipping...');
        return {'external': true, 'documents': true, 'appStorage': true};
      }

      // Use compute to move encoding off the main thread
      final data = await compute(_encodeBookings, bookings);
      final checksum = _generateChecksum(data);

      debugPrint(
        '🔒 Starting triple backup (${bookings.length} bookings, ${data.length} bytes)...',
      );

      // Execute all three backups in parallel
      final results = await Future.wait([
        _backupToExternal(data, checksum),
        _backupToDocuments(data, checksum),
        _backupToAppStorage(data, checksum),
      ]);

      final resultMap = {
        'external': results[0],
        'documents': results[1],
        'appStorage': results[2],
      };

      final successCount = resultMap.values.where((v) => v).length;

      // If no backups succeeded and we haven't retried yet, try once more
      if (successCount == 0 && retryCount < 1) {
        debugPrint('⚠️ All backups failed, retrying once...');
        await Future.delayed(const Duration(seconds: 1));
        return tripleBackup(retryCount: retryCount + 1);
      }

      // Log results
      if (successCount == 3) {
        debugPrint('✅ Triple backup complete: All 3 locks successful!');
      } else if (successCount >= 1) {
        debugPrint('⚠️ Partial backup: $successCount/3 locks successful');
        resultMap.forEach((key, value) {
          if (!value) debugPrint('  ❌ $key backup failed');
        });
      } else {
        debugPrint('❌ Triple backup failed: 0/3 locks successful');
      }

      return resultMap;
    } catch (e, stackTrace) {
      debugPrint('❌ Triple backup critical error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {'external': false, 'documents': false, 'appStorage': false};
    }
  }

  /// Lock 1: External Storage (Survives uninstall)
  Future<bool> _backupToExternal(String data, String checksum) async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('ℹ️ Lock 1: Skipped (not Android)');
        return false;
      }

      if (await requestStoragePermission()) {
        final directory = Directory(
          '/storage/emulated/0/$_primaryFolder/Backups',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          debugPrint('📁 Created directory: ${directory.path}');
        }

        // Save master backup
        final masterFile = File('${directory.path}/$_masterFileName');
        await masterFile.writeAsString(data);

        // Verify the write
        if (!await masterFile.exists() || (await masterFile.length()) == 0) {
          throw Exception('Backup file write verification failed');
        }

        // Save metadata
        await _saveMetadata(directory, data.length, checksum);

        // Create incremental backup
        await _createIncrementalBackup(directory, data);

        debugPrint('✅ Lock 1 (External): ${masterFile.path}');
        return true;
      } else {
        debugPrint('⚠️ Lock 1: Permission denied');
      }
    } catch (e) {
      debugPrint('❌ Lock 1 failed: $e');
    }
    return false;
  }

  /// Lock 2: Documents Folder (User accessible)
  Future<bool> _backupToDocuments(String data, String checksum) async {
    try {
      if (!Platform.isAndroid) {
        debugPrint('ℹ️ Lock 2: Skipped (not Android)');
        return false;
      }

      if (await requestStoragePermission()) {
        final directory = Directory(
          '/storage/emulated/0/Documents/$_documentsFolder',
        );
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          debugPrint('📁 Created directory: ${directory.path}');
        }

        // Save master backup
        final masterFile = File('${directory.path}/$_masterFileName');
        await masterFile.writeAsString(data);

        // Verify the write
        if (!await masterFile.exists() || (await masterFile.length()) == 0) {
          throw Exception('Backup file write verification failed');
        }

        // Save metadata
        await _saveMetadata(directory, data.length, checksum);

        // Create incremental backup
        await _createIncrementalBackup(directory, data);

        debugPrint('✅ Lock 2 (Documents): ${masterFile.path}');
        return true;
      } else {
        debugPrint('⚠️ Lock 2: Permission denied');
      }
    } catch (e) {
      debugPrint('❌ Lock 2 failed: $e');
    }
    return false;
  }

  /// Lock 3: App External Storage (Fast automatic)
  Future<bool> _backupToAppStorage(String data, String checksum) async {
    try {
      Directory? directory;

      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          directory = Directory('${directory.path}/Backups');
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        if (!await directory.exists()) {
          await directory.create(recursive: true);
          debugPrint('📁 Created directory: ${directory.path}');
        }

        // Save master backup
        final masterFile = File('${directory.path}/$_masterFileName');
        await masterFile.writeAsString(data);

        // Verify the write
        if (!await masterFile.exists() || (await masterFile.length()) == 0) {
          throw Exception('Backup file write verification failed');
        }

        // Save metadata
        await _saveMetadata(directory, data.length, checksum);

        // Create incremental backup
        await _createIncrementalBackup(directory, data);

        debugPrint('✅ Lock 3 (App Storage): ${masterFile.path}');
        return true;
      } else {
        debugPrint('⚠️ Lock 3: Could not get storage directory');
      }
    } catch (e) {
      debugPrint('❌ Lock 3 failed: $e');
    }
    return false;
  }

  /// Save backup metadata for verification
  Future<void> _saveMetadata(
    Directory directory,
    int fileSize,
    String checksum,
  ) async {
    try {
      final metadata = {
        'lastBackup': DateTime.now().toIso8601String(),
        'fileSize': fileSize,
        'checksum': checksum,
        'version': '1.0',
      };

      final metaFile = File('${directory.path}/backup_metadata.json');
      await metaFile.writeAsString(jsonEncode(metadata));
    } catch (e) {
      debugPrint('Metadata save failed: $e');
    }
  }

  /// Create timestamped incremental backup and maintain last N backups
  Future<void> _createIncrementalBackup(
    Directory directory,
    String data,
  ) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final incrementalFile = File('${directory.path}/backup_$timestamp.json');
      await incrementalFile.writeAsString(data);

      // Cleanup old incremental backups, keep last N
      await _cleanupOldBackups(directory);
    } catch (e) {
      debugPrint('Incremental backup failed: $e');
    }
  }

  /// Remove old incremental backups, keeping only the last N
  Future<void> _cleanupOldBackups(Directory directory) async {
    try {
      final files = directory
          .listSync()
          .whereType<File>()
          .where(
            (f) =>
                f.path.contains('backup_') &&
                !f.path.contains(_masterFileName) &&
                !f.path.contains('metadata'),
          )
          .toList();

      if (files.length > _maxIncrementalBackups) {
        // Sort by modification time (oldest first)
        files.sort(
          (a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()),
        );

        // Delete oldest files
        final toDelete = files.length - _maxIncrementalBackups;
        for (var i = 0; i < toDelete; i++) {
          await files[i].delete();
          debugPrint('Deleted old backup: ${files[i].path}');
        }
      }
    } catch (e) {
      debugPrint('Cleanup failed: $e');
    }
  }

  /// Verify backup file integrity
  Future<bool> verifyBackup(File file) async {
    try {
      if (!await file.exists()) return false;

      final content = await file.readAsString();

      // Try to decode JSON
      final decoded = jsonDecode(content);
      if (decoded is! List) return false;

      // Try to parse as bookings
      final bookings = await compute(_decodeBookings, content);

      debugPrint('✅ Backup verified: ${bookings.length} bookings');
      return true;
    } catch (e) {
      debugPrint('❌ Backup verification failed: $e');
      return false;
    }
  }

  /// Silent Backup - Automatically called on data changes
  /// Uses triple-lock system with automatic error recovery
  Future<void> silentBackup() async {
    try {
      final results = await tripleBackup();
      final successCount = results.values.where((v) => v).length;

      // If at least one backup succeeded, we're good
      if (successCount >= 1) {
        debugPrint('🔒 Silent backup completed: $successCount/3 locks');
      } else {
        debugPrint('⚠️ Silent backup warning: All locks failed');
      }
    } catch (e) {
      // Silent backups should never throw, just log
      debugPrint('⚠️ Silent backup error (non-critical): $e');
    }
  }

  /// Export: Shared storage with fallback to share sheet
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

          // Verify the export
          if (await verifyBackup(file)) {
            return file.path;
          }
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

  /// Import: File Picker with verification
  Future<int> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);

      // Verify backup before importing
      if (!await verifyBackup(file)) {
        throw Exception("Backup file is corrupted or invalid.");
      }

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

        // Trigger triple backup after successful import
        await tripleBackup();

        return count;
      } catch (e) {
        throw Exception("Invalid backup file format: $e");
      }
    }
    return -1; // Canceled
  }

  /// Find and restore from the best available backup
  Future<File?> findBestBackup() async {
    final locations = <Directory>[];

    // Check all three backup locations
    try {
      if (Platform.isAndroid && await requestStoragePermission()) {
        locations.add(Directory('/storage/emulated/0/$_primaryFolder/Backups'));
        locations.add(
          Directory('/storage/emulated/0/Documents/$_documentsFolder'),
        );
      }

      final appDir = await getExternalStorageDirectory();
      if (appDir != null) {
        locations.add(Directory('${appDir.path}/Backups'));
      }
    } catch (e) {
      debugPrint('Error checking backup locations: $e');
    }

    // Find the most recent valid backup
    File? bestBackup;
    DateTime? latestTime;

    for (final dir in locations) {
      if (!await dir.exists()) continue;

      final masterFile = File('${dir.path}/$_masterFileName');
      if (await masterFile.exists() && await verifyBackup(masterFile)) {
        final modTime = await masterFile.lastModified();
        if (latestTime == null || modTime.isAfter(latestTime)) {
          latestTime = modTime;
          bestBackup = masterFile;
        }
      }
    }

    return bestBackup;
  }

  /// Get backup status across all locations
  Future<Map<String, dynamic>> getBackupStatus() async {
    final status = <String, dynamic>{};

    try {
      // Check Lock 1 (External)
      final external = Directory('/storage/emulated/0/$_primaryFolder/Backups');
      status['external'] = await _checkBackupLocation(external);

      // Check Lock 2 (Documents)
      final documents = Directory(
        '/storage/emulated/0/Documents/$_documentsFolder',
      );
      status['documents'] = await _checkBackupLocation(documents);

      // Check Lock 3 (App Storage)
      final appDir = await getExternalStorageDirectory();
      if (appDir != null) {
        final appBackups = Directory('${appDir.path}/Backups');
        status['appStorage'] = await _checkBackupLocation(appBackups);
      }
    } catch (e) {
      debugPrint('Error checking backup status: $e');
    }

    return status;
  }

  Future<Map<String, dynamic>> _checkBackupLocation(Directory dir) async {
    if (!await dir.exists()) {
      return {'exists': false};
    }

    final masterFile = File('${dir.path}/$_masterFileName');
    if (!await masterFile.exists()) {
      return {'exists': true, 'hasBackup': false};
    }

    final stat = await masterFile.stat();
    final isValid = await verifyBackup(masterFile);

    return {
      'exists': true,
      'hasBackup': true,
      'valid': isValid,
      'size': stat.size,
      'lastModified': stat.modified.toIso8601String(),
      'path': masterFile.path,
    };
  }
}

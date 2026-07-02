import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vownote/services/backup_service.dart';
import 'package:vownote/services/database_service.dart';

class GoogleDriveService extends ChangeNotifier {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '822410515694-6k0gc1imvrksd6dre472f2ons9a6fsj9.apps.googleusercontent.com',
    scopes: [
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );

  GoogleSignInAccount? _currentUser;
  bool _isLoading = false;
  bool _isBackingUp = false;
  bool _isRestoring = false;

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isLoading => _isLoading || _isBackingUp || _isRestoring;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  bool get isSignedIn => _currentUser != null;

  Future<void> init() async {
    _currentUser = _googleSignIn.currentUser;
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      notifyListeners();
    });
    try {
      await _googleSignIn.signInSilently().timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint('Google Silent Sign-In timed out after 2 seconds.');
          return null;
        },
      );
    } catch (e) {
      debugPrint('Google Silent Sign-In failed: $e');
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
    } catch (e) {
      debugPrint('Google Sign-Out failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File> _getDbFile() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'BizLedger.db');
    return File(path);
  }

  Future<String?> _getAccessToken() async {
    final auth = await _currentUser?.authentication;
    return auth?.accessToken;
  }

  /// Searches for existing backup file on Google Drive AppData folder.
  /// Returns the fileId if found, null otherwise.
  Future<String?> _findBackupFile(String accessToken) async {
    final query = "name = 'BizLedger_master_backup.db' and parents in 'appDataFolder'";
    final uri = Uri.parse(
      'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(query)}&spaces=appDataFolder',
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final files = data['files'] as List;
      if (files.isNotEmpty) {
        return files.first['id'] as String;
      }
    } else {
      debugPrint('❌ Search failed: ${response.statusCode} - ${response.body}');
    }
    return null;
  }

  /// Uploads backup to Google Drive AppData
  Future<bool> backupToDrive() async {
    if (!isSignedIn) return false;

    _isBackingUp = true;
    notifyListeners();

    try {
      final dbFile = await _getDbFile();
      if (!await dbFile.exists()) {
        debugPrint('❌ DB file does not exist.');
        return false;
      }

      // Checkpoint the database to flush WAL changes to the main .db file
      final db = await DatabaseService().database;
      await db.rawQuery('PRAGMA wal_checkpoint(FULL);');

      final token = await _getAccessToken();
      if (token == null) return false;

      final existingFileId = await _findBackupFile(token);

      if (existingFileId != null) {
        // OVERWRITE (PATCH)
        debugPrint('🔄 Overwriting Google Drive backup $existingFileId...');
        final bytes = await dbFile.readAsBytes();
        final uri = Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files/$existingFileId?uploadType=media',
        );

        final response = await http.patch(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/octet-stream',
          },
          body: bytes,
        );

        if (response.statusCode == 200) {
          debugPrint('✅ Google Drive backup overwritten successfully.');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
          return true;
        } else {
          debugPrint('❌ Overwrite failed: ${response.statusCode} - ${response.body}');
        }
      } else {
        // CREATE (POST)
        debugPrint('📤 Creating new Google Drive backup...');
        final uri = Uri.parse(
          'https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart',
        );

        final bytes = await dbFile.readAsBytes();
        final boundary = '----vownote_boundary_${DateTime.now().millisecondsSinceEpoch}';

        final metadata = jsonEncode({
          'name': 'BizLedger_master_backup.db',
          'parents': ['appDataFolder']
        });

        // Construct raw multipart request body manually to keep it fast/low-memory
        final buffer = BytesBuilder();
        buffer.add(utf8.encode('--$boundary\r\n'));
        buffer.add(utf8.encode('Content-Type: application/json; charset=UTF-8\r\n\r\n'));
        buffer.add(utf8.encode('$metadata\r\n'));
        buffer.add(utf8.encode('--$boundary\r\n'));
        buffer.add(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
        buffer.add(bytes);
        buffer.add(utf8.encode('\r\n--$boundary--\r\n'));

        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/related; boundary=$boundary',
          },
          body: buffer.takeBytes(),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('✅ Google Drive backup created successfully.');
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_backup_time', DateTime.now().toIso8601String());
          return true;
        } else {
          debugPrint('❌ Creation failed: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('❌ Google Drive backup exception: $e');
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
    return false;
  }

  /// Downloads and restores backup from Google Drive AppData
  Future<bool> restoreFromDrive() async {
    if (!isSignedIn) return false;

    _isRestoring = true;
    notifyListeners();

    try {
      final token = await _getAccessToken();
      if (token == null) return false;

      final fileId = await _findBackupFile(token);
      if (fileId == null) {
        debugPrint('❌ No backup file found on Google Drive.');
        return false;
      }

      debugPrint('📥 Downloading Google Drive backup $fileId...');
      final uri = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final tempFile = File(p.join(tempDir.path, 'BizLedger_Restore_Temp.db'));
        await tempFile.writeAsBytes(response.bodyBytes);

        // Verify the database backup using the cryptographic keys
        final backupService = BackupService();
        final isValid = await backupService.verifyBackup(tempFile);

        if (!isValid) {
          debugPrint('❌ Dowloaded DB backup is invalid or corrupted.');
          return false;
        }

        // Close the current DB and overwrite it
        final dbFile = await _getDbFile();
        await DatabaseService().closeDatabase();

        await tempFile.copy(dbFile.path);
        debugPrint('✅ Google Drive backup successfully restored!');
        return true;
      } else {
        debugPrint('❌ Download failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Google Drive restore exception: $e');
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
    return false;
  }
}

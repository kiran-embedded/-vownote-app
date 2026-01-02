import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:http/http.dart' as http;
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/database_service.dart';

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  // Manual Stream Controller to handle Auth State safely
  final _userController = StreamController<GoogleSignInAccount?>.broadcast();
  Stream<GoogleSignInAccount?> get userStream => _userController.stream;

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;

  // Getter for current user
  GoogleSignInAccount? get currentUser => _currentUser;

  GoogleDriveService() {
    _init();
  }

  void _init() {
    _googleSignIn
        .signInSilently()
        .then((account) {
          _handleSignIn(account);
        })
        .catchError((e) {
          print('Silent sign-in failed: $e');
        });
  }

  Future<void> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      await _handleSignIn(account);
    } catch (e) {
      print('Sign in failed: $e');
      rethrow;
    }
  }

  Future<void> _handleSignIn(GoogleSignInAccount? account) async {
    _currentUser = account;
    _userController.add(account);

    if (account != null) {
      try {
        final httpClient = await _googleSignIn.authenticatedClient();
        if (httpClient != null) {
          _driveApi = drive.DriveApi(httpClient);
        }
      } catch (e) {
        print('Failed to get authenticated client: $e');
      }
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _currentUser = null;
    _driveApi = null;
    _userController.add(null);
  }

  // Find or create 'VowNote' folder
  Future<String?> _getFolderId() async {
    if (_driveApi == null) return null;

    try {
      final query =
          "mimeType = 'application/vnd.google-apps.folder' and name = 'VowNote' and trashed = false";
      final fileList = await _driveApi!.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      } else {
        // Create folder
        final folder = drive.File()
          ..name = 'VowNote'
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await _driveApi!.files.create(folder);
        return createdFolder.id;
      }
    } catch (e) {
      print('Error getting/creating folder: $e');
      return null;
    }
  }

  Future<void> uploadBackup() async {
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Not signed in');

    final folderId = await _getFolderId();
    if (folderId == null) throw Exception('Could not create folder');

    // Get all data
    final db = DatabaseService();
    final bookings = await db.getBookings();
    final data = jsonEncode(bookings.map((e) => e.toMap()).toList());

    // Create file content
    final media = drive.Media(
      Future.value(utf8.encode(data)).asStream(),
      utf8.encode(data).length,
    );

    final fileToUpload = drive.File()
      ..name = 'vownote_backup.json'
      ..parents = [folderId];

    // Check if exists to overwrite
    final query =
        "name = 'vownote_backup.json' and '$folderId' in parents and trashed = false";
    final existing = await _driveApi!.files.list(q: query);

    if (existing.files != null && existing.files!.isNotEmpty) {
      await _driveApi!.files.update(
        fileToUpload,
        existing.files!.first.id!,
        uploadMedia: media,
      );
    } else {
      await _driveApi!.files.create(fileToUpload, uploadMedia: media);
    }
  }

  // Restore: Returns true if successful
  Future<bool> restoreBackup() async {
    if (_driveApi == null) await signIn();
    if (_driveApi == null) throw Exception('Not signed in');

    final folderId = await _getFolderId();
    if (folderId == null) throw Exception('Could not find folder');

    final query =
        "name = 'vownote_backup.json' and '$folderId' in parents and trashed = false";
    final existing = await _driveApi!.files.list(q: query);

    if (existing.files != null && existing.files!.isNotEmpty) {
      final fileId = existing.files!.first.id!;
      final media =
          await _driveApi!.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> dataStore = [];
      await media.stream.forEach((element) {
        dataStore.addAll(element);
      });

      final jsonString = utf8.decode(dataStore);
      final List<dynamic> jsonList = jsonDecode(jsonString);

      final db = DatabaseService();
      // Simple strategy: Clear and Insert (Risk: Local changes lost if not synced. User requested "all data saved in gdrive and local strorage")
      // For now, we will merge or upsert.
      for (var map in jsonList) {
        await db.insertBooking(Booking.fromMap(map));
      }
      return true;
    }
    return false;
  }

  Future<void> uploadPdf(File pdfFile, String fileName) async {
    if (_driveApi == null) await signIn();
    if (_driveApi == null) return;

    final folderId = await _getFolderId();
    if (folderId == null) return;

    final media = drive.Media(pdfFile.openRead(), pdfFile.lengthSync());
    final fileToUpload = drive.File()
      ..name = fileName
      ..parents = [folderId];

    await _driveApi!.files.create(fileToUpload, uploadMedia: media);
  }
}

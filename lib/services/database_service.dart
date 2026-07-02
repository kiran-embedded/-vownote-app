import 'dart:io';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/backup_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final _secureStorage = const FlutterSecureStorage();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = null; // Clear stale reference
    _database = await _initDatabase();
    return _database!;
  }
  Future<void> closeDatabase() async {
    if (_database != null) {
      try {
        await _database!.close();
      } catch (e) {
        debugPrint('Error closing database: $e');
      }
      _database = null;
    }
  }
  Future<String> getEncryptionKey() async {
    return 'BizLedger_Secure_Key_583a1d9b4c7e2f0a';
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'BizLedger.db');
    final oldPath = join(dbPath, 'vownote.db');

    // Migration from old app name to new app name
    if (await databaseExists(oldPath) && !await databaseExists(path)) {
      debugPrint('Migrating from vownote.db to BizLedger.db...');
      final oldFile = File(oldPath);
      await oldFile.rename(path);
    }

    final dbKey = await getEncryptionKey();

    // If DB exists, verify it can be opened. If not, attempt migration or delete.
    if (await databaseExists(path)) {
      try {
        // Quick validation: try opening and immediately closing
        // Use a temp path check instead of opening the same file to avoid
        // sqflite_sqlcipher connection caching issues (database_closed error)
        final dbFile = File(path);
        final bytes = await dbFile.readAsBytes();
        if (bytes.isEmpty) {
          debugPrint('Database file is empty, deleting...');
          await deleteDatabase(path);
        }
      } catch (e) {
        debugPrint('Database validation failed: $e. Attempting migration...');
        try {
          await _encryptExistingDatabase(path, dbKey);
        } catch (e2) {
          debugPrint('Migration failed. Database is unrecoverable. Deleting...');
          await deleteDatabase(path);
        }
      }
    }

    return await openDatabase(
      path,
      password: dbKey,
      version: 8, // Bumped for isClosed column
      onConfigure: (db) async {
        // High performance optimizations
        // Must use rawQuery because these PRAGMAs return a result row, and execute() would crash.
        await db.rawQuery('PRAGMA journal_mode = WAL;');
        await db.rawQuery('PRAGMA synchronous = NORMAL;');
        await db.rawQuery('PRAGMA cache_size = -20000;'); // 20MB cache
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bookings(
            id TEXT PRIMARY KEY,
            customerName TEXT,
            brideName TEXT,
            groomName TEXT,
            eventDates TEXT,
            totalAmount REAL,
            totalAdvance REAL,
            advanceReceived REAL,
            receivedAmount REAL,
            address TEXT,
            phoneNumber TEXT,
            alternatePhone TEXT,
            notes TEXT,
            bookingCategory TEXT,
            diaryCode TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            businessType TEXT,
            payments TEXT,
            taxRate REAL,
            discountAmount REAL,
            discountPercentage REAL,
            isClosed INTEGER DEFAULT 0
          )
        ''');
        await db.execute('CREATE INDEX idx_bookings_businessType ON bookings (businessType)');
        await db.execute('CREATE INDEX idx_bookings_createdAt ON bookings (createdAt)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await db.execute('ALTER TABLE bookings ADD COLUMN receivedAmount REAL');
        if (oldVersion < 3) await db.execute('ALTER TABLE bookings ADD COLUMN notes TEXT');
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE bookings ADD COLUMN customerName TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN totalAdvance REAL');
          await db.execute('ALTER TABLE bookings ADD COLUMN advanceReceived REAL');
          await db.execute('ALTER TABLE bookings ADD COLUMN alternatePhone TEXT');
          await db.execute('UPDATE bookings SET customerName = brideName WHERE customerName IS NULL');
        }
        if (oldVersion < 5) {
          await db.execute('ALTER TABLE bookings ADD COLUMN bookingCategory TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN diaryCode TEXT');
          await db.execute("UPDATE bookings SET bookingCategory = 'None' WHERE bookingCategory IS NULL");
          await db.execute("UPDATE bookings SET diaryCode = '' WHERE diaryCode IS NULL");
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE bookings ADD COLUMN businessType TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN payments TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN taxRate REAL');
          await db.execute('ALTER TABLE bookings ADD COLUMN discountAmount REAL');
          await db.execute('ALTER TABLE bookings ADD COLUMN discountPercentage REAL');
          
          await db.execute("UPDATE bookings SET businessType = 'wedding' WHERE businessType IS NULL");
          await db.execute("UPDATE bookings SET payments = '[]' WHERE payments IS NULL");
          await db.execute('UPDATE bookings SET taxRate = 0 WHERE taxRate IS NULL');
          await db.execute('UPDATE bookings SET discountAmount = 0 WHERE discountAmount IS NULL');
          await db.execute('UPDATE bookings SET discountPercentage = 0 WHERE discountPercentage IS NULL');
        }
        if (oldVersion < 7) {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_bookings_businessType ON bookings (businessType)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_bookings_createdAt ON bookings (createdAt)');
        }
        if (oldVersion < 8) {
          await db.execute('ALTER TABLE bookings ADD COLUMN isClosed INTEGER DEFAULT 0');
        }
      },
    );
  }

  Future<void> _encryptExistingDatabase(String path, String key) async {
    final tempPath = path + '_encrypted.db';
    
    // Clean up any failed previous migration
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
    
    // Open the plaintext DB without password. In sqflite_sqlcipher, empty string password acts as unencrypted.
    final plaintextDb = await openDatabase(path, password: '');
    
    // Attach the new encrypted DB and use sqlcipher_export to migrate
    await plaintextDb.execute("ATTACH DATABASE '$tempPath' AS encrypted KEY '$key'");
    await plaintextDb.execute("SELECT sqlcipher_export('encrypted')");
    await plaintextDb.execute("DETACH DATABASE encrypted");
    await plaintextDb.close();
    
    // Replace the plaintext database with the encrypted one
    final oldFile = File(path);
    await oldFile.delete();
    final newFile = File(tempPath);
    await newFile.rename(path);
  }

  Future<void> insertBooking(Booking booking) async {
    final db = await database;
    await db.insert(
      'bookings',
      booking.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    BackupService().silentBackup();
  }

  Future<void> updateBooking(Booking booking) async {
    final db = await database;
    await db.update(
      'bookings',
      booking.toMap(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
    BackupService().silentBackup();
  }

  Future<List<Booking>> getBookings({String? businessType}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      orderBy: 'createdAt DESC',
      where: businessType != null ? 'businessType = ?' : null,
      whereArgs: businessType != null ? [businessType] : null,
    );
    return List.generate(maps.length, (i) {
      return Booking.fromMap(maps[i]);
    });
  }

  Future<void> deleteBooking(String id) async {
    final db = await database;
    await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
    BackupService().silentBackup();
  }

  Future<List<Booking>> getBookingsForMonth(int month, int year) async {
    final allBookings = await getBookings();
    return allBookings.where((booking) {
      return booking.eventDates.any(
        (date) => date.month == month && date.year == year,
      );
    }).toList();
  }
}

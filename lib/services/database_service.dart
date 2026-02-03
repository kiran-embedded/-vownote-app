import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:vownote/models/booking.dart';
import 'package:vownote/services/backup_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vownote.db');

    return await openDatabase(
      path,
      version: 6, // Bumped to 6 for new business fields
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
            discountPercentage REAL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE bookings ADD COLUMN receivedAmount REAL',
          );
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE bookings ADD COLUMN notes TEXT');
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE bookings ADD COLUMN customerName TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN totalAdvance REAL');
          await db.execute(
            'ALTER TABLE bookings ADD COLUMN advanceReceived REAL',
          );
          await db.execute(
            'ALTER TABLE bookings ADD COLUMN alternatePhone TEXT',
          );
          await db.execute(
            'UPDATE bookings SET customerName = brideName WHERE customerName IS NULL',
          );
        }
        if (oldVersion < 5) {
          // Migration to Version 5
          await db.execute(
            'ALTER TABLE bookings ADD COLUMN bookingCategory TEXT',
          );
          await db.execute('ALTER TABLE bookings ADD COLUMN diaryCode TEXT');
          await db.execute(
            "UPDATE bookings SET bookingCategory = 'None' WHERE bookingCategory IS NULL",
          );
          await db.execute(
            "UPDATE bookings SET diaryCode = '' WHERE diaryCode IS NULL",
          );
        }
        if (oldVersion < 6) {
          // Migration to Version 6: Add business-related fields
          await db.execute('ALTER TABLE bookings ADD COLUMN businessType TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN payments TEXT');
          await db.execute('ALTER TABLE bookings ADD COLUMN taxRate REAL');
          await db.execute(
            'ALTER TABLE bookings ADD COLUMN discountAmount REAL',
          );
          await db.execute(
            'ALTER TABLE bookings ADD COLUMN discountPercentage REAL',
          );
          // Set defaults for existing records
          await db.execute(
            "UPDATE bookings SET businessType = 'wedding' WHERE businessType IS NULL",
          );
          await db.execute(
            "UPDATE bookings SET payments = '[]' WHERE payments IS NULL",
          );
          await db.execute(
            'UPDATE bookings SET taxRate = 0 WHERE taxRate IS NULL',
          );
          await db.execute(
            'UPDATE bookings SET discountAmount = 0 WHERE discountAmount IS NULL',
          );
          await db.execute(
            'UPDATE bookings SET discountPercentage = 0 WHERE discountPercentage IS NULL',
          );
        }
      },
    );
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

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
      version: 3, // Bump Version to 3
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE bookings(
            id TEXT PRIMARY KEY,
            brideName TEXT,
            groomName TEXT,
            eventDates TEXT,
            totalAmount REAL,
            advanceAmount REAL,
            receivedAmount REAL,
            address TEXT,
            phoneNumber TEXT,
            notes TEXT, -- New Column
            createdAt TEXT,
            updatedAt TEXT
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

  Future<List<Booking>> getBookings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'bookings',
      orderBy: 'createdAt DESC',
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

  // For monthly filtering
  Future<List<Booking>> getBookingsForMonth(int month, int year) async {
    // This is a bit complex with standard SQL because dates are stored as JSON list in 'eventDates'.
    // A simpler approach for the "View" is to fetch all and filter in Dart,
    // OR we could store a 'primaryDate' column for easier querying.
    // Given the scale of a wedding planner (dozens, maybe hundreds, not millions), fetching all and filtering in memory is fine and robust.

    final allBookings = await getBookings();
    return allBookings.where((booking) {
      // Check if ANY of the dates fall in the target month/year
      return booking.eventDates.any(
        (date) => date.month == month && date.year == year,
      );
    }).toList();
  }
}

import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/slot.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static final _dbCompleter = <String, Future<Database>>{};

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Ensure only one initialization happens at a time
    if (_dbCompleter.containsKey('init')) {
      return await _dbCompleter['init']!;
    }

    final completer = Completer<Database>();
    _dbCompleter['init'] = completer.future;

    try {
      _database = await _initDatabase();
      completer.complete(_database!);
      return _database!;
    } catch (e) {
      completer.completeError(e);
      _dbCompleter.remove('init');
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'meta_race.db');
    return await openDatabase(
      path,
      version: 5,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            identifier TEXT UNIQUE,
            password TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE slots (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time_label TEXT,
            track_name TEXT,
            car_model TEXT,
            capacity INTEGER DEFAULT 3,
            booked_count INTEGER DEFAULT 0,
            is_booked INTEGER DEFAULT 0,
            booked_by_id INTEGER,
            FOREIGN KEY (booked_by_id) REFERENCES users (id)
          )
        ''');

        await db.execute('''
          CREATE TABLE booking_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            driver_name TEXT,
            track_name TEXT,
            time_label TEXT,
            race_date TEXT,
            booked_at TEXT
          )
        ''');

        List<Map<String, dynamic>> raceShifts = [
          {'time_label': '09:00 AM - 10:00 AM', 'track_name': 'Monaco GP', 'car_model': 'F1-W14', 'capacity': 3, 'booked_count': 0},
          {'time_label': '10:00 AM - 11:00 AM', 'track_name': 'Silverstone', 'car_model': 'GT3 RS', 'capacity': 3, 'booked_count': 0},
          {'time_label': '11:00 AM - 12:00 PM', 'track_name': 'Nürburgring', 'car_model': 'SF-23', 'capacity': 3, 'booked_count': 0},
          {'time_label': '02:00 PM - 03:00 PM', 'track_name': 'Spa-Francorchamps', 'car_model': '911 RSR', 'capacity': 3, 'booked_count': 0},
        ];

        for (var race in raceShifts) {
          await db.insert('slots', race);
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS booking_history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id INTEGER,
              driver_name TEXT,
              track_name TEXT,
              time_label TEXT,
              race_date TEXT,
              booked_at TEXT
            )
          ''');
        }
      }
    );
  }

  // User methods
  Future<int> registerUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> loginUser(String identifier, String password) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'identifier = ? AND password = ?',
      whereArgs: [identifier, password],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Slot methods
  Future<List<Slot>> getSlots() async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query('slots');
    return List.generate(maps.length, (i) {
      return Slot.fromMap(maps[i]);
    });
  }

  Future<int> updateSlotBooking(int slotId, int newBookedCount, int? userId) async {
    final db = await database;
    return await db.update(
      'slots',
      {'booked_count': newBookedCount, 'is_booked': userId != null ? 1 : 0, 'booked_by_id': userId},
      where: 'id = ?',
      whereArgs: [slotId],
    );
  }

  Future<int> cancelBooking(int slotId, int newBookedCount) async {
    final db = await database;
    return await db.update(
      'slots',
      {'booked_count': newBookedCount, 'is_booked': 0, 'booked_by_id': null},
      where: 'id = ?',
      whereArgs: [slotId],
    );
  }

  // History methods
  Future<int> insertHistory(Map<String, dynamic> history) async {
    final db = await database;
    return await db.insert('booking_history', history);
  }

  Future<List<Map<String, dynamic>>> getHistory(int userId) async {
    final db = await database;
    return await db.query(
      'booking_history',
      where: 'user_id = ?',
      orderBy: 'booked_at DESC',
      whereArgs: [userId],
    );
  }
}

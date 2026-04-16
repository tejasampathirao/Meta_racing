import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/slot.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'meta_race.db');
    return await openDatabase(
      path,
      version: 2, // Upgraded version for schema change
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
            is_booked INTEGER DEFAULT 0,
            booked_by_id INTEGER,
            FOREIGN KEY (booked_by_id) REFERENCES users (id)
          )
        ''');

        List<Map<String, dynamic>> initialRaces = [
          {'time_label': '09:00 AM', 'track_name': 'Monaco GP', 'car_model': 'F1-W14'},
          {'time_label': '11:00 AM', 'track_name': 'Silverstone', 'car_model': 'GT3 RS'},
          {'time_label': '02:00 PM', 'track_name': 'Nürburgring', 'car_model': 'SF-23'},
          {'time_label': '04:00 PM', 'track_name': 'Spa-Francorchamps', 'car_model': '911 RSR'},
        ];

        for (var race in initialRaces) {
          await db.insert('slots', {...race, 'is_booked': 0});
        }
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Simplest way for prototype: drop and recreate
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('''
            CREATE TABLE users (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              username TEXT,
              identifier TEXT UNIQUE,
              password TEXT
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

  Future<int> updateSlotStatus(int slotId, int isBooked, int? userId) async {
    final db = await database;
    return await db.update(
      'slots',
      {'is_booked': isBooked, 'booked_by_id': userId},
      where: 'id = ?',
      whereArgs: [slotId],
    );
  }

  Future<int> cancelBooking(int slotId) async {
    final db = await database;
    return await db.update(
      'slots',
      {'is_booked': 0, 'booked_by_id': null},
      where: 'id = ?',
      whereArgs: [slotId],
    );
  }
}

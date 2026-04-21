import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) {
      // Ensure the role column exists on the cached connection
      await _ensureRoleColumn(_database!);
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> _ensureRoleColumn(Database db) async {
    final cols = await db.rawQuery('PRAGMA table_info(users)');
    final hasRole = cols.any((c) => c['name'] == 'role');
    if (!hasRole) {
      await db.execute("ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'");
    }
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'meta_race.db');
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            phone TEXT DEFAULT '',
            password TEXT,
            role TEXT DEFAULT 'user',
            last_login_time TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 4) {
          // Add role column to existing table
          final cols = await db.rawQuery('PRAGMA table_info(users)');
          final hasRole = cols.any((c) => c['name'] == 'role');
          if (!hasRole) {
            await db.execute(
              "ALTER TABLE users ADD COLUMN role TEXT DEFAULT 'user'",
            );
          }
        }
      },
    );
  }

  Future<int> registerUser(User user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> loginUser(String email, String password) async {
    final db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );

    if (maps.isNotEmpty) {
      // Update last login time
      final now = DateTime.now().toIso8601String();
      await db.update(
        'users',
        {'last_login_time': now},
        where: 'id = ?',
        whereArgs: [maps.first['id']],
      );
      return User.fromMap({...maps.first, 'last_login_time': now});
    }
    return null;
  }
}

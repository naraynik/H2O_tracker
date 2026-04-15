import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

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
    String path = join(await getDatabasesPath(), 'hydra_database.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        name TEXT,
        password TEXT,
        weight INTEGER,
        height INTEGER,
        age INTEGER,
        daily_goal INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE water_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT,
        amount INTEGER,
        timestamp TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE users ADD COLUMN weight INTEGER;');
      await db.execute('ALTER TABLE users ADD COLUMN height INTEGER;');
      await db.execute('ALTER TABLE users ADD COLUMN age INTEGER;');
      await db.execute('ALTER TABLE users ADD COLUMN daily_goal INTEGER;');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE water_logs(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          email TEXT,
          amount INTEGER,
          timestamp TEXT
        )
      ''');
    }
  }

  // Register a new user
  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    return await db.insert(
      'users', 
      user, 
      conflictAlgorithm: ConflictAlgorithm.ignore, // Use ignore to handle duplicate emails manually if needed
    );
  }

  // Get user by email for login / duplicate check
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  // Update user physical stats 
  Future<int> updateUserPhysicalStats(String email, Map<String, dynamic> stats) async {
    final db = await database;
    return await db.update(
      'users',
      stats,
      where: 'email = ?',
      whereArgs: [email],
    );
  }

  // Insert a new hydration entry
  Future<int> insertWaterLog(String email, int amount, String timestamp) async {
    final db = await database;
    return await db.insert('water_logs', {
      'email': email,
      'amount': amount,
      'timestamp': timestamp,
    });
  }

  // Get all historic hydration entries for login regeneration
  Future<List<Map<String, dynamic>>> getWaterLogs(String email) async {
    final db = await database;
    return await db.query(
      'water_logs',
      where: 'email = ?',
      whereArgs: [email],
      orderBy: 'timestamp DESC',
    );
  }
}

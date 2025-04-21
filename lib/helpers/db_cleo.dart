import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBCleo {
  static final DBCleo _instance = DBCleo._internal();
  factory DBCleo() => _instance;

  DBCleo._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        content TEXT,
        timestamp TEXT,
        userNIM TEXT
      )
    ''');
  }

  // CREATE
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert('notes', note);
  }

  // READ
  Future<List<Map<String, dynamic>>> getNotesByUser(String userNIM) async {
    final db = await database;
    return await db.query('notes', where: 'userNIM = ?', whereArgs: [userNIM]);
  }

  // UPDATE
  Future<int> updateNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.update(
      'notes',
      note,
      where: 'id = ?',
      whereArgs: [note['id']],
    );
  }

  // DELETE
  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}

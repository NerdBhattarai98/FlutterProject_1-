import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TodoDB {
  static final TodoDB instance = TodoDB._init();
  TodoDB._init();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'todo.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            isDone INTEGER NOT NULL
          )
        ''');
      },
    );
    return _database!;
  }

  Future<int> addTask(String title, String description) async {
    final db = await database;
    return db.insert('tasks', {
      'title': title,
      'description': description,
      'isDone': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return db.query('tasks', orderBy: 'id DESC');
  }

  Future<int> updateTask(int id, String title, String description) async {
    final db = await database;
    return db.update(
      'tasks',
      {
        'title': title,
        'description': description,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> markDone(int id, int isDone) async {
    final db = await database;
    return db.update('tasks', {'isDone': isDone}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }
}

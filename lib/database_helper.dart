import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('keuangan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transaksi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        judul TEXT NOT NULL,
        jumlah REAL NOT NULL,
        jenis TEXT NOT NULL,
        tanggal TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertTransaksi(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transaksi', row);
  }

  Future<List<Map<String, dynamic>>> getSemuaTransaksi() async {
    final db = await instance.database;
    return await db.query('transaksi', orderBy: 'id DESC');
  }

  Future<int> deleteTransaksi(int id) async {
    final db = await instance.database;
    return await db.delete('transaksi', where: 'id = ?', whereArgs: [id]);
  }
}

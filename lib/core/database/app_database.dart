import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Quản lý kết nối SQLite và schema. Mỗi lần đổi schema: tăng [_version]
/// và thêm hàm migration tương ứng vào [_migrations].
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _version = 1;

  /// Key = phiên bản đích. Vd: 2: (db) => db.execute('ALTER TABLE ...')
  static final Map<int, Future<void> Function(Database db)> _migrations = {};

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'gia_pha.db');
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE persons (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        gender TEXT NOT NULL,
        birth_date TEXT,
        death_date TEXT,
        birth_place TEXT,
        occupation TEXT,
        bio TEXT
      )''');
    await db.execute('''
      CREATE TABLE relationships (
        id TEXT PRIMARY KEY,
        person_a_id TEXT NOT NULL,
        person_b_id TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (person_a_id) REFERENCES persons(id) ON DELETE CASCADE,
        FOREIGN KEY (person_b_id) REFERENCES persons(id) ON DELETE CASCADE
      )''');
    await db.execute('CREATE INDEX idx_rel_a ON relationships(person_a_id)');
    await db.execute('CREATE INDEX idx_rel_b ON relationships(person_b_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      await _migrations[v]?.call(db);
    }
  }
}

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Quản lý kết nối SQLite và schema. Mỗi lần đổi schema: tăng [_version]
/// và thêm hàm migration tương ứng vào [_migrations].
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _version = 4;

  /// Key = phiên bản đích.
  static final Map<int, Future<void> Function(Database db)> _migrations = {
    2: (db) async {
      await db.execute('ALTER TABLE persons ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE persons ADD COLUMN address TEXT');
      await db.execute('ALTER TABLE persons ADD COLUMN email TEXT');
      await db.execute(
        'ALTER TABLE persons ADD COLUMN seq INTEGER NOT NULL DEFAULT 0',
      );
      await db.execute('ALTER TABLE persons ADD COLUMN birth_order INTEGER');
      await db.execute('UPDATE persons SET seq = rowid');
      await _createExtraTables(db);
    },
    3: (db) async {
      await db.execute('ALTER TABLE persons ADD COLUMN photo_path TEXT');
      await _createExtraTables(db);
    },
    4: (db) async {
      await _createExtraTables(db);
    },
  };

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
        bio TEXT,
        phone TEXT,
        address TEXT,
        email TEXT,
        seq INTEGER NOT NULL DEFAULT 0,
        birth_order INTEGER,
        photo_path TEXT
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
    await _createExtraTables(db);
  }

  static Future<void> _createExtraTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS articles (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS honors (
        id TEXT PRIMARY KEY,
        person_id TEXT,
        honoree TEXT NOT NULL,
        title TEXT NOT NULL,
        year INTEGER,
        description TEXT,
        FOREIGN KEY (person_id) REFERENCES persons(id) ON DELETE SET NULL
      )''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS heirlooms (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        image_path TEXT,
        keeper TEXT,
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        k TEXT PRIMARY KEY,
        v TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        note TEXT,
        day INTEGER NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        is_lunar INTEGER NOT NULL DEFAULT 0,
        repeat_yearly INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS phado_layers (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL,
        kind TEXT NOT NULL,
        cx REAL NOT NULL,
        cy REAL NOT NULL,
        w REAL NOT NULL,
        aspect REAL NOT NULL,
        rotation REAL NOT NULL DEFAULT 0,
        opacity REAL NOT NULL DEFAULT 1,
        front INTEGER NOT NULL DEFAULT 0,
        z INTEGER NOT NULL DEFAULT 0
      )''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      await _migrations[v]?.call(db);
    }
  }
}

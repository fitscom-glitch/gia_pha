import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/members/data/models/person_model.dart';
import 'package:gia_pha/features/members/data/models/relationship_model.dart';

/// Truy cập trực tiếp SQLite. Không chứa logic nghiệp vụ.
class FamilyLocalDataSource {
  FamilyLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<PersonModel>> getPersons() async {
    final db = await _db.database;
    final rows = await db.query('persons', orderBy: 'full_name COLLATE NOCASE');
    return rows.map(PersonModel.fromMap).toList();
  }

  Future<List<RelationshipModel>> getRelationships() async {
    final db = await _db.database;
    final rows = await db.query('relationships');
    return rows.map(RelationshipModel.fromMap).toList();
  }

  /// Update nếu đã có, ngược lại insert (không dùng REPLACE vì nó xóa dòng cũ
  /// và kích hoạt ON DELETE CASCADE làm mất quan hệ). Quan hệ mới (nếu có)
  /// được ghi trong cùng giao dịch.
  Future<void> savePerson(
    PersonModel person, {
    RelationshipModel? relationship,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final updated = await txn.update(
        'persons',
        person.toMap(),
        where: 'id = ?',
        whereArgs: [person.id],
      );
      if (updated == 0) await txn.insert('persons', person.toMap());
      if (relationship != null) {
        await txn.insert('relationships', relationship.toMap());
      }
    });
  }

  Future<void> deletePerson(String id) async {
    final db = await _db.database;
    await db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }
}

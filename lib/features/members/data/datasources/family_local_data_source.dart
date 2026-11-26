import 'package:gia_pha/core/database/app_database.dart';
import 'package:gia_pha/features/members/data/models/person_model.dart';
import 'package:gia_pha/features/members/data/models/relationship_model.dart';

/// Truy cập trực tiếp SQLite. Không chứa logic nghiệp vụ.
class FamilyLocalDataSource {
  FamilyLocalDataSource(this._db);

  final AppDatabase _db;

  /// Theo thứ tự nhập vào (KHÔNG sắp theo bảng chữ cái).
  Future<List<PersonModel>> getPersons() async {
    final db = await _db.database;
    final rows = await db.query('persons', orderBy: 'seq, rowid');
    return rows.map(PersonModel.fromMap).toList();
  }

  Future<List<RelationshipModel>> getRelationships() async {
    final db = await _db.database;
    final rows = await db.query('relationships', orderBy: 'rowid');
    return rows.map(RelationshipModel.fromMap).toList();
  }

  /// Update nếu đã có, ngược lại insert với `seq` kế tiếp (không dùng REPLACE vì
  /// nó xóa dòng cũ và kích hoạt ON DELETE CASCADE làm mất quan hệ).
  /// Quan hệ mới (nếu có) được ghi trong cùng giao dịch.
  Future<void> savePerson(
    PersonModel person, {
    RelationshipModel? relationship,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final map = person.toMap();
      final updated = await txn
          .update('persons', map, where: 'id = ?', whereArgs: [person.id]);
      if (updated == 0) {
        final r = await txn.rawQuery(
          'SELECT COALESCE(MAX(seq), 0) + 1 AS next FROM persons',
        );
        final next = r.first['next'] as int;
        await txn.insert('persons', {...map, 'seq': next});
      }
      if (relationship != null) {
        await txn.insert('relationships', relationship.toMap());
      }
    });
  }

  Future<void> replaceParents(
    String childId,
    List<RelationshipModel> parents,
  ) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        'relationships',
        where: 'person_b_id = ? AND type = ?',
        whereArgs: [childId, 'parentChild'],
      );
      for (final r in parents) {
        await txn.insert('relationships', r.toMap());
      }
    });
  }

  Future<void> deletePerson(String id) async {
    final db = await _db.database;
    await db.delete('persons', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setBirthOrders(List<String> orderedIds) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < orderedIds.length; i++) {
        batch.update(
          'persons',
          {'birth_order': i + 1},
          where: 'id = ?',
          whereArgs: [orderedIds[i]],
        );
      }
      await batch.commit(noResult: true);
    });
  }
}

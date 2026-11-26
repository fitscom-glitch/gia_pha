import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';
import 'package:uuid/uuid.dart';

/// Đặt lại cha/mẹ của một người (tối đa vài người: cha, mẹ, hoặc cha + một trong các bà vợ).
class SetParents {
  const SetParents(this._repository);

  final FamilyRepository _repository;
  static const _uuid = Uuid();

  Future<void> call(String childId, List<String> parentIds) {
    final unique = <String>{
      for (final id in parentIds)
        if (id != childId) id,
    };
    return _repository.replaceParents(childId, [
      for (final pid in unique)
        Relationship(
          id: _uuid.v4(),
          personAId: pid,
          personBId: childId,
          type: RelationType.parentChild,
        ),
    ]);
  }
}

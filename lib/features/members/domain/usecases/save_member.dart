import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';
import 'package:uuid/uuid.dart';

/// Lưu thành viên. Nếu có [anchorId] + [addAs] thì tạo luôn quan hệ với người đó.
class SaveMember {
  const SaveMember(this._repository);

  final FamilyRepository _repository;
  static const _uuid = Uuid();

  Future<void> call(Person person, {String? anchorId, AddAs? addAs}) {
    final relationship = (anchorId != null && addAs != null)
        ? _relationFor(person.id, anchorId, addAs)
        : null;
    return _repository.savePerson(person, relationship: relationship);
  }

  Relationship _relationFor(String newId, String anchorId, AddAs addAs) {
    return switch (addAs) {
      AddAs.child => Relationship(
          id: _uuid.v4(),
          personAId: anchorId,
          personBId: newId,
          type: RelationType.parentChild,
        ),
      AddAs.parent => Relationship(
          id: _uuid.v4(),
          personAId: newId,
          personBId: anchorId,
          type: RelationType.parentChild,
        ),
      AddAs.spouse => Relationship(
          id: _uuid.v4(),
          personAId: anchorId,
          personBId: newId,
          type: RelationType.spouse,
        ),
    };
  }
}

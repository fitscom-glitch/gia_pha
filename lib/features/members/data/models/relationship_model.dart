import 'package:gia_pha/features/members/domain/entities/relationship.dart';

class RelationshipModel extends Relationship {
  const RelationshipModel({
    required super.id,
    required super.personAId,
    required super.personBId,
    required super.type,
  });

  factory RelationshipModel.fromEntity(Relationship r) => RelationshipModel(
        id: r.id,
        personAId: r.personAId,
        personBId: r.personBId,
        type: r.type,
      );

  factory RelationshipModel.fromMap(Map<String, Object?> m) =>
      RelationshipModel(
        id: m['id'] as String,
        personAId: m['person_a_id'] as String,
        personBId: m['person_b_id'] as String,
        type: RelationType.values.byName(m['type'] as String),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'person_a_id': personAId,
        'person_b_id': personBId,
        'type': type.name,
      };
}

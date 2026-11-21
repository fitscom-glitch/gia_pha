/// parentChild: A là cha/mẹ của B. spouse: A và B là vợ/chồng.
enum RelationType { parentChild, spouse }

/// Thêm người mới theo vai trò so với một người đã có.
enum AddAs { parent, child, spouse }

class Relationship {
  const Relationship({
    required this.id,
    required this.personAId,
    required this.personBId,
    required this.type,
  });

  final String id;
  final String personAId;
  final String personBId;
  final RelationType type;
}

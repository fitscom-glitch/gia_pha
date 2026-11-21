import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';

int compareByBirth(Person a, Person b) {
  final x = a.birthDate, y = b.birthDate;
  if (x == null && y == null) return a.fullName.compareTo(b.fullName);
  if (x == null) return 1;
  if (y == null) return -1;
  return x.compareTo(y);
}

/// Toàn bộ dữ liệu gia phả trong bộ nhớ + các truy vấn quan hệ.
class FamilyData {
  const FamilyData(this.persons, this.relationships);

  final List<Person> persons;
  final List<Relationship> relationships;

  Person? byId(String id) {
    for (final p in persons) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<Person> _resolve(Iterable<String> ids) =>
      ids.map(byId).whereType<Person>().toList();

  List<Person> parentsOf(String id) => _resolve(relationships
      .where((r) => r.type == RelationType.parentChild && r.personBId == id)
      .map((r) => r.personAId));

  List<Person> childrenOf(String id) => _resolve(relationships
      .where((r) => r.type == RelationType.parentChild && r.personAId == id)
      .map((r) => r.personBId))
    ..sort(compareByBirth);

  List<Person> spousesOf(String id) => _resolve(relationships
      .where((r) =>
          r.type == RelationType.spouse &&
          (r.personAId == id || r.personBId == id))
      .map((r) => r.personAId == id ? r.personBId : r.personAId));
}

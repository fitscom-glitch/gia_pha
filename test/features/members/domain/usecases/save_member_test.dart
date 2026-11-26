import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';
import 'package:gia_pha/features/members/domain/usecases/save_member.dart';

class _FakeRepository implements FamilyRepository {
  Person? savedPerson;
  Relationship? savedRelationship;

  @override
  Future<FamilyData> loadFamily() async => const FamilyData([], []);

  @override
  Future<void> savePerson(Person person, {Relationship? relationship}) async {
    savedPerson = person;
    savedRelationship = relationship;
  }

  @override
  Future<void> replaceParents(String childId, List<Relationship> parents) async {}

  @override
  Future<void> deletePerson(String id) async {}

  @override
  Future<void> setBirthOrders(List<String> orderedIds) async {}
}

void main() {
  const person = Person(id: 'new', fullName: 'Người mới');
  late _FakeRepository repo;
  late SaveMember saveMember;

  setUp(() {
    repo = _FakeRepository();
    saveMember = SaveMember(repo);
  });

  test('không có anchor thì không tạo quan hệ', () async {
    await saveMember(person);
    expect(repo.savedPerson?.id, 'new');
    expect(repo.savedRelationship, isNull);
  });

  test('thêm con: anchor là cha/mẹ của người mới', () async {
    await saveMember(person, anchorId: 'anchor', addAs: AddAs.child);
    final r = repo.savedRelationship!;
    expect(r.type, RelationType.parentChild);
    expect(r.personAId, 'anchor');
    expect(r.personBId, 'new');
  });

  test('thêm cha/mẹ: người mới là cha/mẹ của anchor', () async {
    await saveMember(person, anchorId: 'anchor', addAs: AddAs.parent);
    final r = repo.savedRelationship!;
    expect(r.type, RelationType.parentChild);
    expect(r.personAId, 'new');
    expect(r.personBId, 'anchor');
  });

  test('thêm vợ/chồng: quan hệ spouse giữa anchor và người mới', () async {
    await saveMember(person, anchorId: 'anchor', addAs: AddAs.spouse);
    final r = repo.savedRelationship!;
    expect(r.type, RelationType.spouse);
    expect({r.personAId, r.personBId}, {'anchor', 'new'});
  });
}

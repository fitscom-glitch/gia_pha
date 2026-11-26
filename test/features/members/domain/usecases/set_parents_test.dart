import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/domain/repositories/family_repository.dart';
import 'package:gia_pha/features/members/domain/usecases/set_parents.dart';

class _Repo implements FamilyRepository {
  String? child;
  List<Relationship> parents = const [];

  @override
  Future<void> replaceParents(String childId, List<Relationship> p) async {
    child = childId;
    parents = p;
  }

  @override
  Future<FamilyData> loadFamily() async => const FamilyData([], []);

  @override
  Future<void> savePerson(Person person, {Relationship? relationship}) async {}

  @override
  Future<void> deletePerson(String id) async {}

  @override
  Future<void> setBirthOrders(List<String> orderedIds) async {}
}

void main() {
  test('đặt cha/mẹ: mỗi người một quan hệ parentChild, bỏ trùng và bỏ chính mình', () async {
    final repo = _Repo();
    await SetParents(repo)('con', ['cha', 'me', 'cha', 'con']);
    expect(repo.child, 'con');
    expect(repo.parents.map((r) => r.personAId), ['cha', 'me']);
    expect(repo.parents.every((r) => r.personBId == 'con'), isTrue);
    expect(repo.parents.every((r) => r.type == RelationType.parentChild), isTrue);
  });

  test('danh sách rỗng = xóa hết cha/mẹ', () async {
    final repo = _Repo();
    await SetParents(repo)('con', const []);
    expect(repo.parents, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/presentation/widgets/relation_note.dart';

void main() {
  final ong = const Person(id: 'ong', fullName: 'Nguyễn Văn Tới', gender: Gender.male);
  final ba = const Person(id: 'ba', fullName: 'Nguyễn Thị Hoạch', gender: Gender.female);
  final con = const Person(id: 'con', fullName: 'Nguyễn Văn Lương', gender: Gender.male);
  final data = FamilyData([ong, ba, con], const [
    Relationship(id: 's', personAId: 'ong', personBId: 'ba', type: RelationType.spouse),
    Relationship(id: 'p1', personAId: 'ong', personBId: 'con', type: RelationType.parentChild),
    Relationship(id: 'p2', personAId: 'ba', personBId: 'con', type: RelationType.parentChild),
  ]);

  test('ghi chú vợ/chồng theo giới tính người đó', () {
    expect(relationNote(data, ong), 'Vợ: Nguyễn Thị Hoạch');
    expect(relationNote(data, ba), 'Chồng: Nguyễn Văn Tới');
  });

  test('có ghi chú cha mẹ khi cần', () {
    expect(
      relationNote(data, con),
      'Con của: Nguyễn Văn Tới & Nguyễn Thị Hoạch',
    );
    expect(relationNote(data, con, includeParents: false), isNull);
  });

  test('có 2 vợ/chồng thì đánh số ①②; "Vợ" và "Con của" nằm trên hai dòng riêng', () {
    const a = Person(id: 'a', fullName: 'Ông A', gender: Gender.male);
    const w1 = Person(id: 'w1', fullName: 'Bà Một', gender: Gender.female);
    const w2 = Person(id: 'w2', fullName: 'Bà Hai', gender: Gender.female);
    const c = Person(id: 'c', fullName: 'Con C', gender: Gender.male);
    final d = FamilyData(const [a, w1, w2, c], const [
      Relationship(id: '1', personAId: 'a', personBId: 'w1', type: RelationType.spouse),
      Relationship(id: '2', personAId: 'a', personBId: 'w2', type: RelationType.spouse),
      Relationship(id: '3', personAId: 'a', personBId: 'c', type: RelationType.parentChild),
      Relationship(id: '4', personAId: 'w2', personBId: 'c', type: RelationType.parentChild),
    ]);
    expect(relationNote(d, a), 'Vợ: ① Bà Một, ② Bà Hai');
    expect(relationNote(d, c), 'Con của: Ông A & ② Bà Hai');
    expect(circledNumber(3), '③');
  });
}

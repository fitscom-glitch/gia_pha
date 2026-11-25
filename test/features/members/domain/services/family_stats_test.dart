import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';
import 'package:gia_pha/features/members/domain/services/family_stats.dart';

Person _p(String id, Gender g, {DateTime? died}) =>
    Person(id: id, fullName: id, gender: g, deathDate: died);

Relationship _parent(String a, String b) => Relationship(
      id: '$a>$b',
      personAId: a,
      personBId: b,
      type: RelationType.parentChild,
    );

Relationship _spouse(String a, String b) => Relationship(
      id: '$a&$b',
      personAId: a,
      personBId: b,
      type: RelationType.spouse,
    );

void main() {
  test('thống kê số đời, giới tính, còn sống/đã mất và con cháu trực hệ', () {
    // ông + bà -> con trai a (vợ va), con gái b (đã mất); a + va -> cháu c.
    final data = FamilyData(
      [
        _p('ong', Gender.male, died: DateTime(1990)),
        _p('ba', Gender.female),
        _p('a', Gender.male),
        _p('va', Gender.female),
        _p('b', Gender.female, died: DateTime(2000)),
        _p('c', Gender.male),
      ],
      [
        _spouse('ong', 'ba'),
        _parent('ong', 'a'),
        _parent('ba', 'a'),
        _parent('ong', 'b'),
        _parent('ba', 'b'),
        _spouse('a', 'va'),
        _parent('a', 'c'),
        _parent('va', 'c'),
      ],
    );
    final s = computeFamilyStats(data);
    expect(s.generations, 3);
    expect(s.total, 6);
    expect(s.male, 3);
    expect(s.female, 3);
    expect(s.deceased, 2);
    expect(s.alive, 4);
    // trực hệ: a, b, c (không tính ông bà gốc, không tính dâu va)
    expect(s.directTotal, 3);
    expect(s.directMale, 2);
    expect(s.directFemale, 1);
  });

  test('gia phả rỗng', () {
    final s = computeFamilyStats(const FamilyData([], []));
    expect(s.total, 0);
    expect(s.directTotal, 0);
    expect(s.generations, 0);
  });
}

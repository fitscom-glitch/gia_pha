import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';

Person _p(String id, {int seq = 0, int? order}) =>
    Person(id: id, fullName: id, seq: seq, birthOrder: order);

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

List<String> _ids(List<Person> l) => l.map((p) => p.id).toList();

void main() {
  group('thứ tự anh em', () {
    test('mặc định theo thứ tự nhập, KHÔNG theo bảng chữ cái', () {
      // "zeta" được nhập trước "alpha"
      final data = FamilyData(
        [_p('cha', seq: 1), _p('zeta', seq: 2), _p('alpha', seq: 3)],
        [_parent('cha', 'zeta'), _parent('cha', 'alpha')],
      );
      expect(_ids(data.childrenOf('cha')), ['zeta', 'alpha']);
    });

    test('số "con thứ mấy" đã đặt được ưu tiên hơn thứ tự nhập', () {
      final data = FamilyData(
        [_p('cha', seq: 1), _p('zeta', seq: 2, order: 2), _p('alpha', seq: 3, order: 1)],
        [_parent('cha', 'zeta'), _parent('cha', 'alpha')],
      );
      expect(_ids(data.childrenOf('cha')), ['alpha', 'zeta']);
    });

    test('người đã đặt thứ tự đứng trước người chưa đặt', () {
      final data = FamilyData(
        [_p('cha', seq: 1), _p('a', seq: 2), _p('b', seq: 3, order: 1)],
        [_parent('cha', 'a'), _parent('cha', 'b')],
      );
      expect(_ids(data.childrenOf('cha')), ['b', 'a']);
    });

    test('con của hai vợ chồng được gộp đúng thứ tự', () {
      final data = FamilyData(
        [_p('cha', seq: 1), _p('me', seq: 2), _p('c1', seq: 3), _p('c2', seq: 4), _p('c3', seq: 5)],
        [
          _spouse('cha', 'me'),
          _parent('cha', 'c1'),
          _parent('me', 'c2'),
          _parent('cha', 'c3'),
        ],
      );
      expect(_ids(data.childrenOfUnit('cha')), ['c1', 'c2', 'c3']);
      expect(_ids(data.childrenOfUnit('me')), ['c1', 'c2', 'c3']);
    });
  });

  group('thứ tự theo mối quan hệ', () {
    List<String> ids(FamilyData d) => d.relationOrder().map((e) => e.person.id).toList();

    test('vợ chồng liền nhau, rồi con cháu theo từng nhánh', () {
      final data = FamilyData(
        [
          _p('ong', seq: 1),
          _p('ba', seq: 2),
          _p('c1', seq: 3),
          _p('v1', seq: 4),
          _p('c2', seq: 5),
          _p('g1', seq: 6),
        ],
        [
          _spouse('ong', 'ba'),
          _parent('ong', 'c1'),
          _spouse('c1', 'v1'),
          _parent('ong', 'c2'),
          _parent('c1', 'g1'),
        ],
      );
      // c1 và cả nhánh của c1 (vợ, con) đứng trước c2
      expect(ids(data), ['ong', 'ba', 'c1', 'v1', 'g1', 'c2']);
      expect(data.relationOrder().map((e) => e.depth), [0, 0, 1, 1, 2, 1]);
    });

    test('dâu/rể nhập trước chồng/vợ vẫn đi kèm vợ/chồng, không làm gốc', () {
      final data = FamilyData(
        [_p('dau', seq: 1), _p('cha', seq: 2), _p('con', seq: 3)],
        [_spouse('cha', 'dau'), _parent('cha', 'con')],
      );
      expect(ids(data), ['cha', 'dau', 'con']);
    });

    test('mọi người đều có mặt, kể cả người chưa có quan hệ', () {
      final data = FamilyData(
        [_p('a', seq: 1), _p('b', seq: 2), _p('c', seq: 3)],
        [_parent('a', 'b')],
      );
      expect(ids(data), ['a', 'b', 'c']);
    });
  });

  group('đời', () {
    final data = FamilyData(
      [_p('ong'), _p('ba'), _p('cha'), _p('dau'), _p('chau')],
      [
        _spouse('ong', 'ba'),
        _parent('ong', 'cha'),
        _spouse('cha', 'dau'),
        _parent('cha', 'chau'),
      ],
    );

    test('mỗi người một đời, dâu/rể cùng đời với vợ/chồng', () {
      final g = data.generations();
      expect(g['ong'], 0);
      expect(g['ba'], 0);
      expect(g['cha'], 1);
      expect(g['dau'], 1);
      expect(g['chau'], 2);
    });

    test('tổng số đời', () {
      expect(data.generationCount, 3);
      expect(const FamilyData([], []).generationCount, 0);
    });
  });

  group('người có 2 vợ/chồng', () {
    // ông có hai bà: b1 -> con a1 (con chung), b2 -> con a2 (con chung); riêng: con r.
    const ong = Person(id: 'ong', fullName: 'Ông', gender: Gender.male);
    const b1 = Person(id: 'b1', fullName: 'Bà 1', gender: Gender.female);
    const b2 = Person(id: 'b2', fullName: 'Bà 2', gender: Gender.female);
    const a1 = Person(id: 'a1', fullName: 'A1');
    const a2 = Person(id: 'a2', fullName: 'A2');
    const r = Person(id: 'r', fullName: 'R');
    Relationship rel(String id, String a, String b, RelationType t) =>
        Relationship(id: id, personAId: a, personBId: b, type: t);
    final data = FamilyData(const [ong, b1, b2, a1, a2, r], [
      rel('s1', 'ong', 'b1', RelationType.spouse),
      rel('s2', 'ong', 'b2', RelationType.spouse),
      rel('1', 'ong', 'a1', RelationType.parentChild),
      rel('2', 'b1', 'a1', RelationType.parentChild),
      rel('3', 'ong', 'a2', RelationType.parentChild),
      rel('4', 'b2', 'a2', RelationType.parentChild),
      rel('5', 'ong', 'r', RelationType.parentChild),
    ]);

    test('ông thấy tất cả các con', () {
      expect(_ids(data.childrenOfUnit('ong')).toSet(), {'a1', 'a2', 'r'});
    });

    test('mỗi bà chỉ thấy con đã đánh dấu là của mình', () {
      expect(_ids(data.childrenOfUnit('b1')), ['a1']);
      expect(_ids(data.childrenOfUnit('b2')), ['a2']);
    });
  });
}

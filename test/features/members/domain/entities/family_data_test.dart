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
}

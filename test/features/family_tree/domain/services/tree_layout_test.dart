import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_builder.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';

Person _p(String id, [Gender g = Gender.male]) =>
    Person(id: id, fullName: id, gender: g);

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
  group('buildDescendantTree', () {
    test('gộp con của cả hai vợ chồng', () {
      final data = FamilyData(
        [_p('ong'), _p('ba', Gender.female), _p('con1'), _p('con2')],
        [_spouse('ong', 'ba'), _parent('ong', 'con1'), _parent('ba', 'con2')],
      );
      final tree = buildDescendantTree(data, 'ong')!;
      expect(tree.spouses.map((s) => s.id), ['ba']);
      expect(tree.children.map((c) => c.person.id).toSet(), {'con1', 'con2'});
    });

    test('không lặp vô hạn khi dữ liệu có vòng', () {
      final data = FamilyData(
        [_p('a'), _p('b')],
        [_parent('a', 'b'), _parent('b', 'a')],
      );
      final tree = buildDescendantTree(data, 'a')!;
      expect(tree.children.length, 1);
      expect(tree.children.first.children, isEmpty);
    });

    test('trả về null khi không có người gốc', () {
      expect(buildDescendantTree(const FamilyData([], []), 'x'), isNull);
    });
  });

  group('layoutTree', () {
    test('thẻ cùng đời không chồng lấn, cha mẹ nằm giữa các con', () {
      final data = FamilyData(
        [_p('a'), _p('b1'), _p('b2'), _p('b3')],
        [_parent('a', 'b1'), _parent('a', 'b2'), _parent('a', 'b3')],
      );
      final layout = layoutTree(buildDescendantTree(data, 'a')!);
      final cfg = layout.config;
      final root = layout.units.firstWhere((u) => u.node.person.id == 'a');
      final kids = layout.units.where((u) => u.node.person.id != 'a').toList()
        ..sort((l, r) => l.x.compareTo(r.x));

      expect(kids.length, 3);
      for (var i = 0; i + 1 < kids.length; i++) {
        expect(
          kids[i + 1].x - kids[i].x,
          greaterThanOrEqualTo(cfg.cardW + cfg.hGap - 0.001),
        );
      }
      final rootCenter = root.x + cfg.cardW / 2;
      final kidsCenter = (kids.first.x + kids.last.x) / 2 + cfg.cardW / 2;
      expect(rootCenter, closeTo(kidsCenter, 0.001));
      expect(kids.every((k) => k.y > root.y), isTrue);
      expect(layout.width, greaterThanOrEqualTo(kids.last.x + cfg.cardW));
    });

    test('đơn vị vợ chồng đủ rộng cho hai thẻ', () {
      final data = FamilyData(
        [_p('ong'), _p('ba', Gender.female)],
        [_spouse('ong', 'ba')],
      );
      final layout = layoutTree(buildDescendantTree(data, 'ong')!);
      final cfg = layout.config;
      expect(layout.units.length, 1);
      expect(layout.spouseLinks.length, 1);
      expect(
        layout.width,
        closeTo(2 * cfg.cardW + cfg.spouseGap + 2 * cfg.margin, 0.001),
      );
    });
  });
}

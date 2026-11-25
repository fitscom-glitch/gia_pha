import 'package:flutter_test/flutter_test.dart';
import 'package:gia_pha/features/family_tree/domain/entities/tree_node.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_builder.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/domain/entities/relationship.dart';

Person _p(String id) => Person(id: id, fullName: id);

Relationship _parent(String a, String b) => Relationship(
      id: '$a>$b',
      personAId: a,
      personBId: b,
      type: RelationType.parentChild,
    );

void main() {
  // a(đời 1) -> b(đời 2) -> c(đời 3) -> d(đời 4)
  final data = FamilyData(
    [_p('a'), _p('b'), _p('c'), _p('d')],
    [_parent('a', 'b'), _parent('b', 'c'), _parent('c', 'd')],
  );
  final tree = buildDescendantTree(data, 'a')!;

  List<String> ids(TreeNode n) => [n.person.id, for (final c in n.children) ...ids(c)];

  test('ẩn đời giữa: con cháu nối lên người hiển thị gần nhất', () {
    final roots = collapseTree(tree, (p) => p.id != 'b' && p.id != 'c');
    expect(roots.length, 1);
    expect(ids(roots.single), ['a', 'd']);
    expect(roots.single.children.single.person.id, 'd');
  });

  test('ẩn người gốc: trả về các nhánh làm gốc', () {
    final roots = collapseTree(tree, (p) => p.id != 'a');
    expect(roots.map((r) => r.person.id), ['b']);
    expect(ids(roots.single), ['b', 'c', 'd']);
  });

  test('xếp nhiều gốc cạnh nhau, không chồng lấn', () {
    final two = FamilyData(
      [_p('x'), _p('y')],
      const [],
    );
    final roots = [
      TreeNode(two.persons[0], const [], []),
      TreeNode(two.persons[1], const [], []),
    ];
    final layout = layoutTreeForest(roots);
    final xs = layout.units.map((u) => u.x).toList()..sort();
    expect(xs[1] - xs[0], greaterThanOrEqualTo(layout.config.cardW + layout.config.hGap - 0.001));
    expect(layout.units.every((u) => u.y == layout.units.first.y), isTrue);
  });
}

import 'package:gia_pha/features/family_tree/domain/entities/tree_node.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

/// Dựng cây hậu duệ từ [rootId]. Con của cả người gốc và vợ/chồng đều được gộp.
/// Trả về null nếu không tìm thấy [rootId].
TreeNode? buildDescendantTree(FamilyData data, String rootId) {
  final root = data.byId(rootId);
  if (root == null) return null;
  final visited = <String>{};

  TreeNode build(Person p) {
    visited.add(p.id);
    final spouses =
        data.spousesOf(p.id).where((s) => !visited.contains(s.id)).toList();
    visited.addAll(spouses.map((s) => s.id));

    final kids = <String, Person>{};
    for (final parent in [p, ...spouses]) {
      for (final c in data.childrenOf(parent.id)) {
        if (!visited.contains(c.id)) kids[c.id] = c;
      }
    }
    visited.addAll(kids.keys); // tránh một người xuất hiện 2 lần / vòng lặp
    final sorted = sortedSiblings(kids.values); // đúng thứ tự anh em
    return TreeNode(p, spouses, [for (final k in sorted) build(k)]);
  }

  return build(root);
}

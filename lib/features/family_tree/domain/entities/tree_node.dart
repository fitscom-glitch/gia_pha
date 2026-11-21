import 'package:gia_pha/features/members/domain/entities/person.dart';

/// Một "đơn vị" trên cây: 1 người + các vợ/chồng, kèm danh sách con.
class TreeNode {
  TreeNode(this.person, this.spouses, this.children);

  final Person person;
  final List<Person> spouses;
  final List<TreeNode> children;
}

import 'dart:math' as math;

import 'package:gia_pha/features/family_tree/domain/entities/tree_node.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';

class LayoutConfig {
  const LayoutConfig({
    this.cardW = 132,
    this.cardH = 84,
    this.spouseGap = 18,
    this.hGap = 28,
    this.vGap = 64,
    this.margin = 32,
  });

  final double cardW, cardH, spouseGap, hGap, vGap, margin;
}

/// Vị trí góc trên-trái của một đơn vị (người + vợ/chồng) và hàng của nó.
class PositionedUnit {
  const PositionedUnit(this.node, this.x, this.y, this.row);

  final TreeNode node;
  final double x, y;
  final int row;
}

class TreeEdge {
  const TreeEdge(this.fromX, this.fromY, this.toX, this.toY);

  final double fromX, fromY, toX, toY;
}

/// Một hàng đã dùng trên sơ đồ: chỉ số hàng và tọa độ y của nó.
class LayoutRow {
  const LayoutRow(this.row, this.y);

  final int row;
  final double y;
}

class TreeLayoutResult {
  const TreeLayoutResult({
    required this.units,
    required this.childEdges,
    required this.spouseLinks,
    required this.rows,
    required this.width,
    required this.height,
    required this.config,
  });

  final List<PositionedUnit> units;
  final List<TreeEdge> childEdges;
  final List<TreeEdge> spouseLinks;
  final List<LayoutRow> rows;
  final double width, height;
  final LayoutConfig config;
}

/// Đoạn: các đơn vị cùng một hàng nối tiếp nhau (do gộp đời) cùng các nhánh con ở hàng dưới.
class _Segment {
  _Segment(this.row);

  final int row;
  final members = <TreeNode>[];
  final exits = <_Segment>[];
  final exitParents = <TreeNode>[];
}

class _Layouter {
  _Layouter(this.c, this.rowOf);

  final LayoutConfig c;
  final int Function(Person) rowOf;
  final _segW = <_Segment, double>{};
  final units = <PositionedUnit>[];
  final childEdges = <TreeEdge>[];
  final spouseLinks = <TreeEdge>[];
  final _centers = <TreeNode, double>{};
  int baseRow = 0;
  int maxOffset = 0;

  double unitW(TreeNode n) {
    final k = 1 + n.spouses.length;
    return k * c.cardW + (k - 1) * c.spouseGap;
  }

  _Segment build(TreeNode start) {
    final row = rowOf(start.person);
    final seg = _Segment(row);
    void visit(TreeNode n) {
      seg.members.add(n);
      for (final ch in n.children) {
        if (rowOf(ch.person) == row) {
          visit(ch);
        } else {
          seg.exits.add(build(ch));
          seg.exitParents.add(n);
        }
      }
    }

    visit(start);
    return seg;
  }

  double unitsW(_Segment s) {
    var w = c.hGap * (s.members.length - 1);
    for (final m in s.members) {
      w += unitW(m);
    }
    return w;
  }

  double exitsW(_Segment s) {
    if (s.exits.isEmpty) return 0;
    var w = c.hGap * (s.exits.length - 1);
    for (final e in s.exits) {
      w += segW(e);
    }
    return w;
  }

  double segW(_Segment s) {
    final cached = _segW[s];
    if (cached != null) return cached;
    final w = math.max(unitsW(s), exitsW(s));
    _segW[s] = w;
    return w;
  }

  double rowY(int row) => c.margin + (row - baseRow) * (c.cardH + c.vGap);

  void place(_Segment s, double left) {
    final sw = segW(s);
    maxOffset = math.max(maxOffset, s.row - baseRow);
    final y = rowY(s.row);
    var x = left + (sw - unitsW(s)) / 2;
    for (final m in s.members) {
      final w = unitW(m);
      units.add(PositionedUnit(m, x, y, s.row));
      for (var i = 0; i < m.spouses.length; i++) {
        final right = x + i * (c.cardW + c.spouseGap) + c.cardW;
        final midY = y + c.cardH / 2;
        spouseLinks.add(TreeEdge(right, midY, right + c.spouseGap, midY));
      }
      _centers[m] = x + w / 2;
      x += w + c.hGap;
    }
    var childLeft = left + (sw - exitsW(s)) / 2;
    for (var i = 0; i < s.exits.length; i++) {
      final ch = s.exits[i];
      place(ch, childLeft);
      childEdges.add(TreeEdge(
        _centers[s.exitParents[i]]!,
        y + c.cardH,
        _centers[ch.members.first]!,
        rowY(ch.row),
      ));
      childLeft += segW(ch) + c.hGap;
    }
  }
}

/// Xếp cây hậu duệ thành các hàng. [rowOf] cho biết hàng của một người (đời nào vào hàng nào);
/// nếu null thì mỗi đời một hàng (theo độ sâu). Các đời gộp chung một hàng sẽ nằm nối tiếp
/// nhau trên hàng đó, không vẽ nét nối giữa cha mẹ và con trong cùng hàng.
TreeLayoutResult layoutTree(
  TreeNode root, {
  LayoutConfig config = const LayoutConfig(),
  int Function(Person person)? rowOf,
}) =>
    layoutTreeForest([root], config: config, rowOf: rowOf);

/// Như [layoutTree] nhưng cho nhiều gốc đặt cạnh nhau (khi người gốc bị ẩn do gộp đời).
TreeLayoutResult layoutTreeForest(
  List<TreeNode> roots, {
  LayoutConfig config = const LayoutConfig(),
  int Function(Person person)? rowOf,
}) {
  assert(roots.isNotEmpty);
  final depthRow = <String, int>{};
  if (rowOf == null) {
    void walk(TreeNode n, int d) {
      depthRow[n.person.id] = d;
      for (final ch in n.children) {
        walk(ch, d + 1);
      }
    }

    for (final r in roots) {
      walk(r, 0);
    }
  }
  int rowFn(Person p) => rowOf != null ? rowOf(p) : (depthRow[p.id] ?? 0);

  final l = _Layouter(config, rowFn);
  l.baseRow = roots.map((r) => rowFn(r.person)).reduce(math.min);
  final segments = [for (final r in roots) l.build(r)];
  var left = config.margin;
  for (final s in segments) {
    l.place(s, left);
    left += l.segW(s) + config.hGap;
  }

  final ys = <int, double>{for (final u in l.units) u.row: u.y};
  final rows = [for (final r in ys.keys.toList()..sort()) LayoutRow(r, ys[r]!)];
  final width = (left - config.hGap) + config.margin;
  final height = (l.maxOffset + 1) * config.cardH +
      l.maxOffset * config.vGap +
      2 * config.margin;
  return TreeLayoutResult(
    units: l.units,
    childEdges: l.childEdges,
    spouseLinks: l.spouseLinks,
    rows: rows,
    width: width,
    height: height,
    config: config,
  );
}

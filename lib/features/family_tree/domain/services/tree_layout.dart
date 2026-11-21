import 'dart:math' as math;

import 'package:gia_pha/features/family_tree/domain/entities/tree_node.dart';

class LayoutConfig {
  const LayoutConfig({
    this.cardW = 132,
    this.cardH = 76,
    this.spouseGap = 18,
    this.hGap = 28,
    this.vGap = 64,
    this.margin = 32,
  });

  final double cardW, cardH, spouseGap, hGap, vGap, margin;
}

/// Vị trí góc trên-trái của một đơn vị (người + vợ/chồng).
class PositionedUnit {
  const PositionedUnit(this.node, this.x, this.y);

  final TreeNode node;
  final double x, y;
}

class TreeEdge {
  const TreeEdge(this.fromX, this.fromY, this.toX, this.toY);

  final double fromX, fromY, toX, toY;
}

class TreeLayoutResult {
  const TreeLayoutResult({
    required this.units,
    required this.childEdges,
    required this.spouseLinks,
    required this.width,
    required this.height,
    required this.config,
  });

  final List<PositionedUnit> units;
  final List<TreeEdge> childEdges;
  final List<TreeEdge> spouseLinks;
  final double width, height;
  final LayoutConfig config;
}

class _Layouter {
  _Layouter(this.c);

  final LayoutConfig c;
  final _subW = <TreeNode, double>{};
  final units = <PositionedUnit>[];
  final childEdges = <TreeEdge>[];
  final spouseLinks = <TreeEdge>[];
  int maxDepth = 0;

  double unitW(TreeNode n) {
    final k = 1 + n.spouses.length;
    return k * c.cardW + (k - 1) * c.spouseGap;
  }

  double childrenW(TreeNode n) {
    if (n.children.isEmpty) return 0;
    var w = c.hGap * (n.children.length - 1);
    for (final ch in n.children) {
      w += subtreeW(ch);
    }
    return w;
  }

  /// Bề rộng cần cho cả nhánh = max(bề rộng đơn vị, tổng bề rộng các con).
  double subtreeW(TreeNode n) {
    final cached = _subW[n];
    if (cached != null) return cached;
    final w = math.max(unitW(n), childrenW(n));
    _subW[n] = w;
    return w;
  }

  void place(TreeNode n, double left, int depth) {
    maxDepth = math.max(maxDepth, depth);
    final sw = subtreeW(n);
    final uw = unitW(n);
    final x = left + (sw - uw) / 2; // căn giữa đơn vị trong nhánh của nó
    final y = c.margin + depth * (c.cardH + c.vGap);
    units.add(PositionedUnit(n, x, y));

    for (var i = 0; i < n.spouses.length; i++) {
      final right = x + i * (c.cardW + c.spouseGap) + c.cardW;
      final midY = y + c.cardH / 2;
      spouseLinks.add(TreeEdge(right, midY, right + c.spouseGap, midY));
    }

    final parentX = left + sw / 2;
    final parentY = y + c.cardH;
    var childLeft = left + (sw - childrenW(n)) / 2;
    for (final ch in n.children) {
      final csw = subtreeW(ch);
      childEdges.add(
        TreeEdge(parentX, parentY, childLeft + csw / 2, parentY + c.vGap),
      );
      place(ch, childLeft, depth + 1);
      childLeft += csw + c.hGap;
    }
  }
}

TreeLayoutResult layoutTree(
  TreeNode root, {
  LayoutConfig config = const LayoutConfig(),
}) {
  final l = _Layouter(config);
  l.place(root, config.margin, 0);
  final width = l.subtreeW(root) + 2 * config.margin;
  final height = (l.maxDepth + 1) * config.cardH +
      l.maxDepth * config.vGap +
      2 * config.margin;
  return TreeLayoutResult(
    units: l.units,
    childEdges: l.childEdges,
    spouseLinks: l.spouseLinks,
    width: width,
    height: height,
    config: config,
  );
}

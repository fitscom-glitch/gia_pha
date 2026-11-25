import 'dart:ui';

import 'package:gia_pha/features/family_tree/domain/services/generation_rows.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_builder.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/pha_do_canvas.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/settings/domain/entities/app_settings.dart';

/// Kết quả xếp phả đồ: bố cục, đời của từng người và các hàng đời.
class PhaDoModel {
  const PhaDoModel({
    required this.layout,
    required this.generations,
    required this.rows,
    required this.data,
  });

  final TreeLayoutResult layout;
  final Map<String, int> generations;
  final List<List<int>> rows;
  final FamilyData data;

  Size get size => PhaDoCanvas.sizeOf(layout);

  /// Gốc mặc định: người không có cha mẹ, ưu tiên người có con và nhập trước.
  static String? defaultRootId(FamilyData d) {
    if (d.persons.isEmpty) return null;
    final roots = d.persons.where((p) => d.parentsOf(p.id).isEmpty).toList();
    final pool = [...(roots.isEmpty ? d.persons : roots)];
    pool.sort((a, b) {
      final ha = d.childrenOf(a.id).isNotEmpty;
      final hb = d.childrenOf(b.id).isNotEmpty;
      if (ha != hb) return ha ? -1 : 1;
      return a.seq.compareTo(b.seq);
    });
    return pool.first.id;
  }

  /// Null nếu chưa có thành viên để hiển thị.
  static PhaDoModel? build(FamilyData d, AppSettings settings, String? requestedRoot) {
    var tree = requestedRoot == null ? null : buildDescendantTree(d, requestedRoot);
    if (tree == null) {
      final fallback = defaultRootId(d);
      tree = fallback == null ? null : buildDescendantTree(d, fallback);
    }
    if (tree == null) return null;

    final gens = d.generations();
    final groups = parseGenerationGroups(settings.generationGroups);
    final rows = buildGenerationRows(d.generationCount, groups);
    final rowOfGen = {
      for (var r = 0; r < rows.length; r++)
        for (final g in rows[r]) g: r,
    };
    int genOf(Person p) => (gens[p.id] ?? 0) + 1;
    final roots = collapseTree(tree, (p) => !isGenerationHidden(genOf(p), groups));
    if (roots.isEmpty) return null;
    final layout = layoutTreeForest(roots, rowOf: (p) => rowOfGen[genOf(p)] ?? 0);
    return PhaDoModel(layout: layout, generations: gens, rows: rows, data: d);
  }
}

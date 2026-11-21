import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_builder.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';

class TreePage extends ConsumerStatefulWidget {
  const TreePage({super.key, this.initialRootId});

  final String? initialRootId;

  @override
  ConsumerState<TreePage> createState() => _TreePageState();
}

class _TreePageState extends ConsumerState<TreePage> {
  String? _rootId;

  @override
  void initState() {
    super.initState();
    _rootId = widget.initialRootId;
  }

  /// Gốc mặc định: người không có cha mẹ, ưu tiên người có con và sinh sớm nhất.
  String? _defaultRoot(FamilyData d) {
    if (d.persons.isEmpty) return null;
    final roots = d.persons.where((p) => d.parentsOf(p.id).isEmpty).toList();
    final pool = [...(roots.isEmpty ? d.persons : roots)];
    pool.sort((a, b) {
      final ha = d.childrenOf(a.id).isNotEmpty;
      final hb = d.childrenOf(b.id).isNotEmpty;
      if (ha != hb) return ha ? -1 : 1;
      return compareByBirth(a, b);
    });
    return pool.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final family = ref.watch(familyProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sơ đồ gia phả'),
        actions: [
          family.maybeWhen(
            data: (d) => PopupMenuButton<String>(
              icon: const Icon(Icons.person_search),
              tooltip: 'Chọn người gốc',
              onSelected: (id) => setState(() => _rootId = id),
              itemBuilder: (_) => [
                for (final p in d.persons)
                  PopupMenuItem(value: p.id, child: Text(p.fullName)),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: family.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (d) {
          final rootId = _rootId ?? _defaultRoot(d);
          final tree = rootId == null ? null : buildDescendantTree(d, rootId);
          if (tree == null) {
            return const Center(child: Text('Chưa có thành viên để hiển thị'));
          }
          return _TreeCanvas(layout: layoutTree(tree));
        },
      ),
    );
  }
}

class _TreeCanvas extends StatelessWidget {
  const _TreeCanvas({required this.layout});

  final TreeLayoutResult layout;

  @override
  Widget build(BuildContext context) {
    final cfg = layout.config;
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(200),
      minScale: 0.2,
      maxScale: 2.5,
      child: SizedBox(
        width: layout.width,
        height: layout.height,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(layout.width, layout.height),
              painter: _EdgePainter(
                layout.childEdges,
                layout.spouseLinks,
                Theme.of(context).colorScheme.outline,
              ),
            ),
            for (final u in layout.units)
              for (final (i, p) in [u.node.person, ...u.node.spouses].indexed)
                Positioned(
                  left: u.x + i * (cfg.cardW + cfg.spouseGap),
                  top: u.y,
                  width: cfg.cardW,
                  height: cfg.cardH,
                  child: _PersonCard(p),
                ),
          ],
        ),
      ),
    );
  }
}

class _EdgePainter extends CustomPainter {
  _EdgePainter(this.childEdges, this.spouseLinks, this.color);

  final List<TreeEdge> childEdges;
  final List<TreeEdge> spouseLinks;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final e in childEdges) {
      final midY = (e.fromY + e.toY) / 2;
      final path = Path()
        ..moveTo(e.fromX, e.fromY)
        ..lineTo(e.fromX, midY)
        ..lineTo(e.toX, midY)
        ..lineTo(e.toX, e.toY);
      canvas.drawPath(path, paint);
    }
    for (final e in spouseLinks) {
      canvas.drawLine(Offset(e.fromX, e.fromY), Offset(e.toX, e.toY), paint);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.childEdges != childEdges ||
      old.spouseLinks != spouseLinks ||
      old.color != color;
}

class _PersonCard extends StatelessWidget {
  const _PersonCard(this.person);

  final Person person;

  @override
  Widget build(BuildContext context) {
    final color = genderColor(person.gender);
    return Material(
      color: color.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.shade300),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/person/${person.id}'),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                person.fullName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (person.lifespan.isNotEmpty)
                Text(
                  person.lifespan,
                  style: TextStyle(
                    fontSize: 11,
                    color: person.isDeceased ? Colors.black54 : color.shade700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

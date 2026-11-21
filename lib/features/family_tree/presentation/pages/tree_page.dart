import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/gold_app_bar.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_data.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_painter.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_builder.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/providers/family_providers.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';

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
      appBar: GoldAppBar(
        title: 'Sơ đồ gia phả',
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
      body: PatternBackground(
        child: family.when(
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
              painter: _EdgePainter(layout.childEdges, layout.spouseLinks),
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

/// Nét nối cha mẹ – con (đỏ thẫm, chấm vàng ở hai đầu) và "đồng tiền" nối vợ chồng.
class _EdgePainter extends CustomPainter {
  _EdgePainter(this.childEdges, this.spouseLinks);

  final List<TreeEdge> childEdges;
  final List<TreeEdge> spouseLinks;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.redDark
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final dot = Paint()..color = AppColors.gold;
    final dotRing = Paint()
      ..color = AppColors.redDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    for (final e in childEdges) {
      final midY = (e.fromY + e.toY) / 2;
      final path = Path()
        ..moveTo(e.fromX, e.fromY)
        ..lineTo(e.fromX, midY)
        ..lineTo(e.toX, midY)
        ..lineTo(e.toX, e.toY);
      canvas.drawPath(path, line);
    }
    for (final e in childEdges) {
      for (final pt in [Offset(e.fromX, e.fromY), Offset(e.toX, e.toY)]) {
        canvas.drawCircle(pt, 3.6, dot);
        canvas.drawCircle(pt, 3.6, dotRing);
      }
    }

    final coinFill = Paint()..color = AppColors.red;
    final coinRing = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final e in spouseLinks) {
      canvas.drawLine(Offset(e.fromX, e.fromY), Offset(e.toX, e.toY), line);
      final c = Offset((e.fromX + e.toX) / 2, e.fromY);
      canvas.drawCircle(c, 5.2, coinFill);
      canvas.drawCircle(c, 5.2, coinRing);
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.childEdges != childEdges || old.spouseLinks != spouseLinks;
}

/// Thẻ thành viên: viền vàng, dải màu theo giới, hình rồng (nam) / phụng (nữ) mờ làm nền.
class _PersonCard extends StatelessWidget {
  const _PersonCard(this.person);

  final Person person;

  @override
  Widget build(BuildContext context) {
    final style = genderStyle(person.gender);
    final motif = person.gender == Gender.female ? phoenixMotif : dragonMotif;
    return Material(
      color: person.isDeceased ? AppColors.paperDark : AppColors.card,
      elevation: 2,
      shadowColor: const Color(0x667F0E14),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.goldDark, width: 1.6),
      ),
      child: InkWell(
        onTap: () => context.push('/person/${person.id}'),
        child: Stack(
          children: [
            Positioned(
              right: 3,
              bottom: 3,
              width: 62,
              height: 36,
              child: MotifView(
                motif: motif,
                color: style.accent.withAlpha(46),
                flipX: person.gender == Gender.female,
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 6,
              child: ColoredBox(color: style.accent),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      person.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.ink,
                      ),
                    ),
                    if (person.lifespan.isNotEmpty)
                      Text(
                        person.lifespan,
                        style: TextStyle(
                          fontSize: 11,
                          color: person.isDeceased
                              ? AppColors.goldDark
                              : AppColors.redDark,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

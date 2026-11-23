import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_data.dart';
import 'package:gia_pha/core/widgets/ornaments/motif_painter.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/family_tree/domain/services/generation_rows.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/generation_colors.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';
import 'package:gia_pha/features/members/presentation/widgets/relation_note.dart';

const _orange = Color(0xFFF58220);
const _navy = Color(0xFF1A237E);

/// Phả đồ dạng tranh treo: khung vàng cam, hai rồng, băng rôn tên dòng họ,
/// nhãn "ĐỜI THỨ N" bên trái và cây gia phả ở giữa.
class PhaDoCanvas extends StatelessWidget {
  const PhaDoCanvas({
    super.key,
    required this.layout,
    required this.data,
    required this.generations,
    required this.rows,
    required this.clanName,
    required this.place,
    required this.onOpenPerson,
  });

  final TreeLayoutResult layout;
  final FamilyData data;

  /// Đời (0-based) của từng người.
  final Map<String, int> generations;

  /// Các hàng của toàn gia phả; mỗi hàng là danh sách đời (tính từ 1).
  final List<List<int>> rows;
  final String clanName;
  final String place;
  final void Function(String personId) onOpenPerson;

  static const double _band = 58;
  static const double _header = 220;
  static const double _labelW = 130;
  static const double _sideW = 24;
  static const double _footer = 80;
  static const double _minTreeH = 440;
  static const double _minWidth = 980;

  static Size sizeOf(TreeLayoutResult layout) {
    final w = layout.width + 2 * (_band + _sideW) + _labelW;
    final h = 2 * _band + _header + (layout.height < _minTreeH ? _minTreeH : layout.height) + _footer;
    return Size(w < _minWidth ? _minWidth : w, h);
  }

  @override
  Widget build(BuildContext context) {
    final size = sizeOf(layout);
    final contentLeft = _band + _sideW + _labelW;
    final innerW = size.width - contentLeft - _sideW - _band;
    final treeX = contentLeft + (innerW - layout.width) / 2;
    final treeY = _band + _header;
    final cfg = layout.config;
    final trimmed = clanName.trim();
    final title = trimmed.isEmpty ? 'GIA TỘC' : '${trimmed.toUpperCase()} TỘC';

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _FramePainter(_band))),
          // hình rồng mờ làm nền
          Positioned(
            left: contentLeft + innerW * 0.08,
            top: treeY,
            width: innerW * 0.84,
            height: layout.height < _minTreeH ? _minTreeH : layout.height,
            child: const MotifView(motif: dragonMotif, color: Color(0x22E0A800)),
          ),
          Positioned(
            left: (size.width - 620) / 2,
            top: _band + 28,
            width: 620,
            height: 170,
            child: _ScrollBanner(title: title, place: place),
          ),
          // nhãn các đời
          for (final r in layout.rows)
            Positioned(
              left: _band + _sideW + 4,
              top: treeY + r.y + (cfg.cardH - 28) / 2,
              width: _labelW - 12,
              height: 28,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.black54),
                ),
                child: Text(
                  r.row < rows.length ? generationRowLabel(rows[r.row]) : '',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          // nét nối
          Positioned(
            left: treeX,
            top: treeY,
            width: layout.width,
            height: layout.height,
            child: CustomPaint(painter: _EdgePainter(layout.childEdges, layout.spouseLinks)),
          ),
          // thẻ thành viên
          for (final u in layout.units)
            for (final (i, p) in [u.node.person, ...u.node.spouses].indexed)
              Positioned(
                left: treeX + u.x + i * (cfg.cardW + cfg.spouseGap),
                top: treeY + u.y,
                width: cfg.cardW,
                height: cfg.cardH,
                child: _PhaCard(
                  person: p,
                  fill: generationFill(generations[p.id] ?? generations[u.node.person.id] ?? 0, p.gender),
                  note: relationNote(data, p, includeParents: false),
                  onTap: () => onOpenPerson(p.id),
                ),
              ),
        ],
      ),
    );
  }
}

/// Băng rôn đỏ có hai trục cuộn hai đầu: "PHẢ ĐỒ" + tên dòng họ + địa danh.
class _ScrollBanner extends StatelessWidget {
  const _ScrollBanner({required this.title, required this.place});

  final String title;
  final String place;

  Widget _roll() => Container(
        width: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8BC34A), Color(0xFFDCEDC8), Color(0xFF8BC34A)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E88E5), width: 3),
        ),
        child: Column(
          children: [
            Container(height: 16, color: const Color(0xFF1E88E5)),
            const Spacer(),
            Container(height: 16, color: const Color(0xFF1E88E5)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          left: 44,
          right: 44,
          top: 8,
          bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: const Color(0xFFE41E26),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.gold, width: 4),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'PHẢ ĐỒ',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    letterSpacing: 8,
                    color: AppColors.goldLight,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.w900,
                      fontSize: 48,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                if (place.trim().isNotEmpty)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      place.trim().toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(left: 0, top: 0, bottom: 0, child: _roll()),
        Positioned(right: 0, top: 0, bottom: 0, child: _roll()),
      ],
    );
  }
}

/// Khung tranh: viền cam, dải vàng có họa tiết vân mây, nền giấy vàng nhạt.
class _FramePainter extends CustomPainter {
  const _FramePainter(this.band);

  final double band;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = _orange);
    final outer = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    final inner = Rect.fromLTWH(band, band, size.width - 2 * band, size.height - 2 * band);

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(outer),
        Path()..addRect(inner),
      ),
      Paint()..color = const Color(0xFFFFD23F),
    );

    const pattern = CloudPatternPainter(color: Color(0xAAF58220), cell: 38);
    void band_(Rect r) {
      canvas.save();
      canvas.clipRect(r);
      canvas.translate(r.left, r.top);
      pattern.paint(canvas, r.size);
      canvas.restore();
    }

    band_(Rect.fromLTRB(outer.left, outer.top, outer.right, inner.top));
    band_(Rect.fromLTRB(outer.left, inner.bottom, outer.right, outer.bottom));
    band_(Rect.fromLTRB(outer.left, inner.top, inner.left, inner.bottom));
    band_(Rect.fromLTRB(inner.right, inner.top, outer.right, inner.bottom));

    canvas.drawRect(
      inner,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF59D), Color(0xFFFFFDE7), Color(0xFFFFF59D)],
        ).createShader(inner),
    );
    final line = Paint()
      ..color = _orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(inner, line);
    canvas.drawRect(outer, line);
  }

  @override
  bool shouldRepaint(_FramePainter old) => old.band != band;
}

class _EdgePainter extends CustomPainter {
  const _EdgePainter(this.childEdges, this.spouseLinks);

  final List<TreeEdge> childEdges;
  final List<TreeEdge> spouseLinks;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    for (final e in childEdges) {
      final midY = (e.fromY + e.toY) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(e.fromX, e.fromY)
          ..lineTo(e.fromX, midY)
          ..lineTo(e.toX, midY)
          ..lineTo(e.toX, e.toY),
        line,
      );
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

/// Thẻ chữ nhật tô màu theo đời: tên in hoa đậm, ghi chú quan hệ nhỏ bên dưới.
class _PhaCard extends StatelessWidget {
  const _PhaCard({
    required this.person,
    required this.fill,
    required this.note,
    required this.onTap,
  });

  final Person person;
  final Color fill;
  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photo = personPhotoFile(person);
    return Material(
      color: fill,
      elevation: 1.5,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(3)),
        side: BorderSide(color: Colors.white, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              if (photo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: ClipOval(
                    child: Image.file(
                      File(photo.path),
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                      cacheWidth: 90,
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tên dài quá ô thì tự thu nhỏ chữ để vẫn nằm trên một hàng.
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        person.fullName.toUpperCase(),
                        maxLines: 1,
                        softWrap: false,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          height: 1.15,
                          color: _navy,
                        ),
                      ),
                    ),
                    if (note != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 9.5,
                            height: 1.1,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

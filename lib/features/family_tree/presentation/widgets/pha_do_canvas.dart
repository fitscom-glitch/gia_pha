import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gia_pha/core/theme/app_colors.dart';
import 'package:gia_pha/core/widgets/art_assets.dart';
import 'package:gia_pha/core/widgets/ornaments/ornaments.dart';
import 'package:gia_pha/features/family_tree/domain/entities/pha_do_layer.dart';
import 'package:gia_pha/features/family_tree/domain/services/generation_rows.dart';
import 'package:gia_pha/features/family_tree/domain/services/tree_layout.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/generation_colors.dart';
import 'package:gia_pha/features/family_tree/presentation/widgets/layer_image.dart';
import 'package:gia_pha/features/members/domain/entities/family_data.dart';
import 'package:gia_pha/features/members/domain/entities/person.dart';
import 'package:gia_pha/features/members/presentation/widgets/person_avatar.dart';
import 'package:gia_pha/features/members/presentation/widgets/relation_note.dart';

const _orange = Color(0xFFF58220);
const _navy = Color(0xFF1A237E);

/// Phả đồ dạng tranh treo: khung vàng cam, hai rồng chầu, băng rôn tên dòng họ,
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
    this.layers = const [],
    this.showFrame = true,
    this.showBanner = true,
    this.showWatermark = true,
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

  /// Hình nền / họa tiết do người dùng thêm (đã sắp theo thứ tự lớp).
  final List<PhaDoLayer> layers;
  final bool showFrame;
  final bool showBanner;
  final bool showWatermark;

  static const double _band = 58;
  static const double _header = 290;
  static const double _labelW = 130;
  static const double _sideW = 24;
  static const double _footer = 80;
  static const double _minTreeH = 440;
  static const double _minWidth = 1400;
  static const double _bannerW = 680;
  static const double _dragonW = 360;
  static const double _dragonOverlap = 70;

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
          if (showFrame)
            Positioned.fill(child: CustomPaint(painter: _FramePainter(_band)))
          else
            const Positioned.fill(child: ColoredBox(color: Color(0xFFFFFDE7))),
          // hình nền do người dùng thêm
          for (final l in layers.where((l) => l.kind == PhaDoLayerKind.background))
            Positioned.fill(
              child: Opacity(
                opacity: l.opacity,
                child: LayerImage(path: l.path, fit: BoxFit.cover),
              ),
            ),
          // hình rồng mờ làm nền
          if (showWatermark)
            Positioned(
              left: contentLeft + innerW * 0.08,
              top: treeY,
              width: innerW * 0.84,
              height: layout.height < _minTreeH ? _minTreeH : layout.height,
              child: const DragonImage(opacity: 0.09),
            ),
          for (final l in layers.where((l) => l.kind == PhaDoLayerKind.decor && !l.front))
            _decor(l, size),
          if (showBanner) ..._buildHeader(size, title),
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
          for (final l in layers.where((l) => l.kind == PhaDoLayerKind.decor && l.front))
            _decor(l, size),
        ],
      ),
    );
  }

  /// Băng rôn ở giữa, hai rồng chầu hai bên (đầu quay vào băng rôn).
  List<Widget> _buildHeader(Size size, String title) {
    const bannerH = _bannerW / ArtAssets.bannerAspect;
    const dragonH = _dragonW / ArtAssets.dragonAspect;
    const top = _band + 14;
    final cx = size.width / 2;
    final dragonTop = top + (bannerH - dragonH) / 2 + 12;
    return [
      Positioned(
        left: cx - _bannerW / 2 - _dragonW + _dragonOverlap,
        top: dragonTop,
        width: _dragonW,
        height: dragonH,
        child: const DragonImage(faceRight: true),
      ),
      Positioned(
        left: cx + _bannerW / 2 - _dragonOverlap,
        top: dragonTop,
        width: _dragonW,
        height: dragonH,
        child: const DragonImage(faceRight: false),
      ),
      Positioned(
        left: cx - _bannerW / 2,
        top: top,
        width: _bannerW,
        height: bannerH,
        child: _ImageBanner(title: title, place: place),
      ),
    ];
  }

  /// Khung chữ nhật (chưa xoay) của một lớp họa tiết trên khung phả đồ [canvas].
  static Rect layerRect(PhaDoLayer l, Size canvas) {
    final w = l.w * canvas.width;
    return Rect.fromCenter(
      center: Offset(l.cx * canvas.width, l.cy * canvas.height),
      width: w,
      height: w * l.aspect,
    );
  }

  Widget _decor(PhaDoLayer l, Size canvas) {
    final r = layerRect(l, canvas);
    return Positioned(
      left: r.left,
      top: r.top,
      width: r.width,
      height: r.height,
      child: Opacity(
        opacity: l.opacity,
        child: Transform.rotate(
          angle: l.rotation * math.pi / 180,
          child: LayerImage(path: l.path),
        ),
      ),
    );
  }
}

/// Băng rôn bằng hình: chữ "PHẢ ĐỒ" + tên dòng họ + địa danh nằm trên nền đỏ ở giữa.
class _ImageBanner extends StatelessWidget {
  const _ImageBanner({required this.title, required this.place});

  final String title;
  final String place;

  static const _shadow = [
    Shadow(color: Color(0xAA000000), blurRadius: 3, offset: Offset(0, 1.5)),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        return Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                ArtAssets.banner,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
              ),
            ),
            // Vùng nền đỏ của băng rôn nằm ở giữa, cao khoảng 21%–59% ảnh.
            Positioned(
              left: w * 0.22,
              right: w * 0.22,
              top: h * 0.215,
              height: h * 0.385,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PHẢ ĐỒ',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: 8,
                        color: AppColors.goldLight,
                        shadows: _shadow,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 1,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w900,
                        fontSize: 46,
                        height: 1.1,
                        color: AppColors.gold,
                        shadows: _shadow,
                      ),
                    ),
                    if (place.trim().isNotEmpty)
                      Text(
                        place.trim().toUpperCase(),
                        maxLines: 1,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.goldLight,
                          shadows: _shadow,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
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
